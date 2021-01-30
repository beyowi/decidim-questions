# frozen_string_literal: true

module Decidim
  module Questions
    # Exposes the question resource so users can view and create them.
    class QuestionsController < Decidim::Questions::ApplicationController
      helper Decidim::WidgetUrlsHelper
      helper QuestionWizardHelper
      helper ParticipatoryTextsHelper
      include Decidim::ApplicationHelper
      include FormFactory
      include FilterResource
      include Decidim::Questions::Orderable
      include Paginable

      helper_method :question_presenter, :form_presenter

      before_action :authenticate_user!, only: [:new, :create, :complete]
      before_action :ensure_is_draft, only: [:compare, :complete, :preview, :publish, :edit_draft, :update_draft, :destroy_draft]
      before_action :set_question, only: [:show, :edit, :update, :withdraw]
      before_action :edit_form, only: [:edit_draft, :edit]

      before_action :set_participatory_text

      def index
        if component_settings.participatory_texts_enabled?
          @questions = Decidim::Questions::Question
                       .where(component: current_component)
                       .published
                       .not_hidden
                       .only_amendables
                       .includes(:category, :scope)
                       .order(position: :asc)
          render "decidim/questions/questions/participatory_texts/participatory_text"
        else
          @questions = search
                       .results
                       .published
                       .not_hidden
                       .includes(:amendable, :category, :component, :resource_permission, :scope)

          @voted_questions = if current_user
                               QuestionVote.where(
                                 author: current_user,
                                 question: @questions.pluck(:id)
                               ).pluck(:decidim_question_id)
                             else
                               []
                             end
          @questions = paginate(@questions)
          @questions = reorder(@questions)
        end
      end

      def show
        raise ActionController::RoutingError, "Not Found" if @question.blank? || !can_show_question?

        @report_form = form(Decidim::ReportForm).from_params(reason: "spam")
      end

      def new
        enforce_permission_to :create, :question
        @step = :step_1
        if question_draft.present?
          redirect_to edit_draft_question_path(question_draft, component_id: question_draft.component.id, question_slug: question_draft.component.participatory_space.slug)
        else
          @form = form(QuestionWizardCreateStepForm).from_params(body: translated_question_body_template)
        end
      end

      def create
        enforce_permission_to :create, :question
        @step = :step_1
        @form = form(QuestionWizardCreateStepForm).from_params(question_creation_params)

        CreateQuestion.call(@form, current_user) do
          on(:ok) do |question|
            flash[:notice] = I18n.t("questions.create.success", scope: "decidim")

            redirect_to Decidim::ResourceLocatorPresenter.new(question).path + "/compare"
          end

          on(:invalid) do
            flash.now[:alert] = I18n.t("questions.create.error", scope: "decidim")
            render :new
          end
        end
      end

      def compare
        @step = :step_2
        @similar_questions ||= Decidim::Questions::SimilarQuestions
                               .for(current_component, @question)
                               .all

        if @similar_questions.blank?
          flash[:notice] = I18n.t("questions.questions.compare.no_similars_found", scope: "decidim")
          redirect_to Decidim::ResourceLocatorPresenter.new(@question).path + "/complete"
        end
      end

      def complete
        enforce_permission_to :create, :question
        @step = :step_3

        @form = form_question_model

        @form.attachment = form_attachment_new
      end

      def preview
        @step = :step_4
      end

      def publish
        @step = :step_4
        PublishQuestion.call(@question, current_user) do
          on(:ok) do
            flash[:notice] = I18n.t("questions.publish.success", scope: "decidim")
            redirect_to question_path(@question)
          end

          on(:invalid) do
            flash.now[:alert] = I18n.t("questions.publish.error", scope: "decidim")
            render :edit_draft
          end
        end
      end

      def edit_draft
        @step = :step_3
        enforce_permission_to :edit, :question, question: @question
      end

      def update_draft
        @step = :step_1
        enforce_permission_to :edit, :question, question: @question

        @form = form_question_params
        UpdateQuestion.call(@form, current_user, @question) do
          on(:ok) do |question|
            flash[:notice] = I18n.t("questions.update_draft.success", scope: "decidim")
            redirect_to Decidim::ResourceLocatorPresenter.new(question).path + "/preview"
          end

          on(:invalid) do
            flash.now[:alert] = I18n.t("questions.update_draft.error", scope: "decidim")
            render :edit_draft
          end
        end
      end

      def destroy_draft
        enforce_permission_to :edit, :question, question: @question

        DestroyQuestion.call(@question, current_user) do
          on(:ok) do
            flash[:notice] = I18n.t("questions.destroy_draft.success", scope: "decidim")
            redirect_to new_question_path
          end

          on(:invalid) do
            flash.now[:alert] = I18n.t("questions.destroy_draft.error", scope: "decidim")
            render :edit_draft
          end
        end
      end

      def edit
        enforce_permission_to :edit, :question, question: @question
      end

      def update
        enforce_permission_to :edit, :question, question: @question

        @form = form_question_params
        UpdateQuestion.call(@form, current_user, @question) do
          on(:ok) do |question|
            flash[:notice] = I18n.t("questions.update.success", scope: "decidim")
            redirect_to Decidim::ResourceLocatorPresenter.new(question).path
          end

          on(:invalid) do
            flash.now[:alert] = I18n.t("questions.update.error", scope: "decidim")
            render :edit
          end
        end
      end

      def withdraw
        enforce_permission_to :withdraw, :question, question: @question

        WithdrawQuestion.call(@question, current_user) do
          on(:ok) do
            flash[:notice] = I18n.t("questions.update.success", scope: "decidim")
            redirect_to Decidim::ResourceLocatorPresenter.new(@question).path
          end
          on(:has_supports) do
            flash[:alert] = I18n.t("questions.withdraw.errors.has_supports", scope: "decidim")
            redirect_to Decidim::ResourceLocatorPresenter.new(@question).path
          end
        end
      end

      private

      def search_klass
        QuestionSearch
      end

      def default_filter_params
        {
          search_text: "",
          origin: default_filter_origin_params,
          activity: "all",
          category_id: default_filter_category_params,
          state: %w(accepted evaluating not_answered),
          scope_id: default_filter_scope_params,
          related_to: "",
          type: "all"
        }
      end

      def default_filter_origin_params
        filter_origin_params = %w(citizens meeting)
        filter_origin_params << "official" if component_settings.official_questions_enabled
        filter_origin_params << "user_group" if current_organization.user_groups_enabled?
        filter_origin_params
      end

      def default_filter_category_params
        return "all" unless current_component.participatory_space.categories.any?

        ["all"] + current_component.participatory_space.categories.pluck(:id).map(&:to_s)
      end

      def default_filter_scope_params
        return "all" unless current_component.participatory_space.scopes.any?

        if current_component.participatory_space.scope
          ["all", current_component.participatory_space.scope.id] + current_component.participatory_space.scope.children.map { |scope| scope.id.to_s }
        else
          %w(all global) + current_component.participatory_space.scopes.pluck(:id).map(&:to_s)
        end
      end

      def question_draft
        Question.from_all_author_identities(current_user).not_hidden.only_amendables
                .where(component: current_component).find_by(published_at: nil)
      end

      def ensure_is_draft
        @question = Question.not_hidden.where(component: current_component).find(params[:id])
        redirect_to Decidim::ResourceLocatorPresenter.new(@question).path unless @question.draft?
      end

      def set_question
        @question = Question.published.not_hidden.where(component: current_component).find_by(id: params[:id])
      end

      # Returns true if the question is NOT an emendation or the user IS an admin.
      # Returns false if the question is not found or the question IS an emendation
      # and is NOT visible to the user based on the component's amendments settings.
      def can_show_question?
        return true if @question&.amendable? || current_user&.admin?

        Question.only_visible_emendations_for(current_user, current_component).published.include?(@question)
      end

      def question_presenter
        @question_presenter ||= present(@question)
      end

      def form_question_params
        form(QuestionForm).from_params(params)
      end

      def form_question_model
        form(QuestionForm).from_model(@question)
      end

      def form_presenter
        @form_presenter ||= present(@form, presenter_class: Decidim::Questions::QuestionPresenter)
      end

      def form_attachment_new
        form(AttachmentForm).from_model(Attachment.new)
      end

      def edit_form
        form_attachment_model = form(AttachmentForm).from_model(@question.attachments.first)
        @form = form_question_model
        @form.attachment = form_attachment_model
        @form
      end

      def set_participatory_text
        @participatory_text = Decidim::Questions::ParticipatoryText.find_by(component: current_component)
      end

      def translated_question_body_template
        translated_attribute component_settings.new_question_body_template
      end

      def question_creation_params
        params[:question].merge(body_template: translated_question_body_template)
      end
    end
  end
end
