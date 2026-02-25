require "rails_helper"

RSpec.describe SpecsClientMailer, type: :mailer do
  describe "#invite_email" do
    let(:organisation) { create(:organisation, name: "Acme Corp") }
    let(:client) { create(:specs_client, :invited, organisation: organisation, email: "client@example.com") }
    let(:mail) { described_class.invite_email(client) }

    it "sends to the client email" do
      expect(mail.to).to eq(["client@example.com"])
    end

    it "includes the organisation name in subject" do
      expect(mail.subject).to include("Acme Corp")
    end

    it "includes the invite URL in the body" do
      expect(mail.body.encoded).to include(client.invite_token)
    end
  end
end
