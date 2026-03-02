require "rails_helper"

RSpec.describe ShopifySessionTokenVerifiable do
  # Create a test class that includes the concern
  let(:verifier) do
    Class.new do
      include ShopifySessionTokenVerifiable
      # Make private methods accessible for testing
      public :verify_session_token, :base64url_decode
    end.new
  end

  let(:default_client_id) { ENV.fetch("SHOPIFY_CLIENT_ID") }
  let(:default_client_secret) { ENV.fetch("SHOPIFY_CLIENT_SECRET") }
  let(:shop_domain) { "test-store.myshopify.com" }

  def build_jwt(payload, secret)
    header = { alg: "HS256", typ: "JWT" }
    header_b64 = base64url_encode(header.to_json)
    payload_b64 = base64url_encode(payload.to_json)
    signing_input = "#{header_b64}.#{payload_b64}"
    signature = OpenSSL::HMAC.digest("SHA256", secret, signing_input)
    signature_b64 = base64url_encode(signature)
    "#{header_b64}.#{payload_b64}.#{signature_b64}"
  end

  def base64url_encode(str)
    Base64.strict_encode64(str).tr("+/", "-_").delete("=")
  end

  def valid_claims(aud:)
    {
      iss: "https://#{shop_domain}/admin",
      dest: "https://#{shop_domain}",
      aud: aud,
      sub: "12345",
      exp: 5.minutes.from_now.to_i,
      nbf: 5.seconds.ago.to_i,
      iat: Time.now.to_i,
      jti: SecureRandom.uuid
    }
  end

  context "JWT with aud matching global client_id" do
    it "verifies with global secret and returns claims" do
      token = build_jwt(valid_claims(aud: default_client_id), default_client_secret)
      claims = verifier.verify_session_token(token)

      expect(claims).to be_present
      expect(claims["aud"]).to eq(default_client_id)
    end

    it "rejects token signed with wrong secret" do
      token = build_jwt(valid_claims(aud: default_client_id), "wrong-secret")
      claims = verifier.verify_session_token(token)

      expect(claims).to be_nil
    end
  end

  context "JWT with aud matching a ShopIntegration's app_client_id" do
    let(:shop) { create(:shop) }
    let!(:integration) do
      create(:shop_integration, :with_token, :with_custom_app, shop: shop)
    end

    it "verifies with the integration's app_client_secret" do
      token = build_jwt(
        valid_claims(aud: integration.app_client_id),
        integration.app_client_secret
      )
      claims = verifier.verify_session_token(token)

      expect(claims).to be_present
      expect(claims["aud"]).to eq(integration.app_client_id)
    end

    it "rejects token signed with the global secret" do
      token = build_jwt(
        valid_claims(aud: integration.app_client_id),
        default_client_secret
      )
      claims = verifier.verify_session_token(token)

      expect(claims).to be_nil
    end
  end

  context "JWT with unknown aud" do
    it "returns nil" do
      token = build_jwt(
        valid_claims(aud: "unknown-client-id"),
        "some-secret"
      )
      claims = verifier.verify_session_token(token)

      expect(claims).to be_nil
    end
  end

  context "expired token" do
    it "returns nil" do
      payload = valid_claims(aud: default_client_id).merge(exp: 1.minute.ago.to_i)
      token = build_jwt(payload, default_client_secret)

      expect(verifier.verify_session_token(token)).to be_nil
    end
  end

  context "not-yet-valid token (nbf in future beyond grace)" do
    it "returns nil" do
      payload = valid_claims(aud: default_client_id).merge(nbf: 1.minute.from_now.to_i)
      token = build_jwt(payload, default_client_secret)

      expect(verifier.verify_session_token(token)).to be_nil
    end
  end
end
