require 'rails_helper'

RSpec.describe "hyrax/base/structure" do
  let(:logical_order) do
    WithProxyForObject::Factory.new(members).new(params)
  end
  let(:params) do
    {
      nodes: [
        {
          label: "Chapter 1",
          nodes: [
            {
              proxy: "a"
            }
          ]
        }
      ]
    }
  end
  let(:members) do
    [
      build_file_set(id: "a", to_s: "banana"),
      build_file_set(id: "b", to_s: "banana")
    ]
  end

  def build_file_set(id:, to_s:)
    i = instance_double(FileSetPresenter, id: id, thumbnail_id: id, to_s: to_s, collection?: false)
    allow(i).to receive(:solr_document).and_return(SolrDocument.new(FileSet.new(id: "test").to_solr))
    allow(IIIFPath).to receive(:new).with(id).and_return(double(thumbnail: nil))
    i
  end
  let(:scanned_resource) { ScannedResourceShowPresenter.new(SolrDocument.new(ScannedResource.new(id: "test").to_solr), nil) }
  before do
    stub_blacklight_views
    assign(:logical_order, logical_order)
    assign(:presenter, scanned_resource)
    render
  end
  it "renders a li per node" do
    expect(rendered).to have_selector("li", count: 5)
  end
  it "renders a ul per order" do
    expect(rendered).to have_selector("ul", count: 3)
  end
  it "renders labels of chapters" do
    expect(rendered).to have_selector("input[value='Chapter 1']")
  end
  it "renders proxy nodes" do
    expect(rendered).to have_selector("li[data-proxy='a']")
  end
  it "renders unstructured nodes" do
    expect(rendered).to have_selector("li[data-proxy='b']")
  end
  context "when given a multi volume work" do
    let(:scanned_resource) { MultiVolumeWorkShowPresenter.new(SolrDocument.new(MultiVolumeWork.new(id: "test").to_solr), nil) }
    it "renders" do
      expect(rendered).to have_selector("li", count: 5)
      expect(rendered).to have_selector("*[data-class-name='multi_volume_works']")
    end
  end
end
