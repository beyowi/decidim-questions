# frozen_string_literal: true

module Decidim
  module Questions
    # Custom helpers, scoped to the questions engine.
    #
    module ApplicationHelper
      include Decidim::Comments::CommentsHelper
      include PaginateHelper
      include QuestionVotesHelper
      include ::Decidim::EndorsableHelper
      include ::Decidim::FollowableHelper
      include Decidim::MapHelper
      include Decidim::Questions::MapHelper
      include CollaborativeDraftHelper
      include ControlVersionHelper
      include Decidim::RichTextEditorHelper
      include Decidim::CheckBoxesTreeHelper

      delegate :minimum_votes_per_user, to: :component_settings

      # Public: The state of a question in a way a human can understand.
      #
      # state - The String state of the question.
      #
      # Returns a String.
      def humanize_question_state(state)
        I18n.t(state, scope: "decidim.questions.answers", default: :not_answered)
      end

      # Public: The css class applied based on the question state.
      #
      # state - The String state of the question.
      #
      # Returns a String.
      def question_state_css_class(state)
        case state
        when "accepted"
          "text-success"
        when "rejected"
          "text-alert"
        when "evaluating"
          "text-warning"
        when "withdrawn"
          "text-alert"
        else
          "text-info"
        end
      end

      # Public: The state of a question in a way a human can understand.
      #
      # state - The String state of the question.
      #
      # Returns a String.
      def humanize_collaborative_draft_state(state)
        I18n.t("decidim.questions.collaborative_drafts.states.#{state}", default: :open)
      end

      # Public: The css class applied based on the collaborative draft state.
      #
      # state - The String state of the collaborative draft.
      #
      # Returns a String.
      def collaborative_draft_state_badge_css_class(state)
        case state
        when "open"
          "success"
        when "withdrawn"
          "alert"
        when "published"
          "secondary"
        end
      end

      def question_limit_enabled?
        question_limit.present?
      end

      def minimum_votes_per_user_enabled?
        minimum_votes_per_user.positive?
      end

      def not_from_collaborative_draft(question)
        question.linked_resources(:questions, "created_from_collaborative_draft").empty?
      end

      def not_from_participatory_text(question)
        question.participatory_text_level.nil?
      end

      # If the question is official or the rich text editor is enabled on the
      # frontend, the question body is considered as safe content; that's unless
      # the question comes from a collaborative_draft or a participatory_text.
      def safe_content?
        rich_text_editor_in_public_views? && not_from_collaborative_draft(@question) ||
          (@question.official? || @question.official_meeting?) && not_from_participatory_text(@question)
      end

      # If the content is safe, HTML tags are sanitized, otherwise, they are stripped.
      def render_question_body(question)
        body = present(question).body(links: true, strip_tags: !safe_content?)
        body = simple_format(body, {}, sanitize: false)

        return body unless safe_content?

        decidim_sanitize(body)
      end

      # Returns :text_area or :editor based on the organization' settings.
      def text_editor_for_question_body(form)
        options = {
          class: "js-hashtags",
          hashtaggable: true,
          value: form_presenter.body(extras: false).strip
        }

        text_editor_for(form, :body, options)
      end

      def question_limit
        return if component_settings.question_limit.zero?

        component_settings.question_limit
      end

      def votes_given
        @votes_given ||= QuestionVote.where(
          question: Question.where(component: current_component),
          author: current_user
        ).count
      end

      def votes_count_for(model, from_questions_list)
        render partial: "decidim/questions/questions/participatory_texts/question_votes_count.html", locals: { question: model, from_questions_list: from_questions_list }
      end

      def vote_button_for(model, from_questions_list)
        render partial: "decidim/questions/questions/participatory_texts/question_vote_button.html", locals: { question: model, from_questions_list: from_questions_list }
      end

      def endorsers_for(question)
        question.endorsements.for_listing.map { |identity| present(identity.normalized_author) }
      end

      def form_has_address?
        @form.address.present? || @form.has_address
      end

      def authors_for(collaborative_draft)
        collaborative_draft.identities.map { |identity| present(identity) }
      end

      def show_voting_rules?
        return false unless votes_enabled?

        return true if vote_limit_enabled?
        return true if threshold_per_question_enabled?
        return true if question_limit_enabled?
        return true if can_accumulate_supports_beyond_threshold?
        return true if minimum_votes_per_user_enabled?
      end

      def filter_type_values
        [
          ["all", t("decidim.questions.application_helper.filter_type_values.all")],
          ["questions", t("decidim.questions.application_helper.filter_type_values.questions")],
          ["amendments", t("decidim.questions.application_helper.filter_type_values.amendments")]
        ]
      end

      # Options to filter Questions by activity.
      def activity_filter_values
        base = [
          ["all", t(".all")],
          ["my_questions", t(".my_questions")]
        ]
        base += [["voted", t(".voted")]] if current_settings.votes_enabled?
        base
      end

      def filter_origin_values
        origin_values = []
        origin_values << TreePoint.new("official", t("decidim.questions.application_helper.filter_origin_values.official")) if component_settings.official_questions_enabled
        origin_values << TreePoint.new("citizens", t("decidim.questions.application_helper.filter_origin_values.citizens"))
        origin_values << TreePoint.new("user_group", t("decidim.questions.application_helper.filter_origin_values.user_groups")) if current_organization.user_groups_enabled?
        origin_values << TreePoint.new("meeting", t("decidim.questions.application_helper.filter_origin_values.meetings"))

        TreeNode.new(
          TreePoint.new("", t("decidim.questions.application_helper.filter_origin_values.all")),
          origin_values
        )
      end
    end
  end
end
