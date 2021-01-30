# frozen_string_literal: true

module Decidim
  module Questions
    module Admin
      # This controller allows admins to make private notes on questions in a participatory process.
      class QuestionNotesController < Admin::ApplicationController
        helper_method :question

        def create
          enforce_permission_to :create, :question_note, question: question
          @form = form(QuestionNoteForm).from_params(params)

          CreateQuestionNote.call(@form, question) do
            on(:ok) do
              flash[:notice] = I18n.t("question_notes.create.success", scope: "decidim.questions.admin")
              redirect_to question_path(id: question.id)
            end

            on(:invalid) do
              flash.keep[:alert] = I18n.t("question_notes.create.error", scope: "decidim.questions.admin")
              redirect_to question_path(id: question.id)
            end
          end
        end

        private

        def skip_manage_component_permission
          true
        end

        def question
          @question ||= Question.where(component: current_component).find(params[:question_id])
        end
      end
    end
  end
end
