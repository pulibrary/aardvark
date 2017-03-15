class DeliverToGeoBlacklight
  attr_reader :record

  def initialize(obj)
    @record = obj
  end

  def delete
    geo_works_events_generator.record_deleted(geo_work)
  end

  def update
    geo_works_events_generator.record_updated(geo_work)
  end

  private

    def geo_works_events_generator
      @geo_works_events_generator ||= GeoWorks::EventsGenerator.new
    end

    def geo_work
      doc = ::SolrDocument.new(record.to_solr)
      show_presenter_class.new(doc, nil, nil)
    end

    def show_presenter_class
      ::DynamicShowPresenter.new
    end
end
