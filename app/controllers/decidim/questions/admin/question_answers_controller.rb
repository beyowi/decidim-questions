# frozen_string_literal: true

module Decidim
  module Questions
    module Admin
      # This controller allows admins to answer questions in a participatory process.
      class QuestionAnswersController < Admin::ApplicationController
        helper_method :question

        helper Questions::ApplicationHelper
        helper Decidim::Questions::Admin::QuestionsHelper
        helper Decidim::Questions::Admin::QuestionRankingsHelper
        helper Decidim::Messaging::ConversationHelper

        def edit
          enforce_permission_to :create, :question_answer, question: question
          @form = form(Admin::QuestionAnswerForm).from_model(question)
        end

        def update
          enforce_permission_to :create, :question_answer, question: question
          @notes_form = form(QuestionNoteForm).instance
          @answer_form = form(Admin::QuestionAnswerForm).from_params(params)

          Admin::AnswerQuestion.call(@answer_form, question) do
            on(:ok) do
              flash[:notice] = I18n.t("questions.answer.success", scope: "decidim.questions.admin")
              redirect_to questions_path
            end

            on(:invalid) do
              flash.keep[:alert] = I18n.t("questions.answer.invalid", scope: "decidim.questions.admin")
              render template: "decidim/questions/admin/questions/show"
            end
          end
        end

        private

        def skip_manage_component_permission
          true
        end

        def question
          @question ||= Question.where(component: current_component).find(params[:id])
        end
      end
    end
  end
end
