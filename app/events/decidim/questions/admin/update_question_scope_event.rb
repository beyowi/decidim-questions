# frozen-string_literal: true

module Decidim
  module Questions
    module Admin
      class UpdateQuestionScopeEvent < Decidim::Events::SimpleEvent
        include Decidim::Events::AuthorEvent
      end
    end
  end
end
