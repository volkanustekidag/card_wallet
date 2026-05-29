#!/usr/bin/env python3
import base64
import hashlib
import hmac
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
import threading
import time
import uuid
import zipfile
from collections import deque
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import urlparse
from urllib.parse import urlencode
from urllib.request import Request
from urllib.request import urlopen

try:
    import firebase_admin
    from firebase_admin import app_check
    _APP_CHECK_AVAILABLE = True
except ImportError:
    # Dev environments without firebase_admin installed still get to run
    # the server. They just can't accept App Check tokens — the legacy
    # API key path stays open unless APP_CHECK_REQUIRED is true.
    firebase_admin = None  # type: ignore
    app_check = None  # type: ignore
    _APP_CHECK_AVAILABLE = False


HOST = os.getenv("WALLET_EXPORT_HOST", "127.0.0.1")
PORT = int(os.getenv("PORT", os.getenv("WALLET_EXPORT_PORT", "8080")))
PUBLIC_BASE_URL = os.getenv("WALLET_PUBLIC_BASE_URL", f"http://{HOST}:{PORT}")
API_KEY = os.getenv("WALLET_EXPORT_API_KEY", "").strip()
PASS_OUTPUT_DIR = Path(
    os.getenv("WALLET_PASS_OUTPUT_DIR", tempfile.gettempdir())
) / "cardwallet-passes"

# Firebase App Check enforcement.
#
#   APP_CHECK_REQUIRED=true   — only requests carrying a valid
#                                X-Firebase-AppCheck token are accepted.
#                                Production default.
#   APP_CHECK_REQUIRED=false  — accept either a valid App Check token
#                                OR the legacy API key. Use only for local
#                                legacy smoke tests or a temporary rollback.
#   FIREBASE_PROJECT_ID       — App Check verification requires the
#                                project ID to be configured for the
#                                Firebase Admin SDK; on Cloud Run this
#                                is auto-detected from the metadata
#                                server, locally set it explicitly.
APP_CHECK_REQUIRED = os.getenv("APP_CHECK_REQUIRED", "true").lower() == "true"
FIREBASE_PROJECT_ID = os.getenv("FIREBASE_PROJECT_ID", "").strip()

# Reject payloads larger than this before reading the body — protects against
# memory exhaustion via spoofed Content-Length. Real payloads are ~1KB.
MAX_REQUEST_BYTES = 10 * 1024

# Per-IP rate limit: 30 POSTs per 60s rolling window. Cloud Run runs with
# max-instances=1 so a single client can knock the service over without this.
RATE_LIMIT_MAX_REQUESTS = int(os.getenv("WALLET_RATE_LIMIT_MAX", "30"))
RATE_LIMIT_WINDOW_SEC = int(os.getenv("WALLET_RATE_LIMIT_WINDOW", "60"))

# Built passes live in /tmp and are served back via GET. Without this they
# accumulate until the filesystem fills up.
PASS_TTL_SEC = int(os.getenv("WALLET_PASS_TTL_SEC", str(24 * 60 * 60)))
PASS_CLEANUP_INTERVAL_SEC = int(
    os.getenv("WALLET_PASS_CLEANUP_INTERVAL_SEC", "600")
)

APPLE_SUPPORTED_FORMATS = {
    "QR_CODE": "PKBarcodeFormatQR",
    "CODE_128": "PKBarcodeFormatCode128",
}
GOOGLE_SUPPORTED_FORMATS = {
    "QR_CODE": "QR_CODE",
    "CODE_128": "CODE_128",
    "CODE_39": "CODE_39",
    "EAN_13": "EAN_13",
    "EAN_8": "EAN_8",
    "UPC_A": "UPC_A",
}
GOOGLE_WALLET_SCOPE = "https://www.googleapis.com/auth/wallet_object.issuer"
GOOGLE_WALLET_API = "https://walletobjects.googleapis.com/walletobjects/v1"


class ConfigError(Exception):
    pass


class RequestError(Exception):
    def __init__(self, status, message_key):
        super().__init__(message_key)
        self.status = status
        self.message_key = message_key


