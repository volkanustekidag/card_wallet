# Calls the App Store Connect API with the key in ~/.deckard_keys/asc.json (never in this repo).
# ruby tools/aso/asc.rb GET /v1/apps/6755343533/analyticsReportRequests
# Report requests made 2026-11-02: ONGOING 441c6d92-b185-478a-8d73-3f5c68e68656,
# ONE_TIME_SNAPSHOT 54172823-00ce-423d-a660-1719a3998b64 (Apple fills them in 1-2 days).
require "jwt"
require "json"
require "openssl"
require "net/http"
k = JSON.parse(File.read(File.expand_path("~/.deckard_keys/asc.json")))
key = OpenSSL::PKey::EC.new(k["key"])
now = Time.now.to_i
TOKEN = JWT.encode({ iss: k["issuer_id"], iat: now, exp: now + 1100, aud: "appstoreconnect-v1" }, key, "ES256", { kid: k["key_id"], typ: "JWT" })
def call(method, path, body = nil)
  uri = URI(path.start_with?("http") ? path : "https://api.appstoreconnect.apple.com#{path}")
  req = (method == "POST" ? Net::HTTP::Post : Net::HTTP::Get).new(uri)
  req["Authorization"] = "Bearer #{TOKEN}"
  if body then req["Content-Type"] = "application/json"; req.body = body.to_json end
  res = Net::HTTP.start(uri.host, uri.port, use_ssl: true) { |h| h.request(req) }
  [res.code, res.body]
end
if __FILE__ == $0
  code, body = call(ARGV[0], ARGV[1], ARGV[2] && JSON.parse(ARGV[2]))
  puts code
  puts body[0, (ENV["MAX"] || 3000).to_i]
end
