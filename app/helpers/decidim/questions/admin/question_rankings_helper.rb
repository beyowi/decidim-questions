# frozen_string_literal: true

module Decidim
  module Questions
    module Admin
      # This class contains helpers needed to get rankings for a given question
      # ordered by some given criteria.
      #
      module QuestionRankingsHelper
        # Public: Gets the ranking for a given question, ordered by some given
        # criteria. Question is sorted amongst its own siblings.
        #
        # Returns a Hash with two keys:
        #   :ranking - an Integer representing the ranking for the given question.
        #     Ranking starts with 1.
        #   :total - an Integer representing the total number of ranked questions.
        #
        # Examples:
        #   ranking_for(question, question_votes_count: :desc)
        #   ranking_for(question, endorsements_count: :desc)
        def ranking_for(question, order = {})
          siblings = Decidim::Questions::Question.where(component: question.component)
          ranked = siblings.order([order, id: :asc])
          ranked_ids = ranked.pluck(:id)

          { ranking: ranked_ids.index(question.id) + 1, total: ranked_ids.count }
        end

        # Public: Gets the ranking for a given question, ordered by endorsements.
        def endorsements_ranking_for(question)
          ranking_for(question, endorsements_count: :desc)
        end

        # Public: Gets the ranking for a given question, ordered by votes.
        def votes_ranking_for(question)
          ranking_for(question, question_votes_count: :desc)
        end

        def i18n_endorsements_ranking_for(question)
          rankings = endorsements_ranking_for(question)

          I18n.t(
            "ranking",
            scope: "decidim.questions.admin.questions.show",
            ranking: rankings[:ranking],
            total: rankings[:total]
          )
        end

        def i18n_votes_ranking_for(question)
          rankings = votes_ranking_for(question)

          I18n.t(
            "ranking",
            scope: "decidim.questions.admin.questions.show",
            ranking: rankings[:ranking],
            total: rankings[:total]
          )
        end
      end
    end
  end
end