_rate_limit_lock = threading.Lock()
_rate_limit_buckets: dict = {}


def _init_firebase_admin():
    """Bootstrap the Firebase Admin SDK once at startup so App Check
    token verification doesn't pay the init cost on every request.

    On Cloud Run / GCE / Cloud Functions the SDK auto-picks the
    instance service account credentials. Locally, set
    GOOGLE_APPLICATION_CREDENTIALS to a service account JSON with the
    "Firebase App Check Verifier" role (or roles/firebaseappcheck.admin
    for broader scope)."""
    if not _APP_CHECK_AVAILABLE:
        if APP_CHECK_REQUIRED:
            print(
                "FATAL: APP_CHECK_REQUIRED=true but firebase_admin is not "
                "installed. Run: pip install firebase-admin",
                file=sys.stderr,
            )
            sys.exit(2)
        return
    try:
        options = {}
        if FIREBASE_PROJECT_ID:
            options["projectId"] = FIREBASE_PROJECT_ID
        firebase_admin.initialize_app(options=options or None)
    except ValueError:
        # Already initialised — rerunning the import in a unit test
        # or warm restart hits this. Safe to ignore.
        pass
    except Exception as error:
        # Don't crash if creds aren't available locally and we're in
        # legacy-key mode; only hard-fail when App Check is required.
        if APP_CHECK_REQUIRED:
            print(
                f"FATAL: firebase_admin init failed: {type(error).__name__}",
                file=sys.stderr,
            )
            sys.exit(2)


def _verify_app_check_token(token: str) -> bool:
    """Returns True if `token` is a valid Firebase App Check token for
    this project. False on any failure mode (expired, wrong audience,
    SDK not initialised, transient JWKS fetch error). The caller falls
    back to the API key path when this returns False (unless
    APP_CHECK_REQUIRED is true)."""
    if not _APP_CHECK_AVAILABLE or not token:
        return False
    try:
        app_check.verify_token(token)
        return True
    except Exception as error:
        # Token-level errors are expected (debug builds, replay
        # attempts, clock skew) so don't log the token itself.
        print(
            f"App Check verify rejected: {type(error).__name__}",
            file=sys.stderr,
        )
        return False


def _rate_limit_allow(client_ip: str) -> bool:
    """Sliding-window rate limit by client IP. Allows up to
    RATE_LIMIT_MAX_REQUESTS requests in RATE_LIMIT_WINDOW_SEC seconds."""
    now = time.monotonic()
    cutoff = now - RATE_LIMIT_WINDOW_SEC
    with _rate_limit_lock:
        bucket = _rate_limit_buckets.get(client_ip)
        if bucket is None:
            bucket = deque()
            _rate_limit_buckets[client_ip] = bucket
        while bucket and bucket[0] < cutoff:
            bucket.popleft()
        if len(bucket) >= RATE_LIMIT_MAX_REQUESTS:
            return False
        bucket.append(now)
        # Opportunistic GC so the dict doesn't grow forever from one-off IPs.
        if len(_rate_limit_buckets) > 1024:
            for ip in list(_rate_limit_buckets.keys()):
                if not _rate_limit_buckets[ip]:
                    _rate_limit_buckets.pop(ip, None)
        return True


def _pass_cleanup_loop():
    """Background daemon that drops expired pkpass files. Each generated pass
    is fetched once by the user device, so a 24h TTL is generous."""
    while True:
        try:
            cutoff = time.time() - PASS_TTL_SEC
            for path in PASS_OUTPUT_DIR.glob("*.pkpass"):
                try:
                    if path.stat().st_mtime < cutoff:
                        path.unlink(missing_ok=True)
                except OSError:
                    pass
        except Exception:
            # Never let the cleanup thread die — log type only, no payloads.
            print("Wallet export cleanup error", file=sys.stderr)
        time.sleep(PASS_CLEANUP_INTERVAL_SEC)


