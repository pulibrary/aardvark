# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Hyrax::ImageWorkForm do
  let(:work) { ImageWork.new }
  let(:form) { described_class.new(work, nil, nil) }

  describe "#secondary_terms" do
    subject { form.secondary_terms }
    it do
      is_expected.to include(:cartographic_scale, :edition, :alternative, :contents)
    end
  end
end
