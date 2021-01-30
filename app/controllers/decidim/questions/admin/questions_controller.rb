# frozen_string_literal: true

module Decidim
  module Questions
    module Admin
      # This controller allows admins to manage questions in a participatory process.
      class QuestionsController < Admin::ApplicationController
        include Decidim::ApplicationHelper
        include Decidim::Questions::Admin::Filterable

        helper Questions::ApplicationHelper
        helper Decidim::Questions::Admin::QuestionRankingsHelper
        helper Decidim::Messaging::ConversationHelper
        helper_method :questions, :query, :form_presenter, :question, :question_ids
        helper Questions::Admin::QuestionBulkActionsHelper

        def show
          @notes_form = form(QuestionNoteForm).instance
          @answer_form = form(Admin::QuestionAnswerForm).from_model(question)
        end

        def new
          enforce_permission_to :create, :question
          @form = form(Admin::QuestionForm).from_params(
            attachment: form(AttachmentForm).from_params({})
          )
        end

        def create
          enforce_permission_to :create, :question
          @form = form(Admin::QuestionForm).from_params(params)

          Admin::CreateQuestion.call(@form) do
            on(:ok) do
              flash[:notice] = I18n.t("questions.create.success", scope: "decidim.questions.admin")
              redirect_to questions_path
            end

            on(:invalid) do
              flash.now[:alert] = I18n.t("questions.create.invalid", scope: "decidim.questions.admin")
              render action: "new"
            end
          end
        end

        def update_category
          enforce_permission_to :update, :question_category

          Admin::UpdateQuestionCategory.call(params[:category][:id], question_ids) do
            on(:invalid_category) do
              flash.now[:error] = I18n.t(
                "questions.update_category.select_a_category",
                scope: "decidim.questions.admin"
              )
            end

            on(:invalid_question_ids) do
              flash.now[:alert] = I18n.t(
                "questions.update_category.select_a_question",
                scope: "decidim.questions.admin"
              )
            end

            on(:update_questions_category) do
              flash.now[:notice] = update_questions_bulk_response_successful(@response, :category)
              flash.now[:alert] = update_questions_bulk_response_errored(@response, :category)
            end
            respond_to do |format|
              format.js
            end
          end
        end

        def publish_answers
          enforce_permission_to :publish_answers, :questions

          Decidim::Questions::Admin::PublishAnswers.call(current_component, current_user, question_ids) do
            on(:invalid) do
              flash.now[:alert] = t(
                "questions.publish_answers.select_a_question",
                scope: "decidim.questions.admin"
              )
            end

            on(:ok) do
              flash.now[:notice] = I18n.t("questions.publish_answers.success", scope: "decidim")
            end
          end

          respond_to do |format|
            format.js
          end
        end

        def update_scope
          enforce_permission_to :update, :question_scope

          Admin::UpdateQuestionScope.call(params[:scope_id], question_ids) do
            on(:invalid_scope) do
              flash.now[:error] = t(
                "questions.update_scope.select_a_scope",
                scope: "decidim.questions.admin"
              )
            end

            on(:invalid_question_ids) do
              flash.now[:alert] = t(
                "questions.update_scope.select_a_question",
                scope: "decidim.questions.admin"
              )
            end

            on(:update_questions_scope) do
              flash.now[:notice] = update_questions_bulk_response_successful(@response, :scope)
              flash.now[:alert] = update_questions_bulk_response_errored(@response, :scope)
            end

            respond_to do |format|
              format.js
            end
          end
        end

        def edit
          enforce_permission_to :edit, :question, question: question
          @form = form(Admin::QuestionForm).from_model(question)
          @form.attachment = form(AttachmentForm).from_params({})
        end

        def update
          enforce_permission_to :edit, :question, question: question

          @form = form(Admin::QuestionForm).from_params(params)
          Admin::UpdateQuestion.call(@form, @question) do
            on(:ok) do |_question|
              flash[:notice] = t("questions.update.success", scope: "decidim")
              redirect_to questions_path
            end

            on(:invalid) do
              flash.now[:alert] = t("questions.update.error", scope: "decidim")
              render :edit
            end
          end
        end

        private

        def collection
          @collection ||= Question.where(component: current_component).published
        end

        def questions
          @questions ||= filtered_collection
        end

        def question
          @question ||= collection.find(params[:id])
        end

        def question_ids
          @question_ids ||= params[:question_ids]
        end

        def update_questions_bulk_response_successful(response, subject)
          return if response[:successful].blank?

          if subject == :category
            t(
              "questions.update_category.success",
              subject_name: response[:subject_name],
              questions: response[:successful].to_sentence,
              scope: "decidim.questions.admin"
            )
          elsif subject == :scope
            t(
              "questions.update_scope.success",
              subject_name: response[:subject_name],
              questions: response[:successful].to_sentence,
              scope: "decidim.questions.admin"
            )
          end
        end

        def update_questions_bulk_response_errored(response, subject)
          return if response[:errored].blank?

          if subject == :category
            t(
              "questions.update_category.invalid",
              subject_name: response[:subject_name],
              questions: response[:errored].to_sentence,
              scope: "decidim.questions.admin"
            )
          elsif subject == :scope
            t(
              "questions.update_scope.invalid",
              subject_name: response[:subject_name],
              questions: response[:errored].to_sentence,
              scope: "decidim.questions.admin"
            )
          end
        end

        def form_presenter
          @form_presenter ||= present(@form, presenter_class: Decidim::Questions::QuestionPresenter)
        end
      end
    end
  end
end
