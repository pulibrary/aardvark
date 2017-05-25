require 'rails_helper'

RSpec.describe Hyrax::MapSetsController do
  let(:user) { FactoryGirl.create(:user) }
  let(:coverage) { GeoWorks::Coverage.new(43.039, -69.856, 42.943, -71.032).to_s }
  let(:map_set) { FactoryGirl.create(:map_set, user: user, title: ['Dummy Title'], coverage: coverage) }
  let(:reloaded) { map_set.reload }

  describe 'create' do
    let(:user) { FactoryGirl.create(:admin) }
    before do
      sign_in user
    end
    context 'when given a bib id', vcr: { cassette_name: 'bibdata-maps', allow_playback_repeats: true } do
      let(:map_set_attributes) do
        FactoryGirl.attributes_for(:map_set).merge(
          source_metadata_identifier: '9284317',
          rights_statement: 'http://rightsstatements.org/vocab/NKC/1.0/'
        )
      end
      it 'updates the metadata' do
        post :create, params: { map_set: map_set_attributes }
        s = MapSet.last
        expect(s.title.first.to_s).to eq 'Netherlands, Nieuwe Waterweg and Europoort : Hoek Van Holland to Vlaardingen'
        expect(s.coverage).to eq 'northlimit=52.024167; eastlimit=004.341667; southlimit=51.920000; westlimit=003.966667; units=degrees; projection=EPSG:4326'
      end
    end
  end

  describe 'update' do
    let(:map_set) { FactoryGirl.create(:map_set, user: user, title: ['Dummy Title']) }

    before do
      sign_in user
    end

    it 'can update the coverage' do
      post :update, params: { id: map_set, map_set: { coverage: coverage } }
      expect(reloaded.coverage).to eq coverage
    end
  end

  describe '#file_manager' do
    context "when not signed in" do
      it "does not allow them to view it" do
        get :file_manager, params: { id: map_set.id }
        expect(response).not_to be_success
      end
    end
    context 'when logged in as an admin' do
      let(:user) { FactoryGirl.create(:admin) }
      it "lets them see it" do
        sign_in user
        get :file_manager, params: { id: map_set.id }
        expect(response).to be_success
      end
    end
  end

  describe 'generated documents' do
    let(:user) { FactoryGirl.create(:admin) }
    let(:image_work) { FactoryGirl.create(:image_work) }
    let(:file_set) { FactoryGirl.create(:file_set, id: 'x633f104m', geo_mime_type: 'image/tiff') }

    render_views
    before do
      sign_in user
      image_work.ordered_members << file_set
      image_work.thumbnail_id = file_set.id
      image_work.save
      file_set.update_index
      map_set.ordered_members << image_work
      map_set.thumbnail_id = image_work.id
      map_set.save
      image_work.update_index
    end

    describe "#manifest" do
      context 'when requesting JSON', vcr: { cassette_name: 'iiif_manifest' } do
        it 'builds a sammelband manifest' do
          get :manifest, params: { id: map_set.id, format: :json }
          expect(response).to be_success
          response_json = JSON.parse(response.body)
          expect(response_json['viewingHint']).to eq 'individuals'
          expect(response_json['manifests']).to be_nil
        end
      end
    end

    describe "#geoblacklight" do
      context 'when requesting JSON' do
        it 'builds a geoblacklight manifest' do
          get :geoblacklight, params: { id: map_set.id, format: :json }
          expect(response).to be_success
          response_json = JSON.parse(response.body)
          references = JSON.parse(response_json['dct_references_s'])
          expect(response_json['dc_format_s']).to eq 'TIFF'
          expect(response_json['layer_geom_type_s']).to eq 'Scanned Map'
          expect(references).to include('http://iiif.io/api/presentation#manifest')
          expect(references).to include('http://schema.org/thumbnailUrl')
        end
      end
    end
  end
end
