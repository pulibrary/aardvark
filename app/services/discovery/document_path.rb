module Discovery
  class DocumentPath < GeoWorks::Discovery::DocumentBuilder::DocumentPath
    # Override thumbnail method for MapSets
    def thumbnail
      return map_set_thumbnail_path if map_set?
      super
    end

    # Overrides method to get protocol outside of controller context.
    # Needed for delivering to geoblacklight from workflow method.
    def protocol
      default_url_options.fetch(:protocol, 'http').to_sym
    end

    # Overrides method to get host outside of controller context.
    # Needed for delivering to geoblacklight from workflow method.
    def host
      default_url_options[:host]
    end

    def default_url_options
      ActionMailer::Base.default_url_options
    end

    private

      def map_set?
        geo_concern.model_name.to_s == 'MapSet'
      end

      def map_set_thumbnail_path
        id = geo_concern.thumbnail_id
        return unless id
        path = hyrax_url_helpers.download_url(id, host: host, protocol: protocol)
        "#{path}?file=thumbnail"
      end

      # Override method for MapSets. MapSets don't contain image files directly.
      def file_set
        return if map_set?
        return unless geo_concern.geo_file_set_presenters
        geo_concern.geo_file_set_presenters.first
      end
  end
end
