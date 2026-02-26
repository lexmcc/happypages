require "rails_helper"

RSpec.describe "Specs::Guests", type: :request do
  let(:shop) { create(:shop) }
  let(:project) { Specs::Project.create!(shop: shop, name: "Test Project") }
  let(:session) { Specs::Session.create!(project: project, shop: shop) }
  let(:handoff) { create(:specs_handoff, :with_invite, session: session, invite_accepted_at: nil) }

  before { ENV["ANTHROPIC_API_KEY"] ||= "test-key-for-specs" }

  describe "GET /specs/join/:token" do
    it "renders join form for valid pending token" do
      get specs_guest_join_path(handoff.invite_token)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Test Project")
    end

    it "redirects for invalid token" do
      get specs_guest_join_path("invalid-token")
      expect(response).to redirect_to(root_path)
    end

    it "redirects when expired" do
      handoff.update!(invite_expires_at: 1.day.ago)
      get specs_guest_join_path(handoff.invite_token)
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to include("expired")
    end

    it "redirects to session when already accepted" do
      handoff.update!(invite_accepted_at: Time.current)
      get specs_guest_join_path(handoff.invite_token)
      expect(response).to redirect_to(specs_guest_session_path(handoff.invite_token))
    end

    it "accepts invite with name param and redirects to session" do
      get specs_guest_join_path(handoff.invite_token), params: { name: "Bob Client" }
      handoff.reload
      expect(handoff.to_name).to eq("Bob Client")
      expect(handoff.invite_accepted_at).to be_present
      expect(response).to redirect_to(specs_guest_session_path(handoff.invite_token))
    end
  end

  describe "GET /specs/session/:token" do
    it "shows chat for accepted invite" do
      handoff.update!(invite_accepted_at: Time.current)
      get specs_guest_session_path(handoff.invite_token)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Test Project")
    end

    it "redirects to join for pending invite" do
      get specs_guest_session_path(handoff.invite_token)
      expect(response).to redirect_to(specs_guest_join_path(handoff.invite_token))
    end

    it "sets Current.shop from handoff session" do
      handoff.update!(invite_accepted_at: Time.current)
      get specs_guest_session_path(handoff.invite_token)
      # If Current.shop was not set, view rendering would fail when accessing shop-scoped data
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /specs/session/:token/message" do
    let(:api_response) do
      {
        "content" => [
          { "type" => "text", "text" => "Thanks for that." },
          { "type" => "tool_use", "id" => "toolu_456", "name" => "ask_question", "input" => { "question" => "What colors?", "options" => [{ "label" => "Blue", "description" => "Blue theme" }] } }
        ],
        "stop_reason" => "tool_use",
        "usage" => { "input_tokens" => 100, "output_tokens" => 50 }
      }
    end

    before do
      handoff.update!(invite_accepted_at: Time.current)
      allow_any_instance_of(AnthropicClient).to receive(:messages).and_return(api_response)
    end

    it "processes turn and returns JSON" do
      post specs_guest_message_path(handoff.invite_token), params: { message: "Our brand is blue" }
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["tool_name"]).to eq("ask_question")
    end

    it "passes active_user hash, not user record" do
      expect_any_instance_of(Specs::Orchestrator).to receive(:process_turn).with(
        "Our brand is blue",
        image: nil,
        user: nil,
        active_user: hash_including(name: handoff.to_name, role: "client")
      ).and_call_original

      post specs_guest_message_path(handoff.invite_token), params: { message: "Our brand is blue" }
    end

    it "creates message without user_id" do
      post specs_guest_message_path(handoff.invite_token), params: { message: "Our brand is blue" }
      user_msg = session.messages.where(role: "user").last
      expect(user_msg.user).to be_nil
    end
  end
end
