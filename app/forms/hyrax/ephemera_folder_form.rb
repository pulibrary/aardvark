# Generated via
#  `rails generate hyrax:work EphemeraFolder`
module Hyrax
  class EphemeraFolderForm < SingleValuedForm
    self.model_class = ::EphemeraFolder
    self.terms = [:language, :title, :sort_title, :alternative_title, :series, :creator, :contributor, :publisher, :geographic_origin, :genre, :subject, :geo_subject, :description, :date_created, :barcode, :folder_number, :genre, :width, :height, :page_count, :box_id, :member_of_collection_ids]
    self.required_fields = [:title, :barcode, :folder_number, :width, :height, :page_count, :box_id, :language, :genre]
    self.single_valued_fields = [:title, :sort_title, :creator, :geographic_origin, :date_created, :genre, :description, :barcode, :folder_number, :genre, :width, :height, :page_count]
    delegate :box_id, to: :model
  end
end
