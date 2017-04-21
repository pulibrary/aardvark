require 'rails_helper'

RSpec.describe GeoWorks::TriggerUpdateEvents do
  let(:geo_work) { FactoryGirl.create(:complete_image_work) }
  let(:messaging_client) { instance_double(GeoblacklightMessagingClient) }

  before do
    allow(GeoblacklightMessagingClient).to receive(:new).and_return(messaging_client)
  end

  describe '#call' do
    it 'triggers update events for the work' do
      expect(messaging_client).to receive(:publish).with(/UPDATED/)
      described_class.call(geo_work)
    end
  end
end
