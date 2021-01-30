# frozen_string_literal: true

module Decidim
  module Questions
    class QuestionInputSort < Decidim::Core::BaseInputSort
      include Decidim::Core::HasPublishableInputSort
      include Decidim::Core::HasEndorsableInputSort

      graphql_name "QuestionSort"
      description "A type used for sorting questions"

      argument :id, String, "Sort by ID, valid values are ASC or DESC", required: false
      argument :vote_count,
               type: String,
               description: "Sort by number of votes, valid values are ASC or DESC. Will be ignored if votes are hidden",
               required: false,
               prepare: ->(value, _ctx) do
                          { question_votes_count: value }
                        end
    end
  end
end
