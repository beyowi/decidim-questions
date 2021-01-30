# frozen_string_literal: true

module Decidim
  module Questions
    # Simple helpers to handle markup variations for questions
    module QuestionsHelper
      def question_reason_callout_args
        {
          announcement: {
            title: question_reason_callout_title,
            body: decidim_sanitize(translated_attribute(@question.answer))
          },
          callout_class: question_reason_callout_class
        }
      end

      def question_reason_callout_class
        case @question.state
        when "accepted"
          "success"
        when "evaluating"
          "warning"
        when "rejected"
          "alert"
        else
          ""
        end
      end

      def question_reason_callout_title
        i18n_key = case @question.state
                   when "evaluating"
                     "question_in_evaluation_reason"
                   else
                     "question_#{@question.state}_reason"
                   end

        t(i18n_key, scope: "decidim.questions.questions.show")
      end

      def filter_questions_state_values
        Decidim::CheckBoxesTreeHelper::TreeNode.new(
          Decidim::CheckBoxesTreeHelper::TreePoint.new("", t("decidim.questions.application_helper.filter_state_values.all")),
          [
            Decidim::CheckBoxesTreeHelper::TreePoint.new("accepted", t("decidim.questions.application_helper.filter_state_values.accepted")),
            Decidim::CheckBoxesTreeHelper::TreePoint.new("evaluating", t("decidim.questions.application_helper.filter_state_values.evaluating")),
            Decidim::CheckBoxesTreeHelper::TreePoint.new("not_answered", t("decidim.questions.application_helper.filter_state_values.not_answered")),
            Decidim::CheckBoxesTreeHelper::TreePoint.new("rejected", t("decidim.questions.application_helper.filter_state_values.rejected"))
          ]
        )
      end

      def question_has_costs?
        @question.cost.present? &&
          translated_attribute(@question.cost_report).present? &&
          translated_attribute(@question.execution_period).present?
      end

      def resource_version(resource, options = {})
        return unless resource.respond_to?(:amendable?) && resource.amendable?

        super
      end
    end
  end
end
