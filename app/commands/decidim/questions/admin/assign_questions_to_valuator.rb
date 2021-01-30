# frozen_string_literal: true

module Decidim
  module Questions
    module Admin
      # A command with all the business logic to assign questions to a given
      # valuator.
      class AssignQuestionsToValuator < Rectify::Command
        # Public: Initializes the command.
        #
        # form - A form object with the params.
        def initialize(form)
          @form = form
        end

        # Executes the command. Broadcasts these events:
        #
        # - :ok when everything is valid.
        # - :invalid if the form wasn't valid and we couldn't proceed.
        #
        # Returns nothing.
        def call
          return broadcast(:invalid) unless form.valid?

          assign_questions
          broadcast(:ok)
        rescue ActiveRecord::RecordInvalid
          broadcast(:invalid)
        end

        private

        attr_reader :form

        def assign_questions
          transaction do
            form.questions.flat_map do |question|
              find_assignment(question) || assign_question(question)
            end
          end
        end

        def find_assignment(question)
          Decidim::Questions::ValuationAssignment.find_by(
            question: question,
            valuator_role: form.valuator_role
          )
        end

        def assign_question(question)
          Decidim.traceability.create!(
            Decidim::Questions::ValuationAssignment,
            form.current_user,
            question: question,
            valuator_role: form.valuator_role
          )
        end
      end
    end
  end
end
