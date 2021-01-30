# frozen_string_literal: true

module Decidim
  module Questions
    # Exposes Questions versions so users can see how a Question/CollaborativeDraft
    # has been updated through time.
    class VersionsController < Decidim::Questions::ApplicationController
      include Decidim::ApplicationHelper
      include Decidim::ResourceVersionsConcern

      def versioned_resource
        @versioned_resource ||=
          if params[:question_id]
            present(Question.where(component: current_component).find(params[:question_id]))
          else
            CollaborativeDraft.where(component: current_component).find(params[:collaborative_draft_id])
          end
      end
    end
  end
end
