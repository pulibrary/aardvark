namespace :collection do
  desc "Mark all members of a Collection complete"
  task complete: :environment do
    colid = ENV['COLLECTION']
    abort "usage: COLLECTION=[collection id] rake complete_collection" unless colid
    begin
      col = Collection.find( colid )
      puts "completing objects in collection: #{col.title.first}"
      col.member_objects.each do |obj|
        advance(obj, 'metadata_review') if obj.state == 'pending'
        advance(obj, 'final_review') if obj.state == 'metadata_review'
        advance(obj, 'complete') if obj.state == 'final_review'
      end
    rescue => e
      puts "Error: #{e.message}"
    end
  end

  desc "Copy all members of a Collection to another Collection"
  task copy: :environment do
    begin
      Rails.logger = Logger.new(STDOUT)
      from_collection = Collection.find(ENV['FROM_COLLECTION'])
      to_collection = Collection.find(ENV['TO_COLLECTION'])
      MembershipService.copy_membership(from_collection, to_collection)
    rescue => e
      puts "Error: #{e.message}"
    end
  end

  desc "Transfer all members of a Collection to another Collection"
  task transfer: :environment do
    begin
      Rails.logger = Logger.new(STDOUT)
      from_collection = Collection.find(ENV['FROM_COLLECTION'])
      to_collection = Collection.find(ENV['TO_COLLECTION'])
      MembershipService.transfer_membership(from_collection, to_collection)
    rescue => e
      puts "Error: #{e.message}"
    end
  end
end

def advance(obj, state)
  puts "#{obj.id}: #{obj.state} -> #{state}"
  obj.state = state
  obj.save!
  manifest_event_generator.record_updated(obj)
end

def manifest_event_generator
  @manifest_event_generator ||= ManifestEventGenerator.new(Plum.messaging_client)
end
