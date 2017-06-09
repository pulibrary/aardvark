require 'rails_helper'

RSpec.describe UpdateGeoBlacklightJob do
  describe "#perform" do
    let(:image_work) { FactoryGirl.create(:image_work) }
    let(:events_generator) { instance_double(GeoWorks::EventsGenerator) }

    subject { described_class.perform_now(image_work.id, 'ImageWork') }

    before do
      allow(GeoWorks::EventsGenerator).to receive(:new).and_return(events_generator)
    end

    it 'triggers an update record event' do
      expect(events_generator).to receive(:record_updated)
      subject
    end
  end
end
