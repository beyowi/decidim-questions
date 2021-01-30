# frozen_string_literal: true

module Decidim
  module Questions
    module Admin
      # A command to notify about the change of the published state for a question.
      class NotifyQuestionAnswer < Rectify::Command
        # Public: Initializes the command.
        #
        # question - The question to write the answer for.
        # initial_state - The question state before the current process.
        def initialize(question, initial_state)
          @question = question
          @initial_state = initial_state.to_s
        end

        # Executes the command. Broadcasts these events:
        #
        # - :noop when the answer is not published or the state didn't changed.
        # - :ok when everything is valid.
        #
        # Returns nothing.
        def call
          if question.published_state? && state_changed?
            transaction do
              increment_score
              notify_followers
            end
          end

          broadcast(:ok)
        end

        private

        attr_reader :question, :initial_state

        def state_changed?
          initial_state != question.state.to_s
        end

        def notify_followers
          if question.accepted?
            publish_event(
              "decidim.events.questions.question_accepted",
              Decidim::Questions::AcceptedQuestionEvent
            )
          elsif question.rejected?
            publish_event(
              "decidim.events.questions.question_rejected",
              Decidim::Questions::RejectedQuestionEvent
            )
          elsif question.evaluating?
            publish_event(
              "decidim.events.questions.question_evaluating",
              Decidim::Questions::EvaluatingQuestionEvent
            )
          end
        end

        def publish_event(event, event_class)
          Decidim::EventsManager.publish(
            event: event,
            event_class: event_class,
            resource: question,
            affected_users: question.notifiable_identities,
            followers: question.followers - question.notifiable_identities
          )
        end

        def increment_score
          if question.accepted?
            question.coauthorships.find_each do |coauthorship|
              Decidim::Gamification.increment_score(coauthorship.user_group || coauthorship.author, :accepted_questions)
            end
          elsif initial_state == "accepted"
            question.coauthorships.find_each do |coauthorship|
              Decidim::Gamification.decrement_score(coauthorship.user_group || coauthorship.author, :accepted_questions)
            end
          end
        end
      end
    end
  end
end
