require "rails_helper"

RSpec.describe InviteMailer, type: :mailer do
  describe "#invite_email" do
    let(:shop) { create(:shop, name: "Cool Store") }
    let(:user) { create(:user, shop: shop, email: "merchant@example.com", invite_token: "abc123") }
    let(:mail) { InviteMailer.invite_email(user) }

    it "renders the headers" do
      expect(mail.subject).to include("Happypages")
      expect(mail.to).to eq(["merchant@example.com"])
    end

    it "includes the invite link in the body" do
      expect(mail.body.encoded).to include("/invite/abc123")
    end

    it "includes the shop name" do
      expect(mail.body.encoded).to include("Cool Store")
    end
  end
end
