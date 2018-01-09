# frozen_string_literal: true
require 'rails_helper'

RSpec.describe VocabulariesController, type: :controller do
  let(:user) { FactoryGirl.create(:admin) }

  before do
    sign_in user
  end

  # This should return the minimal set of attributes required to create a valid
  # Vocabulary. As you add validations to Vocabulary, be sure to
  # adjust the attributes here as well.
  let(:valid_attributes) { { label: 'Test Vocab' } }

  let(:invalid_attributes) { { label: nil } }

  describe "GET #index" do
    it "assigns all vocabularies as @vocabularies" do
      vocabulary = Vocabulary.create! valid_attributes
      get :index, params: {}
      expect(assigns(:vocabularies)).to eq([vocabulary])
    end

    it "hides categories" do
      vocabulary = Vocabulary.create! valid_attributes
      Vocabulary.create! label: 'Category', parent: vocabulary
      get :index, params: {}
      expect(assigns(:vocabularies)).to eq([vocabulary])
    end
  end

  describe "GET #show" do
    it "assigns the requested vocabulary as @vocabulary" do
      vocabulary = Vocabulary.create! valid_attributes
      get :show, params: { id: vocabulary.to_param }
      expect(assigns(:vocabulary)).to eq(vocabulary)
    end

    it "serves JSON-LD" do
      vocabulary = Vocabulary.create! valid_attributes
      get :show, params: { id: vocabulary.to_param, format: :jsonld }

      json = JSON.parse(response.body)
      expect(json['@id']).to eq(vocabulary_url(vocabulary, locale: nil))
      expect(json['@type']).to eq('skos:ConceptScheme')
      expect(json['pref_label']).to eq(vocabulary.label)
    end

    it "serves Turtle", vcr: { cassette_name: 'context.json' } do
      vocabulary = Vocabulary.create! valid_attributes
      get :show, params: { id: vocabulary.to_param, format: :ttl }

      expect(response.body).to include "<http://www.w3.org/2004/02/skos/core#prefLabel> \"#{vocabulary.label}\""
    end

    it "serves N-Triples", vcr: { cassette_name: 'context.json' } do
      vocabulary = Vocabulary.create! valid_attributes
      get :show, params: { id: vocabulary.to_param, format: :nt }

      expect(response.body).to include "<http://www.w3.org/2004/02/skos/core#prefLabel> \"#{vocabulary.label}\""
    end
  end

  describe "GET #new" do
    it "assigns a new vocabulary as @vocabulary" do
      get :new, params: {}
      expect(assigns(:vocabulary)).to be_a_new(Vocabulary)
    end
  end

  describe "GET #edit" do
    it "assigns the requested vocabulary as @vocabulary" do
      vocabulary = Vocabulary.create! valid_attributes
      get :edit, params: { id: vocabulary.to_param }
      expect(assigns(:vocabulary)).to eq(vocabulary)
    end
  end

  describe "POST #create" do
    context "with valid params" do
      it "creates a new Vocabulary" do
        expect {
          post :create, params: { vocabulary: valid_attributes }
        }.to change(Vocabulary, :count).by(1)
      end

      it "registers the newly created Vocabulary" do
        post :create, params: { vocabulary: valid_attributes }
        vocab = Vocabulary.first
        expect(Qa::Authorities::Local.subauthority_for(vocab.label)).not_to be_blank
      end

      it "assigns a newly created vocabulary as @vocabulary" do
        post :create, params: { vocabulary: valid_attributes }
        expect(assigns(:vocabulary)).to be_a(Vocabulary)
        expect(assigns(:vocabulary)).to be_persisted
      end

      it "redirects to the created vocabulary" do
        post :create, params: { vocabulary: valid_attributes }
        expect(response).to redirect_to(Vocabulary.last)
      end
    end

    context "with a parent vocabulary" do
      let(:parent) { FactoryGirl.create(:vocabulary, label: 'Parent Vocab') }
      let(:attributes_with_parent) { valid_attributes.merge(parent_id: parent.id) }

      it "assigns a newly created vocabulary as @vocabulary" do
        post :create, params: { vocabulary: attributes_with_parent }
        expect(assigns(:vocabulary)).to be_a(Vocabulary)
        expect(assigns(:vocabulary)).to be_persisted
        expect(assigns(:vocabulary).parent).to eq(parent)
      end
    end

    context "with invalid params" do
      it "assigns a newly created but unsaved vocabulary as @vocabulary" do
        post :create, params: { vocabulary: invalid_attributes }
        expect(assigns(:vocabulary)).to be_a_new(Vocabulary)
      end

      it "re-renders the 'new' template" do
        post :create, params: { vocabulary: invalid_attributes }
        expect(response).to render_template("new")
      end
    end
  end

  describe "PUT #update" do
    context "with valid params" do
      let(:new_attributes) { { label: 'Updated Label' } }

      it "updates the requested vocabulary" do
        vocabulary = Vocabulary.create! valid_attributes
        put :update, params: { id: vocabulary.to_param, vocabulary: new_attributes }
        vocabulary.reload
        expect(assigns(:vocabulary).label).to eq('Updated Label')
      end

      it "assigns the requested vocabulary as @vocabulary" do
        vocabulary = Vocabulary.create! valid_attributes
        put :update, params: { id: vocabulary.to_param, vocabulary: valid_attributes }
        expect(assigns(:vocabulary)).to eq(vocabulary)
      end

      it "redirects to the vocabulary" do
        vocabulary = Vocabulary.create! valid_attributes
        put :update, params: { id: vocabulary.to_param, vocabulary: valid_attributes }
        expect(response).to redirect_to(vocabulary)
      end
    end

    context "with invalid params" do
      it "assigns the vocabulary as @vocabulary" do
        vocabulary = Vocabulary.create! valid_attributes
        put :update, params: { id: vocabulary.to_param, vocabulary: invalid_attributes }
        expect(assigns(:vocabulary)).to eq(vocabulary)
      end

      it "re-renders the 'edit' template" do
        vocabulary = Vocabulary.create! valid_attributes
        put :update, params: { id: vocabulary.to_param, vocabulary: invalid_attributes }
        expect(response).to render_template("edit")
      end
    end
  end

  describe "DELETE #destroy" do
    it "destroys the requested vocabulary" do
      vocabulary = Vocabulary.create! valid_attributes
      expect {
        delete :destroy, params: { id: vocabulary.to_param }
      }.to change(Vocabulary, :count).by(-1)
    end

    it "redirects to the vocabularies list" do
      vocabulary = Vocabulary.create! valid_attributes
      delete :destroy, params: { id: vocabulary.to_param }
      expect(response).to redirect_to(vocabularies_url)
    end
  end
end
