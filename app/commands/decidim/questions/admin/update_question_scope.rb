# frozen_string_literal: true

module Decidim
  module Questions
    module Admin
      #  A command with all the business logic when an admin batch updates questions scope.
      class UpdateQuestionScope < Rectify::Command
        include TranslatableAttributes
        # Public: Initializes the command.
        #
        # scope_id - the scope id to update
        # question_ids - the questions ids to update.
        def initialize(scope_id, question_ids)
          @scope = Decidim::Scope.find_by id: scope_id
          @question_ids = question_ids
          @response = { scope_name: "", successful: [], errored: [] }
        end

        # Executes the command. Broadcasts these events:
        #
        # - :update_questions_scope - when everything is ok, returns @response.
        # - :invalid_scope - if the scope is blank.
        # - :invalid_question_ids - if the question_ids is blank.
        #
        # Returns @response hash:
        #
        # - :scope_name - the translated_name of the scope assigned
        # - :successful - Array of names of the updated questions
        # - :errored - Array of names of the questions not updated because they already had the scope assigned
        def call
          return broadcast(:invalid_scope) if @scope.blank?
          return broadcast(:invalid_question_ids) if @question_ids.blank?

          update_questions_scope

          broadcast(:update_questions_scope, @response)
        end

        private

        attr_reader :scope, :question_ids

        def update_questions_scope
          @response[:scope_name] = translated_attribute(scope.name, scope.organization)
          Question.where(id: question_ids).find_each do |question|
            if scope == question.scope
              @response[:errored] << question.title
            else
              transaction do
                update_question_scope question
                notify_author question if question.coauthorships.any?
              end
              @response[:successful] << question.title
            end
          end
        end

        def update_question_scope(question)
          question.update!(
            scope: scope
          )
        end

        def notify_author(question)
          Decidim::EventsManager.publish(
            event: "decidim.events.questions.question_update_scope",
            event_class: Decidim::Questions::Admin::UpdateQuestionScopeEvent,
            resource: question,
            affected_users: question.notifiable_identities
          )
        end
      end
    end
  end
end
