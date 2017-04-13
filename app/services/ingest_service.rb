class IngestService
  def initialize(logger = nil)
    @logger = logger || Logger.new(STDOUT)
  end

  def minimal_record(klass, user, attributes)
    default_attributes = { rights_statement: 'http://rightsstatements.org/vocab/NKC/1.0/',
                           visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC }
    r = klass.new
    r.attributes = default_attributes.merge(attributes)
    r.apply_depositor_metadata user
    r.apply_remote_metadata if r.source_metadata_identifier
    r.save!
    Workflow::InitializeState.call(r, workflow_name, 'final_review')
    @logger.info "Created #{klass}: #{r.id} #{attributes}"

    r
  end

  def ingest_dir(dir, bib, user, collection = nil)
    klass = choose_class(Dir["#{dir}/*"].first)
    attribs = bib.nil? ? { title: [File.basename(dir)] } : { source_metadata_identifier: bib }
    r = minimal_record klass, user, attribs
    members = []
    Dir["#{dir}/*"].sort.each do |f|
      if File.directory? f
        members << ingest_dir(f, nil, user)
      else
        members << ingest_file(r, f, user, {}, file_set_attributes.merge(title: [File.basename(f)]))
      end
    end
    r.ordered_members = members
    r.member_of_collections << collection if collection
    r.save!

    r
  end

  def ingest_work(file_path, user)
    klass = choose_class(file_path)
    bib_id = File.basename(file_path, '.*')
    attribs = { source_metadata_identifier: bib_id }
    r = minimal_record klass, user, attribs
    members = [ingest_file(r, file_path, user, {}, file_set_attributes.merge(title: [bib_id]))]
    r.ordered_members = members
    r.save!

    r
  end

  def ingest_file(parent, file, user, file_options, attributes)
    file_set = FileSet.new
    file_set.attributes = attributes
    actor = BatchFileSetActor.new(file_set, user)
    actor.create_metadata(file_options)
    actor.create_content(file)
    actor.attach_file_to_work(parent)
    @logger.info "Ingested file #{file}"

    file_set
  end

  def delete_duplicates!(query)
    ActiveFedora::SolrService.query(query, fl: "id").map { |x| ActiveFedora::Base.find(x["id"]) }.each do |r|
      @logger.info "Deleting existing resource with ID of #{r.id} which matched #{query}"
      r.destroy
    end
  end

  def workflow_name
    'book_works'
  end

  def choose_class(file)
    File.directory?(file) ? MultiVolumeWork : ScannedResource
  end

  def file_set_attributes
    {}
  end
end
