require "rails_helper"

RSpec.describe "Specs::Projects", type: :request do
  let(:organisation) { create(:organisation) }
  let(:client) { create(:specs_client, :with_password, organisation: organisation) }

  before do
    post specs_login_path, params: { email: client.email, password: "SecurePass123!" }
  end

  describe "GET /specs/projects/new" do
    it "renders the new project form" do
      get new_specs_project_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /specs/projects" do
    it "creates a project with a session" do
      expect {
        post specs_projects_path, params: { specs_project: { name: "New Spec" } }
      }.to change(Specs::Project, :count).by(1)
        .and change(Specs::Session, :count).by(1)

      project = Specs::Project.last
      expect(project.organisation).to eq(organisation)
      expect(project.shop).to be_nil
      expect(response).to redirect_to(specs_project_path(project))

      session = project.sessions.first
      expect(session.specs_client).to eq(client)
      expect(session.shop).to be_nil
    end

    it "rejects blank name" do
      post specs_projects_path, params: { specs_project: { name: "" } }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "GET /specs/projects/:id" do
    let(:project) { create(:specs_project, :org_scoped, organisation: organisation) }
    let!(:session) { create(:specs_session, :org_scoped, project: project, specs_client: client) }

    it "shows the project" do
      get specs_project_path(project)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(project.name)
    end

    it "does not show projects from other organisations" do
      other_org = create(:organisation, name: "Other")
      other_project = create(:specs_project, :org_scoped, organisation: other_org)
      get specs_project_path(other_project)
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /specs/projects/:id/export" do
    let(:project) { create(:specs_project, :org_scoped, organisation: organisation) }
    let!(:session) do
      create(:specs_session, :org_scoped, :with_outputs, project: project, specs_client: client)
    end

    it "exports client brief" do
      get specs_project_export_path(project, type: "brief")
      expect(response).to have_http_status(:ok)
      expect(response.headers["Content-Type"]).to include("text/markdown")
    end

    it "rejects spec export" do
      get specs_project_export_path(project, type: "spec")
      expect(response).to have_http_status(:bad_request)
    end
  end
end
