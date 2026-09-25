class_name TokenLogic
extends RefCounted
## Access-token bookkeeping: read a JWT's expiry (without trusting it for
## anything but scheduling), decide when to refresh, and derive the key the
## token file is encrypted with. Pure; unit-tested in tests/test_tokens.gd.

## Refresh this many seconds before the access token expires.
const SKEW := 30


## Base64url (no padding) -> bytes.
static func b64url_decode(s: String) -> PackedByteArray:
	var t := s.replace("-", "+").replace("_", "/")
	while t.length() % 4 != 0:
		t += "="
	return Marshalls.base64_to_raw(t)


## The JWT payload as a Dictionary ({} when it is not a JWT).
static func jwt_claims(token: String) -> Dictionary:
	var parts := token.split(".")
	if parts.size() != 3:
		return {}
	var raw := b64url_decode(parts[1])
	var v = JSON.parse_string(raw.get_string_from_utf8())
	return v if v is Dictionary else {}


## Unix seconds the token expires at; 0 when unknown.
static func jwt_exp(token: String) -> int:
	return int(jwt_claims(token).get("exp", 0))


## Whether to refresh before using the access token at `now` (unix seconds).
## `exp` 0 (unknown) means: trust it until the server says 401.
static func needs_refresh(exp: int, now: int, skew := SKEW) -> bool:
	if exp <= 0:
		return false
	return now >= exp - skew


## The key the token file is encrypted with (AES-256 via FileAccess.open_encrypted_with_pass).
## Tied to this device so a copied file is useless elsewhere. This is obfuscation
## against casual reading, not protection from someone who owns the device.
static func storage_key(device_id: String) -> String:
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	ctx.update(("torncity-client/v1/" + device_id).to_utf8_buffer())
	return ctx.finish().hex_encode()
