class PolymorphicManifestBuilder
  class << self
    def new(solr_document, *args)
      if solr_document.member_presenters.map(&:class).uniq.length > 1
        sammelband_manifest_builder.new(solr_document, *args)
      elsif solr_document.is_a? MapSetShowPresenter
        sammelband_manifest_builder.new(solr_document, *args)
      else
        manifest_builder.new(solr_document, *args)
      end
    end

    private

      def manifest_builder
        ManifestBuilder
      end

      def sammelband_manifest_builder
        SammelbandManifestBuilder
      end
  end
end
