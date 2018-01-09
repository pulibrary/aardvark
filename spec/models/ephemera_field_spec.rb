# frozen_string_literal: true
require 'rails_helper'

RSpec.describe EphemeraField, type: :model do
  subject { described_class.new name: "EphemeraFolder.subject", ephemera_project: project, vocabulary: vocab }
  let(:project) { FactoryGirl.build :ephemera_project }
  let(:vocab) { FactoryGirl.build :vocabulary }

  it "has a name" do
    expect(subject.name).to eq("EphemeraFolder.subject")
  end

  it "has a project" do
    expect(subject.ephemera_project).to eq(project)
  end

  it "has a vocabulary" do
    expect(subject.vocabulary).to eq(vocab)
  end
end
