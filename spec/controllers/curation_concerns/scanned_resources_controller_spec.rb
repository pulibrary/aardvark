require 'rails_helper'

describe CurationConcerns::ScannedResourcesController do
  let(:user) { FactoryGirl.create(:user) }
  let(:scanned_resource) { FactoryGirl.create(:scanned_resource, user: user, title: ['Dummy Title']) }
  let(:reloaded) { scanned_resource.reload }

  describe "create" do
    let(:user) { FactoryGirl.create(:admin) }
    before do
      sign_in user
    end
    context "when given a bib id", vcr: { cassette_name: 'bibdata', allow_playback_repeats: true } do
      let(:scanned_resource_attributes) do
        FactoryGirl.attributes_for(:scanned_resource).merge(
          source_metadata_identifier: "2028405"
        )
      end
      it "updates the metadata" do
        post :create, scanned_resource: scanned_resource_attributes
        s = ScannedResource.last
        expect(s.title).to eq ['The Giant Bible of Mainz; 500th anniversary, April fourth, fourteen fifty-two, April fourth, nineteen fifty-two.']
      end
    end
    context "when given a non-existent bib id", vcr: { cassette_name: 'bibdata_not_found', allow_playback_repeats: true } do
      let(:scanned_resource_attributes) do
        FactoryGirl.attributes_for(:scanned_resource).merge(
          source_metadata_identifier: "0000000"
        )
      end
      it "receives an error" do
        expect do
          post :create, scanned_resource: scanned_resource_attributes
        end.not_to change { ScannedResource.count }
        expect(response.status).to be 422
      end
    end

    context "when given a parent" do
      let(:parent) { FactoryGirl.create(:multi_volume_work, user: user) }
      let(:scanned_resource_attributes) do
        FactoryGirl.attributes_for(:scanned_resource).except(:source_metadata_identifier)
      end
      it "creates and indexes its parent" do
        post :create, scanned_resource: scanned_resource_attributes, parent_id: parent.id
        solr_document = ActiveFedora::SolrService.query("id:#{assigns[:curation_concern].id}").first

        expect(solr_document["ordered_by_ssim"]).to eq [parent.id]
      end
    end
  end

  describe "#manifest" do
    let(:solr) { ActiveFedora.solr.conn }
    let(:user) { FactoryGirl.create(:user) }
    context "when requesting JSON" do
      render_views
      before do
        sign_in user
      end
      context "when requesting via SSL" do
        it "returns HTTPS paths" do
          resource = FactoryGirl.build(:scanned_resource)
          allow(resource).to receive(:id).and_return("test")
          solr.add resource.to_solr
          solr.commit

          allow(request).to receive(:ssl?).and_return(true)
          get :manifest, id: "test", format: :json

          expect(response).to be_success
          response_json = JSON.parse(response.body)
          expect(response_json['@id']).to eq "https://plum.com/concern/scanned_resources/test/manifest"
        end
      end
      context "when requesting a child resource" do
        it "returns a manifest" do
          resource = FactoryGirl.build(:scanned_resource)
          allow(resource).to receive(:id).and_return("resource")
          solr.add resource.to_solr.merge(ordered_by_ssim: ["work"])
          solr.commit

          get :manifest, id: "resource", format: :json

          expect(response).to be_success
        end
      end
      it "builds a manifest" do
        resource = FactoryGirl.build(:scanned_resource)
        resource_2 = FactoryGirl.build(:scanned_resource)
        allow(resource).to receive(:id).and_return("test")
        allow(resource_2).to receive(:id).and_return("test2")
        solr.add resource.to_solr
        solr.add resource_2.to_solr
        solr.commit
        expect(ScannedResource).not_to receive(:find)

        get :manifest, id: "test2", format: :json

        expect(response).to be_success
        response_json = JSON.parse(response.body)
        expect(response_json['@id']).to eq "http://plum.com/concern/scanned_resources/test2/manifest"
      end
    end
  end

  describe 'update' do
    let(:scanned_resource_attributes) { { portion_note: 'Section 2', description: 'a description', source_metadata_identifier: '2028405' } }
    before do
      sign_in user
    end
    context 'by default' do
      it 'updates the record but does not refresh the exernal metadata' do
        post :update, id: scanned_resource, scanned_resource: scanned_resource_attributes
        expect(reloaded.portion_note).to eq 'Section 2'
        expect(reloaded.title).to eq ['Dummy Title']
        expect(reloaded.description).to eq 'a description'
      end
    end
    context 'when :refresh_remote_metadata is set', vcr: { cassette_name: 'bibdata', allow_playback_repeats: true } do
      it 'updates remote metadata' do
        post :update, id: scanned_resource, scanned_resource: scanned_resource_attributes, refresh_remote_metadata: true
        expect(reloaded.title).to eq ['The Giant Bible of Mainz; 500th anniversary, April fourth, fourteen fifty-two, April fourth, nineteen fifty-two.']
      end
    end
    context "with collections" do
      let(:resource) { FactoryGirl.create(:scanned_resource_in_collection, user: user) }
      let(:col2) { FactoryGirl.create(:collection, user: user, title: 'Col 2', exhibit_id: 'slug2') }

      before do
        col2.save
      end

      it "updates collection membership" do
        expect(resource.in_collections).to_not be_empty

        updated_attributes = resource.attributes
        updated_attributes[:collection_ids] = [col2.id]
        post :update, id: resource, scanned_resource: updated_attributes
        expect(resource.reload.in_collections).to eq [col2]
      end
    end
  end

  describe "viewing direction and hint" do
    let(:scanned_resource) { FactoryGirl.build(:scanned_resource) }
    let(:user) { FactoryGirl.create(:admin) }
    before do
      sign_in user
      scanned_resource.save!
    end
    it "updates metadata" do
      post :update, id: scanned_resource.id, scanned_resource: { viewing_hint: 'continuous', viewing_direction: 'bottom-to-top' }
      scanned_resource.reload
      expect(scanned_resource.viewing_direction).to eq 'bottom-to-top'
      expect(scanned_resource.viewing_hint).to eq 'continuous'
    end
  end

  describe "show" do
    before do
      sign_in user
    end
    context "when there's a parent" do
      it "is a success" do
        resource = FactoryGirl.create(:scanned_resource)
        work = FactoryGirl.build(:multi_volume_work)
        work.ordered_members << resource
        work.save
        resource.update_index

        get :show, id: resource.id

        expect(response).to be_success
      end
    end
  end

  describe 'pdf' do
    context "when given permission" do
      it 'generates the pdf then redirects to its download url' do
        pdf = double("Actor")
        allow(ScannedResourcePDF).to receive(:new).and_return(pdf)
        allow(pdf).to receive(:render).and_return(true)
        get :pdf, id: scanned_resource
        expect(response).to redirect_to(Rails.application.class.routes.url_helpers.download_path(scanned_resource, file: 'pdf'))
      end
    end
    context "when not given permission" do
      let(:scanned_resource) { FactoryGirl.create(:private_scanned_resource, user: user, title: ['Dummy Title']) }
      context "and not logged in" do
        it "redirects for auth" do
          get :pdf, id: scanned_resource

          expect(response).to redirect_to "http://test.host/users/auth/cas"
        end
      end
      context "and logged in" do
        before do
          sign_in FactoryGirl.create(:user)
        end
        it "redirects to root" do
          get :pdf, id: scanned_resource

          expect(response).to redirect_to Rails.application.class.routes.url_helpers.root_path
        end
      end
    end
  end

  describe "#save_order" do
    let(:resource) { FactoryGirl.create(:scanned_resource, user: user) }
    let(:member) { FactoryGirl.create(:file_set, user: user) }
    let(:member_2) { FactoryGirl.create(:file_set, user: user) }
    let(:new_order) { resource.ordered_member_ids }
    let(:user) { FactoryGirl.create(:admin) }
    render_views
    before do
      3.times { resource.ordered_members << member }
      resource.ordered_members << member_2
      resource.save
      sign_in user
      post :save_order, id: resource.id, order: new_order, format: :json
    end

    context "when given a new order" do
      let(:new_order) { [member.id, member.id, member_2.id, member.id] }
      it "applies it" do
        expect(response).to be_success
        expect(resource.reload.ordered_member_ids).to eq new_order
      end
    end

    context "when given an incomplete order" do
      let(:new_order) { [member.id] }
      it "fails and gives an error" do
        expect(response).not_to be_success
        expect(JSON.parse(response.body)["message"]).to eq "Order given has the wrong number of elements (should be 4)"
        expect(response).to be_bad_request
      end
    end
  end

  describe "#browse_everything_files" do
    let(:resource) { FactoryGirl.create(:scanned_resource, user: user) }
    let(:file) { File.open(Rails.root.join("spec", "fixtures", "files", "color.tif")) }
    let(:user) { FactoryGirl.create(:admin) }
    let(:params) do
      {
        "selected_files" => {
          "0" => {
            "url" => "file://#{file.path}",
            "file_name" => File.basename(file.path),
            "file_size" => file.size
          }
        }
      }
    end
    let(:stub) {}
    before do
      sign_in user
      allow(CharacterizeJob).to receive(:perform_later).once
      allow(BrowseEverythingIngestJob).to receive(:perform_later).and_return(true) if stub
      post :browse_everything_files, id: resource.id, selected_files: params["selected_files"]
    end
    it "appends a new file set" do
      reloaded = resource.reload
      expect(reloaded.file_sets.length).to eq 1
      expect(reloaded.file_sets.first.files.first.mime_type).to eq "image/tiff"
      path = Rails.application.class.routes.url_helpers.curation_concerns_scanned_resource_path(resource)
      expect(response).to redirect_to path
      expect(reloaded.pending_uploads.length).to eq 0
    end
    context "when the job hasn't run yet" do
      let(:stub) { true }
      it "creates pending uploads" do
        expect(resource.pending_uploads.length).to eq 1
        pending_upload = resource.pending_uploads.first
        expect(pending_upload.file_name).to eq File.basename(file.path)
        expect(pending_upload.file_path).to eq file.path
        expect(pending_upload.upload_set_id).not_to be_blank
      end
    end
  end

  describe "#bulk-edit" do
    let(:user) { FactoryGirl.create(:image_editor) }
    before do
      sign_in user
    end
    let(:solr) { ActiveFedora.solr.conn }
    it "sets @members" do
      scanned_resource = FactoryGirl.create(:scanned_resource_with_file, user: user)
      file_set = scanned_resource.members.first
      get :bulk_edit, id: scanned_resource.id

      expect(assigns(:curation_concern)).to eq scanned_resource
      expect(assigns(:members).map(&:id)).to eq [file_set.id]
    end
  end

  describe "#structure" do
    before do
      sign_in user
    end
    let(:solr) { ActiveFedora.solr.conn }
    let(:resource) do
      r = FactoryGirl.build(:scanned_resource)
      allow(r).to receive(:id).and_return("1")
      allow(r.list_source).to receive(:id).and_return("3")
      r
    end
    let(:file_set) do
      f = FactoryGirl.build(:file_set)
      allow(f).to receive(:id).and_return("2")
      f
    end
    before do
      resource.ordered_members << file_set
      solr.add file_set.to_solr.merge(ordered_by_ssim: [resource.id])
      solr.add resource.to_solr
      solr.add resource.list_source.to_solr
      solr.commit
    end
    it "sets @members" do
      get :structure, id: "1"

      expect(assigns(:members).map(&:id)).to eq ["2"]
    end
    it "sets @logical_order" do
      obj = double("logical order object")
      allow_any_instance_of(ScannedResourceShowPresenter).to receive(:logical_order_object).and_return(obj)
      get :structure, id: "1"

      expect(assigns(:logical_order)).to eq obj
    end
  end

  describe "#save_structure" do
    let(:resource) { FactoryGirl.create(:scanned_resource, user: user) }
    let(:file_set) { FactoryGirl.create(:file_set, user: user) }
    let(:user) { FactoryGirl.create(:admin) }
    before do
      sign_in user
      resource.ordered_members << file_set
      resource.save
    end
    let(:nodes) do
      [
        {
          "label": "Chapter 1",
          "nodes": [
            {
              "proxy": file_set.id
            }
          ]
        }
      ]
    end
    it "persists order" do
      post :save_structure, nodes: nodes, id: resource.id

      expect(response.status).to eq 200
      expect(resource.reload.logical_order.order).to eq({ "nodes": nodes }.with_indifferent_access)
    end
  end

  describe "#flag" do
    context "a complete object with an existing workflow note" do
      let(:scanned_resource) { FactoryGirl.create(:scanned_resource, user: user, state: 'complete', workflow_note: ['Existing note']) }
      let(:flag_attributes) { { workflow_note: 'Page 4 is broken' } }
      let(:reloaded) { ScannedResource.find scanned_resource.id }
      before do
        sign_in user
      end

      it "updates the state" do
        post :flag, id: scanned_resource.id, scanned_resource: flag_attributes
        expect(response.status).to eq 302
        expect(flash[:notice]).to eq 'Resource updated'

        expect(reloaded.state).to eq 'flagged'
        expect(reloaded.workflow_note).to include 'Existing note', 'Page 4 is broken'
      end
    end
    context "a complete object without a workflow note" do
      let(:scanned_resource) { FactoryGirl.create(:scanned_resource, user: user, state: 'complete') }
      let(:flag_attributes) { { workflow_note: 'Page 4 is broken' } }
      let(:reloaded) { ScannedResource.find scanned_resource.id }
      before do
        sign_in user
      end

      it "updates the state" do
        post :flag, id: scanned_resource.id, scanned_resource: flag_attributes
        expect(response.status).to eq 302
        expect(flash[:notice]).to eq 'Resource updated'

        expect(reloaded.state).to eq 'flagged'
        expect(reloaded.workflow_note).to include 'Page 4 is broken'
      end
    end
    context "a pending object" do
      let(:scanned_resource) { FactoryGirl.create(:scanned_resource, user: user, state: 'pending') }
      let(:flag_attributes) { { workflow_note: 'Page 4 is broken' } }
      let(:reloaded) { ScannedResource.find scanned_resource.id }
      before do
        sign_in user
      end

      it "receives an error" do
        post :flag, id: scanned_resource.id, scanned_resource: flag_attributes
        expect(response.status).to eq 302
        expect(flash[:alert]).to eq 'Unable to update resource'
        expect(reloaded.state).to eq 'pending'
      end
    end
  end

  describe "marking complete" do
    let(:scanned_resource) { FactoryGirl.create(:scanned_resource, user: user, state: 'final_review') }
    let(:scanned_resource_attributes) { { state: 'complete' } }
    let(:reloaded) { ScannedResource.find scanned_resource.id }

    context "as an admin" do
      let(:admin) { FactoryGirl.create(:admin) }
      before do
        sign_in admin
        Ezid::Client.configure do |conf| conf.logger = Logger.new(File::NULL); end
      end

      it "succeeds", vcr: { cassette_name: "ezid" } do
        post :update, id: scanned_resource.id, scanned_resource: scanned_resource_attributes
        expect(reloaded.state).to eq 'complete'
      end
    end
    context "as an image editor" do
      before do
        sign_in user
      end

      it "fails" do
        post :update, id: scanned_resource.id, scanned_resource: scanned_resource_attributes
        expect(flash[:alert]).to eq 'Unable to mark resource complete'
        expect(reloaded.state).to eq 'final_review'
      end
    end
  end
end
