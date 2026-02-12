module ShopifySessionTokenVerifiable
  extend ActiveSupport::Concern

  private

  # Verifies a Shopify session token (JWT) signed with SHOPIFY_CLIENT_SECRET.
  # Returns decoded claims hash on success, nil on failure.
  def verify_session_token(token)
    client_secret = ENV.fetch("SHOPIFY_CLIENT_SECRET")
    client_id = ENV.fetch("SHOPIFY_CLIENT_ID")

    # Split JWT
    parts = token.split(".")
    return nil unless parts.length == 3

    header_json = base64url_decode(parts[0])
    payload_json = base64url_decode(parts[1])
    signature = base64url_decode(parts[2])
    return nil unless header_json && payload_json && signature

    # Verify algorithm
    header = JSON.parse(header_json)
    return nil unless header["alg"] == "HS256"

    # Verify signature
    signing_input = "#{parts[0]}.#{parts[1]}"
    expected_signature = OpenSSL::HMAC.digest("SHA256", client_secret, signing_input)
    return nil unless ActiveSupport::SecurityUtils.secure_compare(signature, expected_signature)

    # Parse and verify claims
    claims = JSON.parse(payload_json)
    now = Time.now.to_i

    return nil if claims["exp"] && now > claims["exp"]
    return nil if claims["nbf"] && now < (claims["nbf"] - 10) # 10s clock skew grace
    return nil if claims["aud"] && claims["aud"] != client_id

    claims
  rescue JSON::ParserError, ArgumentError
    nil
  end

  def base64url_decode(str)
    # Add padding if needed
    str = str.tr("-_", "+/")
    padding = (4 - str.length % 4) % 4
    str += "=" * padding
    Base64.strict_decode64(str)
  rescue ArgumentError
    nil
  end
end