def main():
    # Production is fail-closed: App Check is required unless explicitly
    # disabled for local legacy testing. Never run a public Cloud Run service
    # with APP_CHECK_REQUIRED=false unless you also understand the API-key
    # fallback exposure.
    if not API_KEY and not APP_CHECK_REQUIRED:
        print(
            "FATAL: set WALLET_EXPORT_API_KEY or APP_CHECK_REQUIRED=true.",
            file=sys.stderr,
        )
        sys.exit(2)
    _init_firebase_admin()
    PASS_OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    cleanup_thread = threading.Thread(
        target=_pass_cleanup_loop, daemon=True, name="pkpass-cleanup"
    )
    cleanup_thread.start()
    server = ThreadingHTTPServer((HOST, PORT), WalletExportHandler)
    print(f"Wallet export server listening on http://{HOST}:{PORT}")
    server.serve_forever()


class WalletExportHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        parsed = urlparse(self.path)
        if parsed.path.startswith("/passes/") and parsed.path.endswith(".pkpass"):
            return self._serve_pkpass(parsed.path.split("/")[-1])
        if parsed.path == "/assets/google-logo.png":
            return self._serve_google_logo()
        self._json_response(404, {"messageKey": "walletExportFailed"})

    def do_POST(self):
        try:
            if not _rate_limit_allow(self._client_ip()):
                return self._json_response(
                    429, {"messageKey": "walletExportRateLimited"}
                )
            self._authorize()
            parsed = urlparse(self.path)
            payload = self._read_json()

            if parsed.path == "/v1/wallet/loyalty/apple":
                pass_path = create_apple_pass(payload)
                launch_url = (
                    f"{PUBLIC_BASE_URL.rstrip()}/passes/{pass_path.name}"
                )
                return self._json_response(200, {"launchUrl": launch_url})

            if parsed.path == "/v1/wallet/loyalty/google":
                launch_url = create_google_save_url(payload)
                return self._json_response(200, {"launchUrl": launch_url})

            self._json_response(404, {"messageKey": "walletExportFailed"})
        except RequestError as error:
            self._json_response(error.status, {"messageKey": error.message_key})
        except ConfigError:
            self._json_response(500, {"messageKey": "walletExportNotConfigured"})
        except Exception as error:
            # Log only the exception type; payloads carry loyalty barcodes
            # and must never end up in stdout/stderr.
            print(
                f"Wallet export error: {type(error).__name__}",
                file=sys.stderr,
            )
            self._json_response(500, {"messageKey": "walletExportFailed"})

    def _client_ip(self) -> str:
        # Cloud Run / proxies set X-Forwarded-For; the first hop is the real
        # client. Fall back to the socket address in dev.
        forwarded = self.headers.get("X-Forwarded-For", "")
        if forwarded:
            return forwarded.split(",")[0].strip()
        return self.client_address[0]

    def _authorize(self):
        app_check_token = self.headers.get("X-Firebase-AppCheck", "").strip()
        if app_check_token and _verify_app_check_token(app_check_token):
            # App Check verified the request really came from a real,
            # unmodified Card Wallet build on a real device. The legacy
            # API key check is skipped in this path.
            return

        if APP_CHECK_REQUIRED:
            # Hard cutover mode — no fallback. Anything without a
            # valid App Check token is rejected.
            raise RequestError(401, "walletExportFailed")

        received = self.headers.get("X-CardWallet-Api-Key", "").strip()
        # Constant-time compare so brute-force timing attacks on the key are
        # not free. compare_digest needs equal-length inputs to be useful,
        # but it also doesn't leak the length difference here.
        if not received or not hmac.compare_digest(received, API_KEY):
            raise RequestError(401, "walletExportFailed")

    def _read_json(self):
        try:
            content_length = int(self.headers.get("Content-Length", "0"))
        except ValueError:
            raise RequestError(400, "walletExportInvalidResponse")
        if content_length <= 0 or content_length > MAX_REQUEST_BYTES:
            raise RequestError(413, "walletExportInvalidResponse")
        raw = self.rfile.read(content_length)
        if len(raw) != content_length:
            raise RequestError(400, "walletExportInvalidResponse")
        try:
            data = json.loads(raw.decode("utf-8"))
        except (json.JSONDecodeError, UnicodeDecodeError):
            raise RequestError(400, "walletExportInvalidResponse")
        if not isinstance(data, dict):
            raise RequestError(400, "walletExportInvalidResponse")
        validate_payload(data)
        return data

    def _serve_pkpass(self, filename):
        safe_name = Path(filename).name
        path = PASS_OUTPUT_DIR / safe_name
        if not path.exists() or path.suffix != ".pkpass":
            return self._json_response(404, {"messageKey": "walletExportFailed"})

        body = path.read_bytes()
        self.send_response(200)
        self.send_header("Content-Type", "application/vnd.apple.pkpass")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Content-Disposition", f'attachment; filename="{safe_name}"')
        self.end_headers()
        self.wfile.write(body)

    def _serve_google_logo(self):
        logo_path = google_logo_path()
        if logo_path is None:
            return self._json_response(404, {"messageKey": "walletExportNotConfigured"})

        body = logo_path.read_bytes()
        self.send_response(200)
        self.send_header("Content-Type", "image/png")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def _json_response(self, status, data):
        body = json.dumps(data).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)


