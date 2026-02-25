require "rails_helper"

RSpec.describe "Superadmin::SpecsClients", type: :request do
  include ActiveJob::TestHelper

  let(:password) { "superadmin_pass" }
  let(:digest) { BCrypt::Password.create(password) }
  let(:organisation) { create(:organisation) }

  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:[]).with("SUPER_ADMIN_EMAIL").and_return("admin@test.com")
    allow(ENV).to receive(:[]).with("SUPER_ADMIN_PASSWORD_DIGEST").and_return(digest)

    post superadmin_login_path, params: { email: "admin@test.com", password: password }
  end

  describe "POST /superadmin/organisations/:id/specs_clients" do
    it "creates a client and sends invite" do
      perform_enqueued_jobs do
        expect {
          post superadmin_organisation_specs_clients_path(organisation), params: {
            specs_client: { email: "new@example.com", name: "New Client" }
          }
        }.to change(Specs::Client, :count).by(1)
          .and change(ActionMailer::Base.deliveries, :count).by(1)
      end

      client = Specs::Client.last
      expect(client.email).to eq("new@example.com")
      expect(client.invite_token).to be_present
      expect(client.invite_expires_at).to be_present
      expect(response).to redirect_to(manage_superadmin_organisation_path(organisation))
    end

    it "rejects blank email" do
      post superadmin_organisation_specs_clients_path(organisation), params: {
        specs_client: { email: "", name: "No Email" }
      }
      expect(response).to redirect_to(manage_superadmin_organisation_path(organisation))
      expect(flash[:alert]).to be_present
    end
  end

  describe "POST /superadmin/organisations/:id/specs_clients/:id/send_invite" do
    let!(:client) { create(:specs_client, organisation: organisation) }

    it "sends an invite email" do
      perform_enqueued_jobs do
        expect {
          post send_invite_superadmin_organisation_specs_client_path(organisation, client)
        }.to change(ActionMailer::Base.deliveries, :count).by(1)
      end

      client.reload
      expect(client.invite_token).to be_present
      expect(client.invite_expires_at).to be_present
      expect(response).to redirect_to(manage_superadmin_organisation_path(organisation))
    end
  end

  context "without superadmin session" do
    before { delete superadmin_logout_path }

    it "redirects to login" do
      post superadmin_organisation_specs_clients_path(organisation), params: {
        specs_client: { email: "test@example.com", name: "Test" }
      }
      expect(response).to redirect_to(superadmin_login_path)
    end
  end
end
