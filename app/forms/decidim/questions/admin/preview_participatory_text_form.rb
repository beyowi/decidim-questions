# frozen_string_literal: true

module Decidim
  module Questions
    module Admin
      # A form object to be used when admin users want to review a collection of questions
      # from a participatory text.
      class PreviewParticipatoryTextForm < Decidim::Form
        attribute :questions, Array[Decidim::Questions::Admin::ParticipatoryTextQuestionForm]

        def from_models(questions)
          self.questions = questions.collect do |question|
            Admin::ParticipatoryTextQuestionForm.from_model(question)
          end
        end

        def questions_attributes=(attributes); end
      end
    end
  end
end
