class WorkIndexer < CurationConcerns::WorkIndexer
  def generate_solr_document
    super.tap do |solr_doc|
      object.member_of_collections.each do |col|
        solr_doc[Solrizer.solr_name('member_of_collection_slugs', :symbol)] = col.exhibit_id
      end
      (PlumSchema.display_fields + [:title]).each do |field|
        objects = object.get_values(field, literal: true)
        statements = objects.map do |obj|
          ::RDF::Statement.from([object.rdf_subject, ::RDF::URI(""), obj])
        end
        output = JSON::LD::API.fromRdf(statements)
        next unless output.length > 0
        output = output[0][""]
        output.map! do |object|
          if object.is_a?(Hash) && object["@value"] && object.keys.length == 1
            object["@value"]
          else
            object.to_json
          end
        end
        solr_doc[Solrizer.solr_name("#{field}_literals", :symbol)] = output
      end
      solr_doc[Solrizer.solr_name("identifier", :symbol)] = object.identifier
    end
  end
end
