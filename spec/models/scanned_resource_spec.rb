# Generated via
#  `rails generate worthwhile:work ScannedResource`
require 'rails_helper'

describe ScannedResource do
  let(:scanned_resource) { FactoryGirl.build(:scanned_resource, source_metadata_identifier: '12345', rights_statement: 'http://rightsstatements.org/vocab/NKC/1.0/') }
  let(:reloaded)         { described_class.find(scanned_resource.id) }
  subject { scanned_resource }

  describe 'has note fields' do
    [:portion_note, :description].each do |note_type|
      it "should let me set a #{note_type}" do
        note = 'This is note text'
        subject.send("#{note_type}=", note)
        expect { subject.save }.to_not raise_error
        expect(reloaded.send(note_type)).to eq note
      end
    end
  end

  describe 'has source metadata id' do
    it 'allows setting of metadata id' do
      id = '12345'
      subject.source_metadata_identifier = id
      expect { subject.save }.to_not raise_error
      expect(reloaded.source_metadata_identifier).to eq id
    end
  end

  context "validating title and metadata id" do
    before do
      subject.source_metadata_identifier = nil
      subject.title = nil
    end
    context "when neither metadata id nor title is set" do
      it 'fails' do
        expect(subject.valid?).to eq false
      end
    end
    context "when only metadata id is set" do
      before do
        subject.source_metadata_identifier = "12355"
      end
      it 'passes' do
        expect(subject.valid?).to eq true
      end
    end
    context "when only title id is set" do
      before do
        subject.title = ["A Title.."]
      end
      it 'passes' do
        expect(subject.valid?).to eq true
      end
    end
  end

  describe '#rights_statement' do
    it "sets rights_statement" do
      nkc = 'http://rightsstatements.org/vocab/NKC/1.0/'
      subject.rights_statement = nkc
      expect { subject.save }.to_not raise_error
      expect(reloaded.rights_statement).to eq nkc
    end

    it "requires rights_statement" do
      subject.rights_statement = nil
      expect(subject.valid?).to be_falsey
    end
  end

  describe 'apply_remote_metadata' do
    context 'when source_metadata_identifier is not set' do
      before { subject.source_metadata_identifier = nil }
      it 'does nothing' do
        original_attributes = subject.attributes
        expect(subject.send(:remote_metadata_factory)).to_not receive(:new)
        subject.apply_remote_metadata
        expect(subject.attributes).to eq(original_attributes)
      end
    end
    context 'With a Pulfa ID', vcr: { cassette_name: 'pulfa' } do
      before do
        subject.source_metadata_identifier = 'AC123_c00004'
      end

      # Pending until
      # https://github.com/pulibrary/pul_metadata_services/issues/5 is closed
      xit 'Extracts Pulfa Metadata and full source' do
        subject.apply_remote_metadata
        expect(subject.title.first).to eq('Series 1: University Librarian Records - Subseries 1A, Frederic Vinton - Correspondence')
        expect(subject.creator.first).to eq('Princeton University. Library. Dept. of Rare Books and Special Collections')
        expect(subject.publisher.first).to eq('Princeton University. Library. Dept. of Rare Books and Special Collections')
        expect(subject.date_created.first).to eq('1734-2012')
        expect(subject.source_metadata).to eq(fixture('pulfa-AC123_c00004.xml').read)
      end

      it 'Saves a record with extacted ead metadata' do
        subject.apply_remote_metadata
        subject.save
        expect { subject.save }.to_not raise_error
        expect(subject.id).to be_truthy
      end
    end

    context 'With a Voyager ID', vcr: { cassette_name: "bibdata", record: :new_episodes }do
      before do
        subject.source_metadata_identifier = '2028405'
      end

      it 'Extracts Voyager Metadata' do
        subject.apply_remote_metadata
        expect(subject.title).to eq(['The Giant Bible of Mainz; 500th anniversary, April fourth, fourteen fifty-two, April fourth, nineteen fifty-two.'])
        expect(subject.resource.get_values(:title, literal: true)).to eq([RDF::Literal.new("The Giant Bible of Mainz; 500th anniversary, April fourth, fourteen fifty-two, April fourth, nineteen fifty-two.", language: :eng)])
        expect(subject.creator).to eq(['Miner, Dorothy Eugenia'])
        expect(subject.date_created).to eq(['1952-01-01T00:00:00Z'])
        expect(subject.publisher).to eq(['[Philadelphia, 1952]'])
      end

      it 'Saves a record with extacted Voyager metadata' do
        subject.apply_remote_metadata
        subject.save
        expect { subject.save }.to_not raise_error
        expect(subject.id).to be_truthy
      end
    end
  end

  describe 'gets a noid' do
    it 'that conforms to a valid pattern' do
      expect { subject.save }.to_not raise_error
      noid_service = ActiveFedora::Noid::Service.new
      expect(noid_service.valid? subject.id).to be_truthy
    end
    it "generates an ID which starts with the environment's first letter" do
      expect { subject.save }.to_not raise_error
      expect(subject.id.first).to eq "t"
    end
  end

  describe "#viewing_direction" do
    it "maps to the IIIF predicate" do
      expect(described_class.properties["viewing_direction"].predicate).to eq RDF::Vocab::IIIF.viewingDirection
    end
  end

  describe "#viewing_hint" do
    it "maps to the IIIF predicate" do
      expect(described_class.properties["viewing_hint"].predicate).to eq RDF::Vocab::IIIF.viewingHint
    end
  end

  describe "validations" do
    it "validates with the viewing direction validator" do
      expect(subject._validators[nil].map(&:class)).to include ViewingDirectionValidator
    end
    it "validates with the viewing hint validator" do
      expect(subject._validators[nil].map(&:class)).to include ViewingHintValidator
    end
  end

  describe "#pending_uploads" do
    it "returns all pending uploads" do
      subject.save
      pending_upload = FactoryGirl.create(:pending_upload, curation_concern_id: subject.id)

      expect(subject.pending_uploads).to eq [pending_upload]
    end
    it "doesn't return anything for other resources' pending uploads" do
      subject.save
      FactoryGirl.create(:pending_upload, curation_concern_id: "banana")

      expect(subject.pending_uploads).to eq []
    end
    context "when not persisted" do
      it "returns a blank array" do
        expect(described_class.new.pending_uploads).to eq []
      end
    end
  end

  include_examples "structural metadata"

  describe "collection indexing" do
    let(:scanned_resource) { FactoryGirl.create(:scanned_resource_in_collection) }
    let(:solr_doc) { scanned_resource.to_solr }
    it "indexes collection" do
      expect(solr_doc['member_of_collections_ssim']).to eq(['Test Collection'])
      expect(solr_doc['member_of_collection_slugs_ssim']).to eq(scanned_resource.member_of_collections.first.exhibit_id)
    end
  end

  describe "#pdf_type" do
    it "is empty by default" do
      expect(described_class.new.pdf_type).to eq []
    end
    it "can be set" do
      subject.pdf_type = ["color"]

      expect(subject.pdf_type).to eq ["color"]
    end
  end

  describe "literal indexing" do
    let(:scanned_resource) { FactoryGirl.create(:scanned_resource_in_collection, title: [::RDF::Literal.new("Test", language: :fr)]) }
    let(:solr_doc) { scanned_resource.to_solr }
    it "indexes literals with tags in a new field" do
      expect(solr_doc['title_tesim']).to eq ['Test']
      expect(solr_doc['title_literals_ssim']).to eq [JSON.dump("@value" => "Test", "@language" => "fr")]
    end
  end

  describe "sort title indexing" do
    let(:scanned_resource) do
      FactoryGirl.create(:scanned_resource_in_collection,
                         title: [::RDF::Literal.new("Test", language: :fr), ::RDF::Literal.new("Me", language: :en)]
                        )
    end
    let(:solr_doc) { scanned_resource.to_solr }
    it "combines multiple titles into string" do
      expect(solr_doc['title_ssort']).to eq solr_doc['title_tesim'].to_sentence
    end
  end
end
