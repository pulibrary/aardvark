class CurationConcerns::ImageWorksController < ApplicationController
  include CurationConcerns::CurationConcernController
  include GeoConcerns::ImageWorksControllerBehavior
  include GeoConcerns::GeoblacklightControllerBehavior
  include CurationConcerns::GeoMessengerBehavior
  include CurationConcerns::Flagging
  self.curation_concern_type = ImageWork

  def show_presenter
    ImageWorkShowPresenter
  end
end
