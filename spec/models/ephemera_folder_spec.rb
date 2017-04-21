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
        subject.barcode = ['123']
      end

      it "is not valid" do
        expect(subject.barcode_valid?).not_to be true
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
