# frozen_string_literal: true

module Decidim
  module Questions
    module Admin
      # A command with all the business logic to publish many answers at once.
      class PublishAnswers < Rectify::Command
        # Public: Initializes the command.
        #
        # component - The component that contains the answers.
        # user - the Decidim::User that is publishing the answers.
        # question_ids - the identifiers of the questions with the answers to be published.
        def initialize(component, user, question_ids)
          @component = component
          @user = user
          @question_ids = question_ids
        end

        # Executes the command. Broadcasts these events:
        #
        # - :ok when everything is valid.
        # - :invalid if there are not questions to publish.
        #
        # Returns nothing.
        def call
          return broadcast(:invalid) unless questions.any?

          questions.each do |question|
            transaction do
              mark_question_as_answered(question)
              notify_question_answer(question)
            end
          end

          broadcast(:ok)
        end

        private

        attr_reader :component, :user, :question_ids

        def questions
          @questions ||= Decidim::Questions::Question
                         .published
                         .answered
                         .state_not_published
                         .where(component: component)
                         .where(id: question_ids)
        end

        def mark_question_as_answered(question)
          Decidim.traceability.perform_action!(
            "publish_answer",
            question,
            user
          ) do
            question.update!(state_published_at: Time.current)
          end
        end

        def notify_question_answer(question)
          NotifyQuestionAnswer.call(question, nil)
        end
      end
    end
  end
end