def validate_payload(data):
    for key in ("id", "name", "brand", "barcode", "barcodeFormat"):
        if not str(data.get(key, "")).strip():
            raise RequestError(400, "walletExportInvalidResponse")


def create_apple_pass(card):
    barcode_format = str(card["barcodeFormat"]).upper()
    pass_format = APPLE_SUPPORTED_FORMATS.get(barcode_format)
    if pass_format is None:
        raise RequestError(422, "walletExportUnsupportedAppleBarcode")

    required = {
        "APPLE_PASS_TYPE_ID": os.getenv("APPLE_PASS_TYPE_ID"),
        "APPLE_TEAM_ID": os.getenv("APPLE_TEAM_ID"),
        "APPLE_ORG_NAME": os.getenv("APPLE_ORG_NAME"),
        "APPLE_SIGNER_CERT_PATH": os.getenv("APPLE_SIGNER_CERT_PATH"),
        "APPLE_SIGNER_KEY_PATH": os.getenv("APPLE_SIGNER_KEY_PATH"),
        "APPLE_WWDR_CERT_PATH": os.getenv("APPLE_WWDR_CERT_PATH"),
        "APPLE_ICON_PATH": os.getenv("APPLE_ICON_PATH"),
    }
    if any(not value for value in required.values()):
        raise ConfigError()

    serial = sanitize_identifier(str(card["id"]))
    filename = f"{serial}-{uuid.uuid4().hex}.pkpass"
    with tempfile.TemporaryDirectory() as tmp:
        pass_dir = Path(tmp)
        pass_json = apple_pass_json(card, pass_format, required)
        (pass_dir / "pass.json").write_text(
            json.dumps(pass_json, ensure_ascii=False, separators=(",", ":")),
            encoding="utf-8",
        )
        copy_pass_images(pass_dir, Path(required["APPLE_ICON_PATH"]))

        logo_path = os.getenv("APPLE_LOGO_PATH")
        if logo_path:
            shutil.copyfile(logo_path, pass_dir / "logo.png")

        manifest = create_manifest(pass_dir)
        (pass_dir / "manifest.json").write_text(
            json.dumps(manifest, separators=(",", ":")),
            encoding="utf-8",
        )
        sign_manifest(
            manifest_path=pass_dir / "manifest.json",
            signature_path=pass_dir / "signature",
            signer_cert=Path(required["APPLE_SIGNER_CERT_PATH"]),
            signer_key=Path(required["APPLE_SIGNER_KEY_PATH"]),
            wwdr_cert=Path(required["APPLE_WWDR_CERT_PATH"]),
            passphrase=os.getenv("APPLE_SIGNER_KEY_PASSPHRASE", ""),
        )

        output = PASS_OUTPUT_DIR / filename
        with zipfile.ZipFile(output, "w", zipfile.ZIP_DEFLATED) as archive:
            for path in pass_dir.iterdir():
                archive.write(path, path.name)
        return output


