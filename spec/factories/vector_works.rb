FactoryGirl.define do
  factory :vector_work do
    title ["Test title"]
    rights_statement ["http://rightsstatements.org/vocab/NKC/1.0/"]
    visibility Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
    state Vocab::FedoraResourceStatus.active

    transient do
      user { FactoryGirl.create(:user) }
    end

    after(:build) do |work, evaluator|
      work.apply_depositor_metadata(evaluator.user.user_key)
    end

    factory :complete_vector_work do
      after(:create) do |work, evaluator|
        FactoryGirl.create(:complete_sipity_entity, proxy_for_global_id: work.to_global_id.to_s)
        work.save
      end
    end

    factory :pending_vector_work do
      after(:create) do |work, evaluator|
        FactoryGirl.create(:pending_sipity_entity, proxy_for_global_id: work.to_global_id.to_s)
        work.save
      end
    end

    factory :vector_work_with_metadata_file do
      after(:create) do |vector_work, evaluator|
        file = FactoryGirl.create(:file_set, user: evaluator.user, geo_mime_type: 'application/xml; schema=fgdc')
        vector_work.ordered_members << file
        vector_work.save
        file.update_index
      end
    end
  end
end
