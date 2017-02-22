require 'rails_helper'

RSpec.describe Hyrax::ImageWorkForm do
  let(:work) { ImageWork.new }
  let(:form) { described_class.new(work, nil, nil) }

  describe "#secondary_terms" do
    subject { form.secondary_terms }
    it do
      is_expected.not_to include(:cartographic_projection)
    end
  end
end
