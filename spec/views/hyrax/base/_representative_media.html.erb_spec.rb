require 'rails_helper'

RSpec.describe "hyrax/base/_representative_media.html.erb" do
  let(:presenter) { instance_double(ScannedResourceShowPresenter, member_presenters: member_presenters, id: "1", persisted?: true, model_name: ScannedResource.model_name) }
  let(:member_presenters) { [] }
  before do
    allow(presenter).to receive(:to_model).and_return(presenter)
    render partial: "hyrax/base/representative_media", locals: { presenter: presenter }
  end
  context "when there are no generic files" do
    it "shows a filler" do
      expect(response).to have_selector "img[src='/assets/nope.png']"
    end
  end
  context "when there are generic files" do
    let(:member_presenters) { [1] }
    it "renders the viewer" do
      expect(response).to have_selector ".viewer[data-uri]"
    end
  end
end
