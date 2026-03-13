require "rails_helper"

RSpec.describe Providers::Shopify::CustomerProvider do
  let(:shop) { create(:shop, :with_credential) }
  let(:provider) { described_class.new(shop) }
  let(:customer_id) { "gid://shopify/Customer/123" }
  let(:namespace) { "app--happypages-friendly-referrals" }

  before do
    stub_request(:post, %r{/admin/api/.*/graphql\.json})
      .to_return(
        status: 200,
        body: { data: { metafieldsSet: { metafields: [{ id: "gid://shopify/Metafield/1" }], userErrors: [] } } }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
  end

  describe "#set_metafields" do
    it "sends multiple metafields in a single GraphQL call" do
      metafields = [
        { key: "referral_code", value: "John023" },
        { key: "referral_page_url", value: "https://app.happypages.co/shop/refer?ref=John023" }
      ]

      result = provider.set_metafields(
        customer_id: customer_id,
        namespace: namespace,
        metafields: metafields
      )

      expect(result[:success]).to be true

      expect(WebMock).to have_requested(:post, %r{graphql}).with { |req|
        body = JSON.parse(req.body)
        mfs = body.dig("variables", "metafields")
        mfs.length == 2 &&
          mfs[0]["key"] == "referral_code" &&
          mfs[1]["key"] == "referral_page_url"
      }
    end

    it "returns success false when userErrors are present" do
      stub_request(:post, %r{/admin/api/.*/graphql\.json})
        .to_return(
          status: 200,
          body: { data: { metafieldsSet: { metafields: [], userErrors: [{ field: "key", message: "is invalid" }] } } }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      result = provider.set_metafields(
        customer_id: customer_id,
        namespace: namespace,
        metafields: [{ key: "bad_key", value: "val" }]
      )

      expect(result[:success]).to be false
      expect(result[:errors]).to be_present
    end

    it "defaults type to single_line_text_field" do
      provider.set_metafields(
        customer_id: customer_id,
        namespace: namespace,
        metafields: [{ key: "test", value: "val" }]
      )

      request_body = nil
      expect(WebMock).to have_requested(:post, %r{graphql}).with { |req|
        request_body = JSON.parse(req.body)
        true
      }

      metafield_input = request_body.dig("variables", "metafields", 0)
      expect(metafield_input["type"]).to eq("single_line_text_field")
    end
  end

  describe "#set_metafield" do
    it "delegates to set_metafields with a single entry" do
      result = provider.set_metafield(
        customer_id: customer_id,
        namespace: namespace,
        key: "referral_code",
        value: "John023"
      )

      expect(result[:success]).to be true

      expect(WebMock).to have_requested(:post, %r{graphql}).with { |req|
        body = JSON.parse(req.body)
        metafields = body.dig("variables", "metafields")
        metafields.length == 1 && metafields[0]["key"] == "referral_code"
      }
    end
  end
end
