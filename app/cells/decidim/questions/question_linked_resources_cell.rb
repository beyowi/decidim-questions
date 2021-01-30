# frozen_string_literal: true

require "cell/partial"

module Decidim
  module Questions
    # This cell renders the linked resource of a question.
    class QuestionLinkedResourcesCell < Decidim::ViewModel
      def show
        render if linked_resource
      end
    end
  end
end
