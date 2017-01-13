module StateBehavior
  extend ActiveSupport::Concern

  included do
    # Sipity workflow state name
    def workflow_state
      return nil unless respond_to?(:to_sipity_entity) && persisted? && to_sipity_entity
      to_sipity_entity.workflow_state.name
    end
  end
end
