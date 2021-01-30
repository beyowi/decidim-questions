# frozen_string_literal: true

module Decidim
  module Questions
    module Admin
      class Permissions < Decidim::DefaultPermissions
        def permissions
          # The public part needs to be implemented yet
          return permission_action if permission_action.scope != :admin

          # Valuators can only perform these actions
          if user_is_valuator?
            if valuator_assigned_to_question?
              can_create_question_note?
              can_create_question_answer?
            end
            can_export_questions?
            valuator_can_unassign_valuator_from_questions?

            return permission_action
          end

          if create_permission_action?
            can_create_question_note?
            can_create_question_from_admin?
            can_create_question_answer?
          end

          # Admins can only edit official questions if they are within the
          # time limit.
          allow! if permission_action.subject == :question && permission_action.action == :edit && admin_edition_is_available?

          # Every user allowed by the space can update the category of the question
          allow! if permission_action.subject == :question_category && permission_action.action == :update

          # Every user allowed by the space can update the scope of the question
          allow! if permission_action.subject == :question_scope && permission_action.action == :update

          # Every user allowed by the space can import questions from another_component
          allow! if permission_action.subject == :questions && permission_action.action == :import

          # Every user allowed by the space can export questions
          can_export_questions?

          # Every user allowed by the space can merge questions to another component
          allow! if permission_action.subject == :questions && permission_action.action == :merge

          # Every user allowed by the space can split questions to another component
          allow! if permission_action.subject == :questions && permission_action.action == :split

          # Every user allowed by the space can assign questions to a valuator
          allow! if permission_action.subject == :questions && permission_action.action == :assign_to_valuator

          # Every user allowed by the space can unassign a valuator from questions
          can_unassign_valuator_from_questions?

          # Only admin users can publish many answers at once
          toggle_allow(user.admin?) if permission_action.subject == :questions && permission_action.action == :publish_answers

          if permission_action.subject == :participatory_texts && participatory_texts_are_enabled?
            # Every user allowed by the space can manage (import, update and publish) participatory texts to questions
            allow! if permission_action.action == :manage
          end

          permission_action
        end

        private

        def question
          @question ||= context.fetch(:question, nil)
        end

        def user_valuator_role
          @user_valuator_role ||= space.user_roles(:valuator).find_by(user: user)
        end

        def user_is_valuator?
          return if user.admin?

          user_valuator_role.present?
        end

        def valuator_assigned_to_question?
          @valuator_assigned_to_question ||=
            Decidim::Questions::ValuationAssignment
            .where(question: question, valuator_role: user_valuator_role)
            .any?
        end

        def admin_creation_is_enabled?
          current_settings.try(:creation_enabled?) &&
            component_settings.try(:official_questions_enabled)
        end

        def admin_edition_is_available?
          return unless question

          (question.official? || question.official_meeting?) && question.votes.empty?
        end

        def admin_question_answering_is_enabled?
          current_settings.try(:question_answering_enabled) &&
            component_settings.try(:question_answering_enabled)
        end

        def create_permission_action?
          permission_action.action == :create
        end

        def participatory_texts_are_enabled?
          component_settings.participatory_texts_enabled?
        end

        # There's no special condition to create question notes, only
        # users with access to the admin section can do it.
        def can_create_question_note?
          allow! if permission_action.subject == :question_note
        end

        # Questions can only be created from the admin when the
        # corresponding setting is enabled.
        def can_create_question_from_admin?
          toggle_allow(admin_creation_is_enabled?) if permission_action.subject == :question
        end

        # Questions can only be answered from the admin when the
        # corresponding setting is enabled.
        def can_create_question_answer?
          toggle_allow(admin_question_answering_is_enabled?) if permission_action.subject == :question_answer
        end

        def can_unassign_valuator_from_questions?
          allow! if permission_action.subject == :questions && permission_action.action == :unassign_from_valuator
        end

        def valuator_can_unassign_valuator_from_questions?
          can_unassign_valuator_from_questions? if user == context.fetch(:valuator, nil)
        end

        def can_export_questions?
          allow! if permission_action.subject == :questions && permission_action.action == :export
        end
      end
    end
  end
end
