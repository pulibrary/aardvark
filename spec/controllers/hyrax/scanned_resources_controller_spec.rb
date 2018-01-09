# frozen_string_literal: true
require 'rails_helper'

describe Hyrax::ScannedResourcesController, admin_set: true do
  let(:user) { FactoryGirl.create(:user) }
  let(:scanned_resource) { FactoryGirl.create(:complete_scanned_resource, user: user, title: ['Dummy Title'], identifier: ['ark:/99999/fk4445wg45']) }
  let(:reloaded) { scanned_resource.reload }

  describe "delete" do
    let(:user) { FactoryGirl.create(:admin) }
    before do
      sign_in user
    end

    it "deletes a record and redirects to the root path" do
      s = FactoryGirl.create(:scanned_resource)

      delete :destroy, params: { id: s.id, format: :html }

      expect(ScannedResource.all.length).to eq 0
      expect(response).to redirect_to "/?locale=en"
    end

    it "fires a delete event" do
      s = FactoryGirl.create(:scanned_resource)
      manifest_generator = instance_double(ManifestEventGenerator, record_deleted: true)
      allow(ManifestEventGenerator).to receive(:new).and_return(manifest_generator)

      delete :destroy, params: { id: s.id }

      expect(manifest_generator).to have_received(:record_deleted)
    end
  end
  describe "new" do
    let(:user) { FactoryGirl.create(:admin) }
    before do
      sign_in user
    end
    context "when given a parent id" do
      let(:mvw) { FactoryGirl.create :multi_volume_work }
      it "copies the parent's visibility" do
        get :new, params: { parent_id: mvw.id, locale: :en }
        expect(assigns(:curation_concern).visibility).to eq mvw.visibility
      end
    end
    context "when given a bogus parent id" do
      it "does not error" do
        expect { get :new, params: { parent_id: 'blargh' } }.not_to raise_error
      end
    end
  end
  describe "create" do
    let(:user) { FactoryGirl.create(:admin) }
    before do
      sign_in user
    end
    context "when given a bib id", vcr: { cassette_name: 'bibdata', record: :new_episodes } do
      let(:scanned_resource_attributes) do
        FactoryGirl.attributes_for(:scanned_resource).merge(
          source_metadata_identifier:  "2028405",
          rights_statement: "http://rightsstatements.org/vocab/NKC/1.0/"
        )
      end
      it "updates the metadata" do
        post :create, params: { scanned_resource: scanned_resource_attributes }
        s = ScannedResource.last
        expect(s.title.first.to_s).to eq 'The Giant Bible of Mainz; 500th anniversary, April fourth, fourteen fifty-two, April fourth, nineteen fifty-two.'
      end
      it "posts a creation event to the queue" do
        manifest_generator = instance_double(ManifestEventGenerator, record_created: true, record_updated: true)
        allow(ManifestEventGenerator).to receive(:new).and_return(manifest_generator)

        post :create, params: { scanned_resource: scanned_resource_attributes }

        expect(manifest_generator).to have_received(:record_created).with(ScannedResource.last)
      end
    end
    context "when given a non-existent bib id", vcr: { cassette_name: 'bibdata_not_found', allow_playback_repeats: true } do
      let(:scanned_resource_attributes) do
        FactoryGirl.attributes_for(:scanned_resource).merge(
          source_metadata_identifier: "0000000",
          rights_statement: "http://rightsstatements.org/vocab/NKC/1.0/"
        )
      end
      it "receives an error" do
        expect do
          post :create, params: { scanned_resource: scanned_resource_attributes }
        end.not_to change { ScannedResource.count }
        expect(response.status).to be 422
      end
      it "doesn't post a creation event" do
        manifest_generator = instance_double(ManifestEventGenerator, record_created: true)
        allow(ManifestEventGenerator).to receive(:new).and_return(manifest_generator)

        post :create, params: { scanned_resource: scanned_resource_attributes }

        expect(manifest_generator).not_to have_received(:record_created)
      end
    end
    context "when given a pulfa id", vcr: { cassette_name: 'pulfa', record: :new_episodes } do
      let(:scanned_resource_attributes) do
        FactoryGirl.attributes_for(:scanned_resource).merge(
          source_metadata_identifier:  "RBD1.1_c284",
          rights_statement: "http://rightsstatements.org/vocab/NKC/1.0/"
        )
      end
      it "updates the metadata" do
        post :create, params: { scanned_resource: scanned_resource_attributes }
        s = ScannedResource.last
        expect(s.title.first.to_s).to eq 'House - Gift Books, Works By and About Derrida, and Related Items - Kostas Axelos. Vers la pensée planétaire.'
      end
      it "posts a creation event to the queue" do
        manifest_generator = instance_double(ManifestEventGenerator, record_created: true, record_updated: true)
        allow(ManifestEventGenerator).to receive(:new).and_return(manifest_generator)

        post :create, params: { scanned_resource: scanned_resource_attributes }

        expect(manifest_generator).to have_received(:record_created).with(ScannedResource.last)
      end
    end
    context "when selecting a collection" do
      let(:collection) { FactoryGirl.create(:collection, user: user) }
      let(:scanned_resource_attributes) do
        FactoryGirl.attributes_for(:scanned_resource).except(:source_metadata_identifier).merge(
          member_of_collection_ids: [collection.id],
          rights_statement: "http://rightsstatements.org/vocab/NKC/1.0/"
        )
      end
      it "successfully add the resource to the collection" do
        post :create, params: { scanned_resource: scanned_resource_attributes }
        s = ScannedResource.last
        expect(s.member_of_collections).to eq [collection]
      end
      it "posts the collection slugs to the event endpoint" do
        messaging_client = instance_double(MessagingClient, publish: true)
        manifest_generator = ManifestEventGenerator.new(messaging_client)
        allow(ManifestEventGenerator).to receive(:new).and_return(manifest_generator)

        post :create, params: { scanned_resource: scanned_resource_attributes }

        s = ScannedResource.last

        expect(messaging_client).to have_received(:publish).with(
          {
            "id" => s.id,
            "event" => "CREATED",
            "manifest_url" => "http://plum.com/concern/scanned_resources/#{s.id}/manifest",
            "collection_slugs" => s.member_of_collections.map(&:exhibit_id)
          }.to_json
        )
      end
    end
  end

  describe "#manifest" do
    let(:solr) { ActiveFedora.solr.conn }
    let(:user) { FactoryGirl.create(:user) }
    context "when not logged in" do
      it "renders a blank JSON Hash" do
        resource = FactoryGirl.create(:campus_only_scanned_resource)
        get :manifest, params: { id: resource.id, format: :json }
        expect(response.body).to eq "{}"
      end
      context "and an authentication token is given" do
        it "renders the full manifest" do
          resource = FactoryGirl.create(:private_scanned_resource)
          authorization_token = AuthToken.create(groups: ["fulfiller"])
          get :manifest, params: { id: resource.id, format: :json, auth_token: authorization_token.token }

          expect(response.body).not_to eq "{}"
        end
      end
    end
    context "when requesting JSON" do
      render_views
      before do
        sign_in user
      end
      context "when requesting via SSL" do
        it "returns HTTPS paths" do
          resource = FactoryGirl.create(:complete_scanned_resource)
          allow(request).to receive(:ssl?).and_return(true)

          get :manifest, params: { id: resource.id, format: :json }

          expect(response).to be_success
          response_json = JSON.parse(response.body)
          expect(response_json['@id']).to eq "http://plum.com/concern/scanned_resources/#{resource.id}/manifest"
        end
      end
      context "when requesting a child resource" do
        it "returns a manifest" do
          resource = FactoryGirl.create(:complete_scanned_resource)
          allow(resource).to receive(:id).and_return("resource")
          solr.add resource.to_solr.merge(ordered_by_ssim: ["work"])
          solr.commit

          get :manifest, params: { id: "resource", format: :json }

          expect(response).to be_success
        end
      end
      it "builds a manifest" do
        resource = FactoryGirl.create(:complete_scanned_resource)
        resource_2 = FactoryGirl.create(:complete_scanned_resource)
        allow(resource).to receive(:id).and_return("test")
        allow(resource_2).to receive(:id).and_return("test2")
        solr.add resource.to_solr
        solr.add resource_2.to_solr
        solr.commit
        expect(ScannedResource).not_to receive(:find)

        get :manifest, params: { id: "test2", format: :json }

        expect(response).to be_success
        response_json = JSON.parse(response.body)
        expect(response_json['@id']).to eq "http://plum.com/concern/scanned_resources/test2/manifest"
        expect(response_json["service"]).to eq nil
      end
    end
  end

  describe 'update' do
    let(:scanned_resource_attributes) { { portion_note: 'Section 2', description: ['a description'], source_metadata_identifier: '2028405' } }
    before do
      sign_in user
    end
    context 'by default' do
      it 'updates the record but does not refresh the exernal metadata' do
        post :update, params: { id: scanned_resource, scanned_resource: scanned_resource_attributes }
        expect(reloaded.portion_note).to eq ['Section 2']
        expect(reloaded.title).to eq ['Dummy Title']
        expect(reloaded.description).to eq ['a description']
      end
      it "can update the start_canvas" do
        post :update, params: { id: scanned_resource, scanned_resource: { start_canvas: "1" } }
        expect(reloaded.start_canvas).to eq ["1"]
      end
      context "when in a collection" do
        let(:scanned_resource) { FactoryGirl.create(:scanned_resource_in_collection, user: user) }
        it "doesn't remove the item from collections" do
          patch :update, params: { id: scanned_resource, scanned_resource: { ocr_language: [], viewing_hint: "individuals", viewing_direction: "left-to-right" } }
          expect(reloaded.member_of_collections).not_to be_blank
        end
      end
      it "posts an update event" do
        manifest_generator = instance_double(ManifestEventGenerator, record_updated: true)
        allow(ManifestEventGenerator).to receive(:new).and_return(manifest_generator)

        post :update, params: { id: scanned_resource, scanned_resource: scanned_resource_attributes }

        expect(manifest_generator).to have_received(:record_updated).with(scanned_resource)
      end
    end
    context 'when :refresh_remote_metadata is set', vcr: { cassette_name: 'bibdata', allow_playback_repeats: true } do
      it 'updates remote metadata' do
        allow(Ezid::Identifier).to receive(:modify)
        allow(Ezid::Client.config).to receive(:user).and_return("test")
        post :update, params: { id: scanned_resource, scanned_resource: scanned_resource_attributes, refresh_remote_metadata: true }
        expect(reloaded.title.first.to_s).to eq 'The Giant Bible of Mainz; 500th anniversary, April fourth, fourteen fifty-two, April fourth, nineteen fifty-two.'
        expect(Ezid::Identifier).to have_received(:modify)
      end
    end
    context "when ocr_language is set" do
      let(:scanned_resource_attributes) do
        {
          ocr_language: ["eng"]
        }
      end

      let(:scanned_resource) do
        s = FactoryGirl.build(:scanned_resource, user: user, title: ['Dummy Title'])
        s.ordered_members << file_set
        s.save
        s
      end
      let(:file_set) { FactoryGirl.create(:file_set) }

      around { |example| perform_enqueued_jobs(&example) }

      it "updates OCR on file sets" do
        ocr_runner = instance_double(OCRRunner)
        allow(OCRRunner).to receive(:new).and_return(ocr_runner)
        allow(ocr_runner).to receive(:from_file)

        post :update, params: { id: scanned_resource, scanned_resource: scanned_resource_attributes }

        expect(OCRRunner).to have_received(:new).with(file_set)
      end
    end
    context "with collections" do
      let(:resource) { FactoryGirl.create(:scanned_resource_in_collection, user: user) }
      let(:col2) { FactoryGirl.create(:collection, user: user, title: ['Col 2']) }

      before do
        col2.save
      end

      it "updates collection membership" do
        expect(resource.member_of_collections).not_to be_empty

        updated_attributes = {}
        updated_attributes[:member_of_collection_ids] = [col2.id]
        post :update, params: { id: resource, scanned_resource: updated_attributes }
        expect(resource.reload.member_of_collections).to eq [col2]
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
      post :update, params: { id: scanned_resource.id, scanned_resource: { viewing_hint: 'continuous', viewing_direction: 'bottom-to-top' } }
      scanned_resource.reload
      expect(scanned_resource.viewing_direction).to eq ['bottom-to-top']
      expect(scanned_resource.viewing_hint).to eq ['continuous']
    end
  end

  describe "show" do
    before do
      sign_in user if user
    end
    context "when the user is anonymous" do
      let(:user) { nil }
      context "and the work's incomplete" do
        it "redirects for auth" do
          resource = FactoryGirl.create(:pending_scanned_resource)

          get :show, params: { id: resource.id }

          expect(response).to be_redirect
        end
      end
      context "and the work's flagged" do
        it "works" do
          resource = FactoryGirl.create(:flagged_scanned_resource)

          get :show, params: { id: resource.id }

          expect(response).to be_success
        end
      end
      context "and the work's complete" do
        it "works" do
          resource = FactoryGirl.create(:complete_scanned_resource)

          get :show, params: { id: resource.id }

          expect(response).to be_success
        end
      end
    end
    context "when the user's an admin" do
      let(:user) { FactoryGirl.create(:admin) }
      context "and the work's incomplete" do
        it "works" do
          resource = FactoryGirl.create(:pending_scanned_resource)

          get :show, params: { id: resource.id }

          expect(response).to be_success
        end
      end
    end
    context "when there's a parent" do
      it "is a success" do
        resource = FactoryGirl.create(:complete_scanned_resource)
        work = FactoryGirl.build(:multi_volume_work)
        work.ordered_members << resource
        work.save
        resource.update_index

        get :show, params: { id: resource.id }

        expect(response).to be_success
      end
    end
  end

  describe 'pdf' do
    before do
      sign_in user if sign_in_user
    end
    context "when requesting color" do
      context "and given permission" do
        let(:user) { FactoryGirl.create(:admin) }
        let(:sign_in_user) { user }
        it "works" do
          pdf = double("Actor")
          allow(ScannedResourcePDF).to receive(:new).with(anything, quality: "color").and_return(pdf)
          allow(pdf).to receive(:render).and_return(true)
          get :pdf, params: { id: scanned_resource, pdf_quality: "color" }
          expect(response).to redirect_to(ManifestBuilder::HyraxManifestHelper.new.download_path(scanned_resource, file: 'color-pdf', locale: 'en'))
        end
        context "when not given permission" do
          let(:user) { FactoryGirl.create(:campus_patron) }
          let(:sign_in_user) { user }
          context "and color PDF is enabled" do
            let(:scanned_resource) { FactoryGirl.create(:complete_scanned_resource, user: user, title: ['Dummy Title'], pdf_type: ['color']) }
            it "works" do
              pdf = double("Actor")
              allow(ScannedResourcePDF).to receive(:new).with(anything, quality: "color").and_return(pdf)
              allow(pdf).to receive(:render).and_return(true)

              get :pdf, params: { id: scanned_resource, pdf_quality: "color" }

              expect(response).to redirect_to(ManifestBuilder::HyraxManifestHelper.new.download_path(scanned_resource, file: 'color-pdf', locale: 'en'))
            end
          end
          it "doesn't work" do
            get :pdf, params: { id: scanned_resource, pdf_quality: "color" }

            expect(response).to redirect_to "/?locale=en"
          end
        end
      end
    end
    context "when requesting gray" do
      let(:sign_in_user) { nil }
      context "when given permission" do
        it 'generates the pdf then redirects to its download url' do
          pdf = double("Actor")
          allow(ScannedResourcePDF).to receive(:new).with(anything, quality: "gray").and_return(pdf)
          allow(pdf).to receive(:render).and_return(true)
          get :pdf, params: { id: scanned_resource, pdf_quality: "gray" }
          expect(response).to redirect_to(ManifestBuilder::HyraxManifestHelper.new.download_path(scanned_resource, file: 'gray-pdf', locale: 'en'))
        end
      end
      context "when the resource has no pdf type set" do
        let(:sign_in_user) { FactoryGirl.create(:user) }
        let(:scanned_resource) { FactoryGirl.create(:complete_scanned_resource, user: user, title: ['Dummy Title'], pdf_type: []) }
        it "redirects to root" do
          get :pdf, params: { id: scanned_resource, pdf_quality: "gray" }

          expect(response).to redirect_to Rails.application.class.routes.url_helpers.root_path(locale: 'en')
        end
      end
      context "when not given permission" do
        let(:scanned_resource) { FactoryGirl.create(:private_scanned_resource, title: ['Dummy Title']) }
        context "and not logged in" do
          it "redirects for auth" do
            get :pdf, params: { id: scanned_resource, pdf_quality: "gray" }

            expect(response).to redirect_to "http://test.host/users/auth/cas?locale=en"
          end
        end
        context "and logged in" do
          let(:sign_in_user) { FactoryGirl.create(:user) }
          it "redirects to root" do
            get :pdf, params: { id: scanned_resource, pdf_quality: "gray" }

            expect(response).to redirect_to Rails.application.class.routes.url_helpers.root_path(locale: 'en')
          end
        end
      end
    end
    context "when requesting bitonal" do
      let(:sign_in_user) { nil }
      context "when given permission" do
        it 'generates the pdf then redirects to its download url' do
          pdf = double("Actor")
          allow(ScannedResourcePDF).to receive(:new).with(anything, quality: "bitonal").and_return(pdf)
          allow(pdf).to receive(:render).and_return(true)
          get :pdf, params: { id: scanned_resource, pdf_quality: "bitonal" }
          expect(response).to redirect_to(ManifestBuilder::HyraxManifestHelper.new.download_path(scanned_resource, file: 'bitonal-pdf', locale: 'en'))
        end
      end
      context "when the resource has no pdf type set" do
        let(:sign_in_user) { FactoryGirl.create(:user) }
        let(:scanned_resource) { FactoryGirl.create(:complete_scanned_resource, user: user, title: ['Dummy Title'], pdf_type: []) }
        it "redirects to root" do
          get :pdf, params: { id: scanned_resource, pdf_quality: "bitonal" }

          expect(response).to redirect_to Rails.application.class.routes.url_helpers.root_path(locale: 'en')
        end
      end
      context "when not given permission" do
        let(:scanned_resource) { FactoryGirl.create(:private_scanned_resource, title: ['Dummy Title']) }
        context "and not logged in" do
          it "redirects for auth" do
            get :pdf, params: { id: scanned_resource, pdf_quality: "bitonal" }

            expect(response).to redirect_to "http://test.host/users/auth/cas?locale=en"
          end
        end
        context "and logged in" do
          let(:sign_in_user) { FactoryGirl.create(:user) }
          it "redirects to root" do
            get :pdf, params: { id: scanned_resource, pdf_quality: "bitonal" }

            expect(response).to redirect_to Rails.application.class.routes.url_helpers.root_path(locale: 'en')
          end
        end
      end
    end
  end

  describe "#browse_everything_files" do
    let(:resource) { FactoryGirl.create(:scanned_resource, user: user) }
    let(:file) { File.open(Rails.root.join("spec", "fixtures", "files", "color.tif")) }
    let(:user) { FactoryGirl.create(:image_editor) }
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
      allow(CharacterizeJob).to receive(:perform_later)
    end
    around { |example| perform_enqueued_jobs(&example) }
    it "appends a new file set" do
      post :browse_everything_files, params: { id: resource.id, selected_files: params["selected_files"] }
      reloaded = resource.reload
      expect(reloaded.file_sets.length).to eq 1
      expect(reloaded.file_sets.first.files.first.original_name).to eq "color.tif"
      path = Rails.application.class.routes.url_helpers.file_manager_hyrax_scanned_resource_path(resource)
      expect(response).to redirect_to path
      expect(reloaded.pending_uploads.length).to eq 0
      expect(reloaded.thumbnail_id).not_to be_blank
      expect(reloaded.representative_id).not_to be_blank
    end
    context "when it's failed in the past" do
      it "continues where it left off" do
        file_set = FactoryGirl.create(:file_set)
        upload_set_id = ActiveFedora::Noid::Service.new.mint
        PendingUpload.create!(curation_concern_id: resource.id, file_name: File.basename(file.path), file_path: file.path, fileset_id: file_set.id, upload_set_id: upload_set_id)
        noid_service = instance_double(ActiveFedora::Noid::Service)
        allow(ActiveFedora::Noid::Service).to receive(:new).and_return(noid_service)
        allow(noid_service).to receive(:mint).and_return(upload_set_id)
        allow(FileSetActor).to receive(:new)
        allow(CompositePendingUpload).to receive(:create)

        post :browse_everything_files, params: { id: resource.id, selected_files: params["selected_files"], parent_id: resource.id }
        reloaded = resource.reload

        expect(reloaded.file_sets.length).to eq 1
        expect(FileSetActor).not_to have_received(:new)
      end
    end
    context "when there's a parent id" do
      it "redirects to the parent path" do
        allow(BrowseEverythingIngestJob).to receive(:perform_later).and_return(true)
        post :browse_everything_files, params: { id: resource.id, selected_files: params["selected_files"], parent_id: resource.id }
        path = Rails.application.class.routes.url_helpers.file_manager_hyrax_parent_scanned_resource_path(id: resource.id, parent_id: resource.id)
        expect(response).to redirect_to path
      end
    end
    context "when the job hasn't run yet" do
      it "creates pending uploads" do
        allow(BrowseEverythingIngestJob).to receive(:perform_later).and_return(true)
        post :browse_everything_files, params: { id: resource.id, selected_files: params["selected_files"] }
        expect(resource.pending_uploads.length).to eq 1
        pending_upload = resource.pending_uploads.first
        expect(pending_upload.file_name).to eq File.basename(file.path)
        expect(pending_upload.file_path).to eq file.path
        expect(pending_upload.upload_set_id).not_to be_blank
      end
    end
  end

  describe "#form_class" do
    subject { described_class.new.form_class }
    it { is_expected.to eq Hyrax::ScannedResourceForm }
  end

  describe "#file_manager" do
    context "when not signed in" do
      it "does not allow them to view it" do
        get :file_manager, params: { id: scanned_resource.id }
        expect(response).not_to be_success
      end
    end
    context "when logged in as an admin" do
      let(:user) { FactoryGirl.create(:admin) }
      it "lets them see it" do
        sign_in user
        get :file_manager, params: { id: scanned_resource.id }
        expect(response).to be_success
      end
    end
  end

  describe "saving structure" do
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
    it "works even if logical order was deleted badly" do
      resource.logical_order.order = { label: "Bad news.", nodes: nodes }
      resource.save!
      resource.logical_order.destroy

      post :save_structure, params: { nodes: nodes, id: resource.id, label: "TOP!" }

      expect(response.status).to eq 200
      expect(resource.reload.logical_order.order).to eq({ "label": "TOP!", "nodes": nodes }.with_indifferent_access)
    end
  end

  describe "#bulk_download" do
    let(:user) { FactoryGirl.create(:admin) }
    let(:file) { File.open(Rails.root.join("spec", "fixtures", "files", "color.tif")) }
    let(:scanned_resource) { FactoryGirl.create(:scanned_resource, user: user, ordered_members: [file_set]) }
    let(:file_set) { FactoryGirl.create(:file_set, user: user, content: file) }
    before do
      sign_in user
      allow(ActiveFedora::Base).to receive(:find).and_call_original
      allow(ActiveFedora::Base).to receive(:find).with(file_set.id).and_return(file_set)
      allow(file_set).to receive(:local_file).and_return(file.path)
    end
    context "when given a list of file sets" do
      it "generates a zip file" do
        post :bulk_download, params: { id: scanned_resource.id, file_sets: [file_set.id] }

        expect(response).to be_success
        expect(response.headers["Content-Type"]).to eq "application/zip"
      end
    end
  end

  include_examples "structure persister", :scanned_resource, ScannedResourceShowPresenter
end
