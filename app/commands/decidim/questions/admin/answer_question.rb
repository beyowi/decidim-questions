# frozen_string_literal: true

module Decidim
  module Questions
    module Admin
      # A command with all the business logic when an admin answers a question.
      class AnswerQuestion < Rectify::Command
        # Public: Initializes the command.
        #
        # form - A form object with the params.
        # question - The question to write the answer for.
        def initialize(form, question)
          @form = form
          @question = question
        end

        # Executes the command. Broadcasts these events:
        #
        # - :ok when everything is valid.
        # - :invalid if the form wasn't valid and we couldn't proceed.
        #
        # Returns nothing.
        def call
          return broadcast(:invalid) if form.invalid?

          store_initial_question_state

          transaction do
            answer_question
            notify_question_answer
          end

          broadcast(:ok)
        end

        private

        attr_reader :form, :question, :initial_has_state_published, :initial_state

        def answer_question
          Decidim.traceability.perform_action!(
            "answer",
            question,
            form.current_user
          ) do
            attributes = {
              state: form.state,
              answer: form.answer,
              answered_at: Time.current,
              cost: form.cost,
              cost_report: form.cost_report,
              execution_period: form.execution_period
            }

            attributes[:state_published_at] = Time.current if !initial_has_state_published && form.publish_answer?

            question.update!(attributes)
          end
        end

        def notify_question_answer
          return if !initial_has_state_published && !form.publish_answer?

          NotifyQuestionAnswer.call(question, initial_state)
        end

        def store_initial_question_state
          @initial_has_state_published = question.published_state?
          @initial_state = question.state
        end
      end
    end
  end
end