def apple_pass_json(card, pass_format, config):
    name = clean_text(card["name"])
    brand = clean_text(card["brand"])
    barcode = clean_text(card["barcode"])
    notes = clean_text(card.get("notes", ""))
    fields = {
        "primaryFields": [
            {"key": "program", "label": "Program", "value": name},
        ],
        "secondaryFields": [
            {"key": "brand", "label": "Brand", "value": brand},
        ],
        "auxiliaryFields": [
            {"key": "member", "label": "Member", "value": barcode},
        ],
        "backFields": [
            {"key": "barcode", "label": "Barcode", "value": barcode},
        ],
    }
    if notes:
        fields["backFields"].append(
            {"key": "notes", "label": "Notes", "value": notes}
        )

    barcode_payload = {
        "format": pass_format,
        "message": barcode,
        "messageEncoding": "iso-8859-1",
        "altText": barcode,
    }
    background = sanitize_rgb(card.get("backgroundColor")) or os.getenv(
        "APPLE_PASS_BACKGROUND", "rgb(28,31,38)"
    )
    foreground = sanitize_rgb(card.get("foregroundColor")) or "rgb(255,255,255)"
    label = sanitize_rgb(card.get("labelColor")) or "rgb(235,235,235)"
    return {
        "formatVersion": 1,
        "passTypeIdentifier": config["APPLE_PASS_TYPE_ID"],
        "serialNumber": sanitize_identifier(str(card["id"])),
        "teamIdentifier": config["APPLE_TEAM_ID"],
        "organizationName": config["APPLE_ORG_NAME"],
        "description": f"{brand} loyalty card",
        "logoText": brand,
        "foregroundColor": foreground,
        "backgroundColor": background,
        "labelColor": label,
        "barcodes": [barcode_payload],
        "barcode": barcode_payload,
        "storeCard": fields,
    }


def copy_pass_images(pass_dir, icon_path):
    icon_dir = icon_path.parent
    icon_sources = {
        "icon.png": icon_path,
        "icon@2x.png": icon_dir / "icon@2x.png",
        "icon@3x.png": icon_dir / "icon@3x.png",
    }
    for name, source in icon_sources.items():
        shutil.copyfile(source if source.exists() else icon_path, pass_dir / name)


def create_manifest(pass_dir):
    manifest = {}
    for path in pass_dir.iterdir():
        if path.name in ("manifest.json", "signature"):
            continue
        manifest[path.name] = hashlib.sha1(path.read_bytes()).hexdigest()
    return manifest


def sign_manifest(
    manifest_path,
    signature_path,
    signer_cert,
    signer_key,
    wwdr_cert,
    passphrase,
):
    command = [
        "openssl",
        "smime",
        "-binary",
        "-sign",
        "-certfile",
        str(wwdr_cert),
        "-signer",
        str(signer_cert),
        "-inkey",
        str(signer_key),
        "-in",
        str(manifest_path),
        "-out",
        str(signature_path),
        "-outform",
        "DER",
    ]
    if passphrase:
        command.extend(["-passin", f"pass:{passphrase}"])
    subprocess.run(command, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)


def create_google_save_url(card):
    barcode_format = google_barcode_format(card)
    if barcode_format is None:
        raise RequestError(422, "walletExportUnsupportedGoogleBarcode")

    service_account_path = os.getenv("GOOGLE_SERVICE_ACCOUNT_PATH")
    issuer_id = os.getenv("GOOGLE_WALLET_ISSUER_ID")
    class_suffix = os.getenv("GOOGLE_WALLET_CLASS_SUFFIX")
    if not service_account_path or not issuer_id or not class_suffix:
        raise ConfigError()

    service_account = json.loads(Path(service_account_path).read_text())
    private_key = service_account.get("private_key")
    client_email = service_account.get("client_email")
    if not private_key or not client_email:
        raise ConfigError()

    class_id = f"{issuer_id}.{sanitize_identifier(class_suffix)}"
    object_id = f"{issuer_id}.{sanitize_identifier(str(card['id']))}"
    logo_url = google_logo_url()
    if not logo_url:
        raise ConfigError()

    if os.getenv("GOOGLE_WALLET_AUTO_CREATE_CLASS", "false").lower() == "true":
        ensure_google_loyalty_class(
            service_account=service_account,
            class_id=class_id,
            logo_url=logo_url,
        )

    origins = [
        value.strip()
        for value in os.getenv("GOOGLE_WALLET_ORIGINS", "").split(",")
        if value.strip()
    ]
    jwt_payload = {
        "iss": client_email,
        "aud": "google",
        "typ": "savetowallet",
        "iat": int(time.time()),
        "origins": origins,
        "payload": {
            "loyaltyObjects": [
                google_loyalty_object(
                    card=card,
                    object_id=object_id,
                    class_id=class_id,
                    barcode_format=barcode_format,
                )
            ]
        },
    }
    token = sign_google_jwt(jwt_payload, private_key)
    return f"https://pay.google.com/gp/v/save/{token}"


