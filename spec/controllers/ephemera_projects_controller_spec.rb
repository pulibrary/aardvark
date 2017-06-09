require 'rails_helper'

# This spec was generated by rspec-rails when you ran the scaffold generator.
# It demonstrates how one might use RSpec to specify the controller code that
# was generated by Rails when you ran the scaffold generator.
#
# It assumes that the implementation code is generated by the rails scaffold
# generator.  If you are using any extension libraries to generate different
# controller code, this generated spec may or may not pass.
#
# It only uses APIs available in rails and/or rspec-rails.  There are a number
# of tools you can use to make these specs even more expressive, but we're
# sticking to rails and rspec-rails APIs to keep things simple and stable.
#
# Compared to earlier versions of this generator, there is very limited use of
# stubs and message expectations in this spec.  Stubs are only used when there
# is no simpler way to get a handle on the object needed for the example.
# Message expectations are only used when there is no simpler way to specify
# that an instance is receiving a specific message.

RSpec.describe EphemeraProjectsController, type: :controller do
  # This should return the minimal set of attributes required to create a valid
  # EphemeraProject. As you add validations to EphemeraProject, be sure to
  # adjust the attributes here as well.
  let(:valid_attributes) { { name: "Test Project" } }

  let(:invalid_attributes) { { name: nil } }

  # This should return the minimal set of values that should be in the session
  # in order to pass any filters (e.g. authentication) defined in
  # EphemeraProjectsController. Be sure to keep this updated too.
  let(:valid_session) { {} }

  describe "GET #index" do
    it "assigns all ephemera_projects as @ephemera_projects" do
      ephemera_project = EphemeraProject.create! valid_attributes
      get :index, params: {}, session: valid_session
      expect(assigns(:ephemera_projects)).to eq([ephemera_project])
    end
  end

  describe "GET #show" do
    it "assigns the requested ephemera_project as @ephemera_project" do
      ephemera_project = EphemeraProject.create! valid_attributes
      get :show, params: { id: ephemera_project.to_param }, session: valid_session
      expect(assigns(:ephemera_project)).to eq(ephemera_project)
    end
  end

  describe "GET #new" do
    it "assigns a new ephemera_project as @ephemera_project" do
      get :new, params: {}, session: valid_session
      expect(assigns(:ephemera_project)).to be_a_new(EphemeraProject)
    end
  end

  describe "GET #edit" do
    it "assigns the requested ephemera_project as @ephemera_project" do
      ephemera_project = EphemeraProject.create! valid_attributes
      get :edit, params: { id: ephemera_project.to_param }, session: valid_session
      expect(assigns(:ephemera_project)).to eq(ephemera_project)
    end
  end

  describe "POST #create" do
    context "with valid params" do
      it "creates a new EphemeraProject" do
        expect {
          post :create, params: { ephemera_project: valid_attributes }, session: valid_session
        }.to change(EphemeraProject, :count).by(1)
      end

      it "assigns a newly created ephemera_project as @ephemera_project" do
        post :create, params: { ephemera_project: valid_attributes }, session: valid_session
        expect(assigns(:ephemera_project)).to be_a(EphemeraProject)
        expect(assigns(:ephemera_project)).to be_persisted
      end

      it "redirects to the created ephemera_project" do
        post :create, params: { ephemera_project: valid_attributes }, session: valid_session
        expect(response).to redirect_to(EphemeraProject.last)
      end
    end

    context "with invalid params" do
      it "assigns a newly created but unsaved ephemera_project as @ephemera_project" do
        post :create, params: { ephemera_project: invalid_attributes }, session: valid_session
        expect(assigns(:ephemera_project)).to be_a_new(EphemeraProject)
      end
    end
  end

  describe "PUT #update" do
    context "with valid params" do
      let(:new_attributes) { { name: "Updated Name" } }

      it "updates the requested ephemera_project" do
        ephemera_project = EphemeraProject.create! valid_attributes
        put :update, params: { id: ephemera_project.to_param, ephemera_project: new_attributes }, session: valid_session
        ephemera_project.reload
        expect(ephemera_project.name).to eq("Updated Name")
      end

      it "assigns the requested ephemera_project as @ephemera_project" do
        ephemera_project = EphemeraProject.create! valid_attributes
        put :update, params: { id: ephemera_project.to_param, ephemera_project: valid_attributes }, session: valid_session
        expect(assigns(:ephemera_project)).to eq(ephemera_project)
      end

      it "redirects to the ephemera_project" do
        ephemera_project = EphemeraProject.create! valid_attributes
        put :update, params: { id: ephemera_project.to_param, ephemera_project: valid_attributes }, session: valid_session
        expect(response).to redirect_to(ephemera_project)
      end
    end

    context "with invalid params" do
      it "assigns the ephemera_project as @ephemera_project" do
        ephemera_project = EphemeraProject.create! valid_attributes
        put :update, params: { id: ephemera_project.to_param, ephemera_project: invalid_attributes }, session: valid_session
        expect(assigns(:ephemera_project)).to eq(ephemera_project)
      end

      it "re-renders the 'edit' template" do
        ephemera_project = EphemeraProject.create! valid_attributes
        put :update, params: { id: ephemera_project.to_param, ephemera_project: invalid_attributes }, session: valid_session
        expect(response).to render_template("edit")
      end
    end
  end

  describe "DELETE #destroy" do
    it "destroys the requested ephemera_project" do
      ephemera_project = EphemeraProject.create! valid_attributes
      expect {
        delete :destroy, params: { id: ephemera_project.to_param }, session: valid_session
      }.to change(EphemeraProject, :count).by(-1)
    end

    it "redirects to the ephemera_projects list" do
      ephemera_project = EphemeraProject.create! valid_attributes
      delete :destroy, params: { id: ephemera_project.to_param }, session: valid_session
      expect(response).to redirect_to(ephemera_projects_url)
    end
  end
end
