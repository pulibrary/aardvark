class ScannedResourcePDF
  class Canvas
    # Letter width/height in points for a PDF.
    LETTER_WIDTH = PDF::Core::PageGeometry::SIZES["LETTER"].first
    LETTER_HEIGHT = PDF::Core::PageGeometry::SIZES["LETTER"].last
    BITONAL_SIZE = 2000
    attr_reader :canvas
    def initialize(canvas)
      @canvas = canvas
    end

    def width
      canvas.resource.width
    end

    def height
      canvas.resource.height
    end

    def url
      canvas.resource.service['@id']
    end
  end
end
