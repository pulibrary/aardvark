# Generated via
#  `rails generate hyrax:work MultiVolumeWork`
require 'rails_helper'

describe Hyrax::Actors::MultiVolumeWorkActor do
  it 'is a BaseActor' do
    expect(described_class < ::Hyrax::Actors::BaseActor).to be true
  end
end
