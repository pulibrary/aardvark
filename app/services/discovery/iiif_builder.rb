module Discovery
  class IIIFBuilder
    attr_reader :geo_work

    def initialize(geo_work)
      @geo_work = geo_work
    end

    def build(document)
      document.iiif = iiif
      document.iiif_manifest = iiif_manifest
    end

    # Get IIIF path for file set
    def iiif
      return unless map_set? || geo_file_set?
      find_thumbnail_file if map_set?
      return unless file_set
      "#{path}/info.json"
    end

    def iiif_manifest
      return unless map_set? || geo_file_set?
      "#{manifest_path}/manifest"
    end

    private

      def path
        IIIFPath.new(file_set.id).to_s
      end

      def manifest_path
        Discovery::DocumentPath.new(geo_work).to_s
      end

      # Gets the representative file set.
      # @return [FileSet] representative file set
      def file_set
        @file_set ||= begin
          representative_id = geo_work.solr_document.representative_id
          file_set_id = [representative_id]
          geo_work.member_presenters(file_set_id).first
        end
      end

      # Finds the file set for a map set thumbnail
      def find_thumbnail_file
        map_set = MapSet.find(geo_work.id)
        image_work = map_set.thumbnail
        return unless image_work
        image_work_presenter = ImageWorkShowPresenter.new(SolrDocument.new(image_work.to_solr), nil)
        file_set_id = image_work_presenter.solr_document.representative_id
        @file_set = image_work_presenter.geo_file_set_presenters.find { |presenter| presenter.id == file_set_id }
      end

      # Tests if geo work is a map set
      # @return [Bool]
      def map_set?
        geo_work.model_name.to_s == 'MapSet'
      end

      # Tests if the file set is a geo file set.
      # @return [Bool]
      def geo_file_set?
        return false unless file_set
        geo_mime_type = file_set.solr_document.fetch(:geo_mime_type_ssim, []).first
        return false unless GeoWorks::ImageFormatService.include?(geo_mime_type)
        @file_set_ids ||= geo_work.geo_file_set_presenters.map(&:id)
        @file_set_ids.include? file_set.id
      end

      # Returns the file set visibility if it's open and authenticated.
      # @return [String] file set visibility
      def visibility
        return unless file_set
        visibility = file_set.solr_document.visibility
        visibility if valid_visibilities.include? visibility
      end

      def valid_visibilities
        [Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC,
         Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED]
      end
  end
end
