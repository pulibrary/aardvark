class ImageWork < ActiveFedora::Base
  include ::CurationConcerns::WorkBehavior
  include ::GeoConcerns::ImageWorkBehavior
  include ::CurationConcerns::BasicMetadata
  include ::GeoConcerns::BasicGeoMetadata
  include ::GeoMetadata
  include ::StateBehavior
  self.valid_child_concerns = [RasterWork]

  # Use local indexer
  self.indexer = GeoWorkIndexer
end
