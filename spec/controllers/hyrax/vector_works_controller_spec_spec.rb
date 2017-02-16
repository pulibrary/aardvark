require 'rails_helper'

describe Hyrax::VectorWorksController do
  let(:user) { FactoryGirl.create(:user) }
  let(:vector_work) { FactoryGirl.create(:complete_vector_work, user: user) }
  let(:manifest_generator) { instance_double(GeoConcerns::EventsGenerator) }

  before do
    allow(GeoConcerns::EventsGenerator).to receive(:new).and_return(manifest_generator)
  end

  describe '#show_presenter' do
    subject { described_class.new.show_presenter }
    xit { is_expected.to eq(VectorWorkShowPresenter) }
  end

  describe '#delete' do
    before do
      sign_in user
    end

    xit 'fires a delete event' do
      expect(manifest_generator).to receive(:record_deleted)
      delete :destroy, params: { id: vector_work }
    end
  end

  describe '#update' do
    let(:vector_work_attributes) do
      FactoryGirl.attributes_for(:vector_work).merge(
        title: ['New Title']
      )
    end

    before do
      sign_in user
    end

    context 'with a complete state' do
      xit 'fires an update event' do
        expect(manifest_generator).to receive(:record_updated)
        post :update, params: { id: vector_work, vector_work: vector_work_attributes }
      end
    end

    context 'with a non-complete state' do
      let(:vector_work) { FactoryGirl.create(:pending_vector_work, user: user) }
      xit 'does not fire an update event' do
        expect(manifest_generator).to_not receive(:record_updated)
        post :update, params: { id: vector_work, vector_work: vector_work_attributes }
      end
    end
  end
end
