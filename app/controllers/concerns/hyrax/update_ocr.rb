module Hyrax
  module UpdateOCR
    extend ActiveSupport::Concern
    def decorator
      ::UpdatesOCR
    end
  end
end
