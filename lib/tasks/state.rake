# frozen_string_literal: true
namespace :state do
  desc "Migrate state from the state property to Sipity"
  task migrate: :environment do
    workflows = {
      'book_works': ['MultiVolumeWork', 'ScannedResource'],
      'geo_works': ['ImageWork', 'RasterWork', 'VectorWork']
    }
    workflows.keys.each do |workflow_name|
      workflows[workflow_name].each do |model|
        ActiveFedora::SolrService.query("has_model_ssim:#{model}", fl: "id", rows: 10_000).map { |x| x["id"] }.each do |id|
          puts "#{id} (#{model})"
          obj = ActiveFedora::Base.find(id)
          next if obj.workflow_state
          Workflow::InitializeState.call(obj, workflow_name, obj.state)
          obj.apply_remote_metadata
          obj.state = Vocab::FedoraResourceStatus.active
          obj.save!
        end
      end
    end
  end
end
