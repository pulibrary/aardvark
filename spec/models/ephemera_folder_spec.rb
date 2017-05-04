# Generated via
#  `rails generate hyrax:work EphemeraFolder`
require 'rails_helper'

RSpec.describe EphemeraFolder do
  subject(:folder) { FactoryGirl.build(:ephemera_folder) }
  it "has a valid factory" do
    expect(folder).to be_valid
  end

  describe "id" do
    before do
      subject.id = '3'
    end

    it "has an id" do
      expect(subject.id).to eq('3')
    end
  end

  describe "barcode_valid?" do
    context "with a valid barcode" do
      it "is valid" do
        expect(subject.barcode_valid?).to be true
      end
    end

    context "with an invalid barcode" do
      before do
        subject.identifier = ['123']
      end

      it "is not valid" do
        expect(subject.barcode_valid?).not_to be true
      end
    end
  end

  describe "language indexing" do
    context "when given a set of language IDs" do
      after do
        Qa::Authorities::Local.registry.instance_variable_get(:@hash).delete("languages")
      end
      before do
        Qa::Authorities::Local.registry.instance_variable_get(:@hash).delete("languages")
        vocabulary
      end
      let(:vocabulary) do
        Vocabulary.create!(label: "languages").tap do |vocab|
          VocabularyTerm.create!(vocabulary: vocab, label: "English")
          VocabularyTerm.create!(vocabulary: vocab, label: "Japanese")
        end
      end
      let(:folder) { FactoryGirl.build(:ephemera_folder, language: [VocabularyTerm.first.id.to_s]) }
      it "Returns the label for the IDs" do
        expect(folder.to_solr["language_sim"]).to eq ["English"]
      end
    end
  end

  describe "Geographic Origin Indexing" do
    context "when given a set of origin IDs" do
      after do
        Qa::Authorities::Local.registry.instance_variable_get(:@hash).delete("Geographic Origin")
      end
      before do
        Qa::Authorities::Local.registry.instance_variable_get(:@hash).delete("Geographic Origin")
        vocabulary
      end
      let(:vocabulary) do
        Vocabulary.create!(label: "Geographic Origin").tap do |vocab|
          VocabularyTerm.create!(vocabulary: vocab, label: "English")
          VocabularyTerm.create!(vocabulary: vocab, label: "Japanese")
        end
      end
      let(:folder) { FactoryGirl.build(:ephemera_folder, geographic_origin: [VocabularyTerm.first.id.to_s]) }
      it "Returns the label for the IDs" do
        expect(folder.to_solr["geographic_origin_sim"]).to eq ["English"]
      end
    end
  end

  describe "Genre Indexing" do
    context "when given a set of genre IDs" do
      after do
        Qa::Authorities::Local.registry.instance_variable_get(:@hash).delete("Genre")
      end
      before do
        Qa::Authorities::Local.registry.instance_variable_get(:@hash).delete("Genre")
        vocabulary
      end
      let(:vocabulary) do
        Vocabulary.create!(label: "Genre").tap do |vocab|
          VocabularyTerm.create!(vocabulary: vocab, label: "English")
          VocabularyTerm.create!(vocabulary: vocab, label: "Japanese")
        end
      end
      let(:folder) { FactoryGirl.build(:ephemera_folder, genre: [VocabularyTerm.first.id.to_s]) }
      it "Returns the label for the IDs" do
        expect(folder.to_solr["genre_sim"]).to eq ["English"]
      end
    end
  end

  describe "Geo Subject Indexing" do
    context "when given a set of geo subject IDs" do
      after do
        Qa::Authorities::Local.registry.instance_variable_get(:@hash).delete("Geoographic Origin")
      end
      before do
        Qa::Authorities::Local.registry.instance_variable_get(:@hash).delete("Geographic Origin")
        vocabulary
      end
      let(:vocabulary) do
        Vocabulary.create!(label: "Geographic Origin").tap do |vocab|
          VocabularyTerm.create!(vocabulary: vocab, label: "English")
          VocabularyTerm.create!(vocabulary: vocab, label: "Japanese")
        end
      end
      let(:folder) { FactoryGirl.build(:ephemera_folder, geo_subject: [VocabularyTerm.first.id.to_s]) }
      it "Returns the label for the IDs" do
        expect(folder.to_solr["geo_subject_sim"]).to eq ["English"]
      end
    end
  end

  describe "box and box_id" do
    let(:box) { FactoryGirl.create :ephemera_box }
    let(:col) { FactoryGirl.build :collection }

    before do
      subject.member_of_collections = [box, col]
    end

    it "includes the box, but not the collection" do
      expect(subject.box).to eq(box)
      expect(subject.box_id).to eq(box.id)
    end
  end

  describe "indexing" do
    it "indexes folder_number" do
      expect(subject.to_solr["folder_number_ssim"]).to eq folder.folder_number.map(&:to_s)
    end
  end
end
