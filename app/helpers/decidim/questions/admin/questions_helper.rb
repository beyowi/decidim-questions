# frozen_string_literal: true

module Decidim
  module Questions
    module Admin
      # This class contains helpers needed to format Meetings
      # in order to use them in select forms for Questions.
      #
      module QuestionsHelper
        # Public: A formatted collection of Meetings to be used
        # in forms.
        def meetings_as_authors_selected
          return unless @question.present? && @question.official_meeting?

          @meetings_as_authors_selected ||= @question.authors.pluck(:id)
        end

        def coauthor_presenters_for(question)
          question.authors.map do |identity|
            if identity.is_a?(Decidim::Organization)
              Decidim::Questions::OfficialAuthorPresenter.new
            else
              present(identity)
            end
          end
        end

        def endorsers_presenters_for(question)
          question.endorsements.for_listing.map { |identity| present(identity.normalized_author) }
        end

        def question_complete_state(question)
          state = humanize_question_state(question.state)
          state += " (#{humanize_question_state(question.internal_state)})" if question.answered? && !question.published_state?
          state.html_safe
        end

        def questions_admin_filter_tree
          {
            t("questions.filters.type", scope: "decidim.questions") => {
              link_to(t("questions", scope: "decidim.questions.application_helper.filter_type_values"), q: ransak_params_for_query(is_emendation_true: "0"),
                                                                                                        per_page: per_page) => nil,
              link_to(t("amendments", scope: "decidim.questions.application_helper.filter_type_values"), q: ransak_params_for_query(is_emendation_true: "1"),
                                                                                                         per_page: per_page) => nil
            },
            t("models.question.fields.state", scope: "decidim.questions") =>
              Decidim::Questions::Question::POSSIBLE_STATES.each_with_object({}) do |state, hash|
                if state == "not_answered"
                  hash[link_to((humanize_question_state state), q: ransak_params_for_query(state_null: 1), per_page: per_page)] = nil
                else
                  hash[link_to((humanize_question_state state), q: ransak_params_for_query(state_eq: state), per_page: per_page)] = nil
                end
              end,
            t("models.question.fields.category", scope: "decidim.questions") => admin_filter_categories_tree(categories.first_class),
            t("questions.filters.scope", scope: "decidim.questions") => admin_filter_scopes_tree(current_component.organization.id)
          }
        end

        def questions_admin_search_hidden_params
          return unless params[:q]

          tags = ""
          tags += hidden_field_tag "per_page", params[:per_page] if params[:per_page]
          tags += hidden_field_tag "q[is_emendation_true]", params[:q][:is_emendation_true] if params[:q][:is_emendation_true]
          tags += hidden_field_tag "q[state_eq]", params[:q][:state_eq] if params[:q][:state_eq]
          tags += hidden_field_tag "q[category_id_eq]", params[:q][:category_id_eq] if params[:q][:category_id_eq]
          tags += hidden_field_tag "q[scope_id_eq]", params[:q][:scope_id_eq] if params[:q][:scope_id_eq]
          tags.html_safe
        end

        def questions_admin_filter_applied_filters
          html = []
          if params[:q][:is_emendation_true].present?
            html << content_tag(:span, class: "label secondary") do
              tag = "#{t("filters.type", scope: "decidim.questions.questions")}: "
              tag += if params[:q][:is_emendation_true].to_s == "1"
                       t("amendments", scope: "decidim.questions.application_helper.filter_type_values")
                     else
                       t("questions", scope: "decidim.questions.application_helper.filter_type_values")
                     end
              tag += icon_link_to("circle-x", url_for(q: ransak_params_for_query_without(:is_emendation_true), per_page: per_page), t("decidim.admin.actions.cancel"),
                                  class: "action-icon--remove")
              tag.html_safe
            end
          end
          if params[:q][:state_null]
            html << content_tag(:span, class: "label secondary") do
              tag = "#{t("models.question.fields.state", scope: "decidim.questions")}: "
              tag += humanize_question_state "not_answered"
              tag += icon_link_to("circle-x", url_for(q: ransak_params_for_query_without(:state_null), per_page: per_page), t("decidim.admin.actions.cancel"),
                                  class: "action-icon--remove")
              tag.html_safe
            end
          end
          if params[:q][:state_eq]
            html << content_tag(:span, class: "label secondary") do
              tag = "#{t("models.question.fields.state", scope: "decidim.questions")}: "
              tag += humanize_question_state params[:q][:state_eq]
              tag += icon_link_to("circle-x", url_for(q: ransak_params_for_query_without(:state_eq), per_page: per_page), t("decidim.admin.actions.cancel"),
                                  class: "action-icon--remove")
              tag.html_safe
            end
          end
          if params[:q][:category_id_eq]
            html << content_tag(:span, class: "label secondary") do
              tag = "#{t("models.question.fields.category", scope: "decidim.questions")}: "
              tag += translated_attribute categories.find(params[:q][:category_id_eq]).name
              tag += icon_link_to("circle-x", url_for(q: ransak_params_for_query_without(:category_id_eq), per_page: per_page), t("decidim.admin.actions.cancel"),
                                  class: "action-icon--remove")
              tag.html_safe
            end
          end
          if params[:q][:scope_id_eq]
            html << content_tag(:span, class: "label secondary") do
              tag = "#{t("models.question.fields.scope", scope: "decidim.questions")}: "
              tag += translated_attribute Decidim::Scope.where(decidim_organization_id: current_component.organization.id).find(params[:q][:scope_id_eq]).name
              tag += icon_link_to("circle-x", url_for(q: ransak_params_for_query_without(:scope_id_eq), per_page: per_page), t("decidim.admin.actions.cancel"),
                                  class: "action-icon--remove")
              tag.html_safe
            end
          end
          html.join(" ").html_safe
        end

        def icon_with_link_to_question(question)
          icon, tooltip = if allowed_to?(:create, :question_answer, question: question) && !question.emendation?
                            [
                              "comment-square",
                              t(:answer_question, scope: "decidim.questions.actions")
                            ]
                          else
                            [
                              "info",
                              t(:show, scope: "decidim.questions.actions")
                            ]
                          end
          icon_link_to(icon, question_path(question), tooltip, class: "icon--small action-icon--show-question")
        end
      end
    end
  end
end
