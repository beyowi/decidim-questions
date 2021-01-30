# frozen_string_literal: true

module Decidim
  module Questions
    module Admin
      # A command with all the business logic to unassign questions from a given
      # valuator.
      class UnassignQuestionsFromValuator < Rectify::Command
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

          unassign_questions
          broadcast(:ok)
        end

        private

        attr_reader :form

        def unassign_questions
          transaction do
            form.questions.flat_map do |question|
              assignment = find_assignment(question)
              unassign(assignment) if assignment
            end
          end
        end

        def find_assignment(question)
          Decidim::Questions::ValuationAssignment.find_by(
            question: question,
            valuator_role: form.valuator_role
          )
        end

        def unassign(assignment)
          Decidim.traceability.perform_action!(
            :delete,
            assignment,
            form.current_user,
            question_title: assignment.question.title
          ) do
            assignment.destroy!
          end
        end
      end
    end
  end
end