def google_loyalty_class(class_id, logo_url):
    issuer_name = os.getenv("GOOGLE_WALLET_ISSUER_NAME", "Card Wallet")
    program_name = os.getenv("GOOGLE_WALLET_PROGRAM_NAME", "Card Wallet Loyalty")
    homepage_url = os.getenv("GOOGLE_WALLET_HOMEPAGE_URL", "").strip()
    loyalty_class = {
        "id": class_id,
        "issuerName": issuer_name,
        "programName": program_name,
        "programLogo": google_image(logo_url, f"{program_name} logo"),
        "accountNameLabel": "Card",
        "accountIdLabel": "Member ID",
        "reviewStatus": "UNDER_REVIEW",
        "hexBackgroundColor": os.getenv("GOOGLE_WALLET_BACKGROUND", "#1C1F26"),
        "countryCode": os.getenv("GOOGLE_WALLET_COUNTRY_CODE", "TR"),
    }
    if homepage_url:
        loyalty_class["homepageUri"] = {
            "uri": homepage_url,
            "description": issuer_name,
        }
    return loyalty_class


def google_loyalty_object(card, object_id, class_id, barcode_format):
    obj = {
        "id": object_id,
        "classId": class_id,
        "state": "ACTIVE",
        "accountId": clean_text(card["barcode"]),
        "accountName": clean_text(card["name"]),
        "barcode": {
            "type": barcode_format,
            "value": clean_text(card["barcode"]),
            "alternateText": clean_text(card["barcode"]),
        },
        "textModulesData": google_text_modules(card),
    }
    hex_bg = rgb_to_hex(sanitize_rgb(card.get("backgroundColor")))
    if hex_bg:
        obj["hexBackgroundColor"] = hex_bg
    return obj


def google_image(uri, description):
    return {
        "sourceUri": {"uri": uri},
        "contentDescription": {
            "defaultValue": {
                "language": "en-US",
                "value": description,
            }
        },
    }


def google_barcode_format(card):
    barcode_format = str(card["barcodeFormat"]).upper()
    if barcode_format in GOOGLE_SUPPORTED_FORMATS:
        return GOOGLE_SUPPORTED_FORMATS[barcode_format]
    if barcode_format == "ITF" and re.fullmatch(r"\d{14}", clean_text(card["barcode"])):
        return "ITF_14"
    return None


def google_text_modules(card):
    modules = [
        {
            "id": "brand",
            "header": "Brand",
            "body": clean_text(card["brand"]),
        }
    ]
    notes = clean_text(card.get("notes", ""))
    if notes:
        modules.append({"id": "notes", "header": "Notes", "body": notes})
    return modules


def ensure_google_loyalty_class(service_account, class_id, logo_url):
    token = google_access_token(service_account)
    get_request = Request(
        f"{GOOGLE_WALLET_API}/loyaltyClass/{class_id}",
        headers={"Authorization": f"Bearer {token}"},
    )
    try:
        with urlopen(get_request, timeout=20) as response:
            if 200 <= response.status < 300:
                return
    except Exception as error:
        status = getattr(getattr(error, "fp", None), "status", None)
        if status != 404:
            raise

    body = json.dumps(google_loyalty_class(class_id, logo_url)).encode("utf-8")
    insert_request = Request(
        f"{GOOGLE_WALLET_API}/loyaltyClass",
        data=body,
        headers={
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json",
        },
        method="POST",
    )
    try:
        with urlopen(insert_request, timeout=20):
            return
    except Exception as error:
        status = getattr(getattr(error, "fp", None), "status", None)
        if status == 409:
            return
        raise


