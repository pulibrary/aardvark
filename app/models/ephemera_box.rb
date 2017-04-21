# Generated via
#  `rails generate hyrax:work EphemeraBox`
class EphemeraBox < ActiveFedora::Base
  include ::Hyrax::WorkBehavior
  include ::Hyrax::BasicMetadata
  include ::StateBehavior
  # Change this to restrict which works can be added as a child.
  self.valid_child_concerns = [EphemeraFolder]
  validates :title, presence: { message: 'Your work must have a title.' }
  validates :box_number, :barcode, presence: true
  validates :barcode, with: :barcode_valid?
  property :barcode, predicate: ::RDF::URI("http://plum.com/predicates/barCode")
  property :box_number, predicate: ::RDF::URI("http://plum.com/predicates/box_number")

  self.human_readable_type = 'Ephemera Box'
  def box_number=(title)
    super.tap do |box_number|
      self.title = ["Box Number #{box_number.first}"]
    end
  end

  def barcode_valid?
    return true if Barcode.new(barcode.first).valid?
    errors.add(:barcode, "has an invalid checkdigit")
  end
end
