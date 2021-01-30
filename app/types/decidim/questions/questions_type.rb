# frozen_string_literal: true

module Decidim
  module Questions
    QuestionsType = GraphQL::ObjectType.define do
      interfaces [-> { Decidim::Core::ComponentInterface }]

      name "Questions"
      description "A questions component of a participatory space."

      connection :questions,
                 type: QuestionType.connection_type,
                 description: "List all questions",
                 function: QuestionListHelper.new(model_class: Question)

      field :question,
            type: QuestionType,
            description: "Finds one question",
            function: QuestionFinderHelper.new(model_class: Question)
    end

    class QuestionListHelper < Decidim::Core::ComponentListBase
      argument :order, QuestionInputSort, "Provides several methods to order the results"
      argument :filter, QuestionInputFilter, "Provides several methods to filter the results"

      # only querying published posts
      def query_scope
        super.published
      end
    end

    class QuestionFinderHelper < Decidim::Core::ComponentFinderBase
      argument :id, !types.ID, "The ID of the question"

      # only querying published posts
      def query_scope
        super.published
      end
    end
  end
end
