require 'rails_helper'

RSpec.describe Discovery::GeoblacklightDocument do
  let(:document_builder) { GeoWorks::Discovery::DocumentBuilder.new(geo_concern_presenter, described_class.new) }
  let(:geo_concern_presenter) { ImageWorkShowPresenter.new(SolrDocument.new(geo_concern.to_solr), nil) }
  let(:geo_concern) { FactoryGirl.build(:image_work, attributes) }
  let(:geo_file_set) { FactoryGirl.create(:file_set, geo_mime_type: geo_mime_type, visibility: visibility) }
  let(:geo_mime_type) { 'image/tiff' }
  let(:coverage) { GeoWorks::Coverage.new(43.039, -69.856, 42.943, -71.032).to_s }
  let(:attributes) do
    {
      id: 'geo-work-1',
      visibility: visibility,
      title: ['Geo Work'],
      coverage: coverage,
      identifier: ['ark:/99999/fk4']
    }
  end

  before do
    geo_concern.ordered_members << geo_file_set
    geo_concern.representative_id = geo_file_set.id
    geo_concern.save
  end

  describe '#to_json' do
    let(:document) { JSON.parse(document_builder.to_json) }

    context 'with a private image work' do
      let(:visibility) { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE }

      it 'returns a document with reduced references and restricted access' do
        refs = JSON.parse(document['dct_references_s'])
        expect(refs).to have_key 'http://schema.org/url'
        expect(refs).to have_key 'http://schema.org/thumbnailUrl'
        expect(refs).not_to have_key 'http://schema.org/downloadUrl'
        expect(refs).not_to have_key 'http://iiif.io/api/image'
        expect(document['dc_rights_s']).to eq 'Restricted'
      end

      context 'with missing required metadata fields' do
        let(:attributes) { { visibility: visibility } }

        it 'returns an error document' do
          expect(document['error'][0]).to include('solr_geom')
        end
      end
    end

    context 'with a public image work' do
      let(:visibility) { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC }

      it 'returns a document with full references and public access' do
        refs = JSON.parse(document['dct_references_s'])
        expect(refs).to have_key 'http://schema.org/downloadUrl'
        expect(refs).to have_key 'http://iiif.io/api/image'
        expect(document['dc_rights_s']).to eq 'Public'
      end
    end
  end

  describe '#to_hash' do
    let(:document) { document_builder.to_hash }

    context 'with a private image work' do
      let(:visibility) { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE }

      it 'returns a document with reduced references and restricted access' do
        refs = JSON.parse(document[:dct_references_s])
        expect(refs).to have_key 'http://schema.org/url'
        expect(refs).to have_key 'http://schema.org/thumbnailUrl'
        expect(refs).not_to have_key 'http://schema.org/downloadUrl'
        expect(refs).not_to have_key 'http://iiif.io/api/image'
        expect(refs).not_to have_key 'http://iiif.io/api/presentation#manifest'
        expect(document[:dc_rights_s]).to eq 'Restricted'
      end
    end

    context 'with a public image work' do
      let(:visibility) { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC }

      it 'returns a document with full references and public access' do
        refs = JSON.parse(document[:dct_references_s])
        expect(refs).to have_key 'http://schema.org/downloadUrl'
        expect(refs).to have_key 'http://iiif.io/api/image'
        expect(refs).to have_key 'http://iiif.io/api/presentation#manifest'
        expect(document[:dc_rights_s]).to eq 'Public'
        expect(document[:layer_geom_type_s]).to eq 'Image'
      end
    end

    context 'with a public image work with a mapset parent' do
      let(:identifier) { ['ark:/99999/fk44jq866'] }
      let(:map_set) { FactoryGirl.build(:map_set, identifier: identifier, coverage: coverage) }
      let(:visibility) { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC }

      before do
        map_set.ordered_members << geo_concern
        map_set.thumbnail_id = geo_concern.id
        map_set.save
        geo_concern.update_index
      end

      it 'returns a suppressed document with a source field' do
        expect(document[:suppressed_b]).to eq true
        expect(document[:dct_source_sm]).to eq ['princeton-fk44jq866']
      end

      context 'with the parent map set' do
        let(:geo_concern_presenter) { MapSetShowPresenter.new(SolrDocument.new(map_set.to_solr), nil) }
        let(:document) { document_builder.to_hash }

        it 'returns iiif references and does not return a suppressed document or a source field' do
          refs = JSON.parse(document[:dct_references_s])
          expect(document[:suppressed_b]).to be_nil
          expect(document[:dct_source_sm]).to be_nil
          expect(document[:layer_geom_type_s]).to eq 'Image'
          expect(refs).to have_key 'http://iiif.io/api/presentation#manifest'
          expect(refs).to have_key 'http://iiif.io/api/image'
        end
      end
    end
  end

  describe 'references' do
    let(:document) { document_builder.to_hash }
    let(:visibility) { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC }

    context 'with a public ImageWork' do
      it 'only has iiif references' do
        refs = JSON.parse(document[:dct_references_s])
        expect(refs).to have_key 'http://iiif.io/api/image'
        expect(refs).to have_key 'http://iiif.io/api/presentation#manifest'
        expect(refs).not_to have_key 'http://www.opengis.net/def/serviceType/ogc/wms'
        expect(refs).not_to have_key 'http://www.opengis.net/def/serviceType/ogc/wfs'
      end
    end

    context 'with a public VectorWork' do
      let(:geo_concern_presenter) { VectorWorkShowPresenter.new(SolrDocument.new(geo_concern.to_solr), nil) }
      let(:geo_mime_type) { 'application/vnd.geo+json' }

      it 'only has wms and wfs references' do
        refs = JSON.parse(document[:dct_references_s])
        expect(refs).not_to have_key 'http://iiif.io/api/image'
        expect(refs).to have_key 'http://www.opengis.net/def/serviceType/ogc/wms'
        expect(refs).to have_key 'http://www.opengis.net/def/serviceType/ogc/wfs'
      end
    end
  end
end
