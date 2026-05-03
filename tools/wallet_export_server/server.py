#!/usr/bin/env python3
import base64
import hashlib
import json
import os
import re
import shutil
import subprocess
import tempfile
import time
import uuid
import zipfile
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import urlparse
from urllib.parse import urlencode
from urllib.request import Request
from urllib.request import urlopen


HOST = os.getenv("WALLET_EXPORT_HOST", "127.0.0.1")
PORT = int(os.getenv("PORT", os.getenv("WALLET_EXPORT_PORT", "8080")))
PUBLIC_BASE_URL = os.getenv("WALLET_PUBLIC_BASE_URL", f"http://{HOST}:{PORT}")
API_KEY = os.getenv("WALLET_EXPORT_API_KEY", "").strip()
PASS_OUTPUT_DIR = Path(
    os.getenv("WALLET_PASS_OUTPUT_DIR", tempfile.gettempdir())
) / "cardwallet-passes"

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


def main():
    PASS_OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
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
            print(f"Wallet export error: {error}")
            self._json_response(500, {"messageKey": "walletExportFailed"})

    def _authorize(self):
        if not API_KEY:
            return
        received = self.headers.get("X-CardWallet-Api-Key", "").strip()
        if received != API_KEY:
            raise RequestError(401, "walletExportFailed")

    def _read_json(self):
        content_length = int(self.headers.get("Content-Length", "0"))
        raw = self.rfile.read(content_length)
        try:
            data = json.loads(raw.decode("utf-8"))
        except json.JSONDecodeError:
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