def google_access_token(service_account):
    now = int(time.time())
    assertion = {
        "iss": service_account["client_email"],
        "scope": GOOGLE_WALLET_SCOPE,
        "aud": "https://oauth2.googleapis.com/token",
        "iat": now,
        "exp": now + 3600,
    }
    signed_assertion = sign_google_jwt(assertion, service_account["private_key"])
    data = urlencode(
        {
            "grant_type": "urn:ietf:params:oauth:grant-type:jwt-bearer",
            "assertion": signed_assertion,
        }
    ).encode("utf-8")
    request = Request(
        "https://oauth2.googleapis.com/token",
        data=data,
        headers={"Content-Type": "application/x-www-form-urlencoded"},
        method="POST",
    )
    with urlopen(request, timeout=20) as response:
        decoded = json.loads(response.read().decode("utf-8"))
    token = decoded.get("access_token")
    if not token:
        raise ConfigError()
    return token


def google_logo_url():
    configured = os.getenv("GOOGLE_WALLET_LOGO_URL", "").strip()
    if configured:
        return configured
    if google_logo_path() is not None:
        return f"{PUBLIC_BASE_URL.rstrip()}/assets/google-logo.png"
    return ""


def google_logo_path():
    for value in (
        os.getenv("GOOGLE_LOGO_PATH"),
        os.getenv("APPLE_LOGO_PATH"),
        os.getenv("APPLE_ICON_PATH"),
    ):
        if value and Path(value).exists():
            return Path(value)
    return None


def sign_google_jwt(payload, private_key):
    header = {"alg": "RS256", "typ": "JWT"}
    signing_input = ".".join(
        [
            base64url(json.dumps(header, separators=(",", ":")).encode("utf-8")),
            base64url(json.dumps(payload, separators=(",", ":")).encode("utf-8")),
        ]
    )
    with tempfile.NamedTemporaryFile("w", delete=False) as key_file:
        key_file.write(private_key)
        key_path = key_file.name
    try:
        signature = subprocess.check_output(
            ["openssl", "dgst", "-sha256", "-sign", key_path],
            input=signing_input.encode("ascii"),
        )
    finally:
        Path(key_path).unlink(missing_ok=True)
    return f"{signing_input}.{base64url(signature)}"


def base64url(value):
    return base64.urlsafe_b64encode(value).rstrip(b"=").decode("ascii")


def sanitize_identifier(value):
    cleaned = re.sub(r"[^A-Za-z0-9._-]", "_", value.strip())
    return cleaned[:64] or uuid.uuid4().hex


_RGB_RE = re.compile(r"^rgb\(\s*(\d{1,3})\s*,\s*(\d{1,3})\s*,\s*(\d{1,3})\s*\)$")


def sanitize_rgb(value):
    """Accept only `rgb(r,g,b)` strings with channels in 0-255. Reject anything
    else so a malformed client value can't slip through into pass.json."""
    if not value or not isinstance(value, str):
        return None
    match = _RGB_RE.match(value.strip())
    if not match:
        return None
    channels = [int(match.group(i)) for i in (1, 2, 3)]
    if any(c < 0 or c > 255 for c in channels):
        return None
    return f"rgb({channels[0]},{channels[1]},{channels[2]})"


def rgb_to_hex(rgb):
    """`rgb(r,g,b)` (already sanitized) → `#RRGGBB`. Returns None on bad input."""
    if not rgb:
        return None
    match = _RGB_RE.match(rgb)
    if not match:
        return None
    return "#{:02X}{:02X}{:02X}".format(
        int(match.group(1)), int(match.group(2)), int(match.group(3))
    )


def clean_text(value):
    return str(value or "").strip()


if __name__ == "__main__":
    main()
