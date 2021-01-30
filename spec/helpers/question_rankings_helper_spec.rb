# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Questions
    module Admin
      describe QuestionRankingsHelper do
        let(:component) { create(:question_component) }

        let!(:question1) { create :question, component: component, question_votes_count: 4 }
        let!(:question2) { create :question, component: component, question_votes_count: 2 }
        let!(:question3) { create :question, component: component, question_votes_count: 2 }
        let!(:question4) { create :question, component: component, question_votes_count: 1 }

        let!(:external_question) { create :question, question_votes_count: 8 }

        describe "ranking_for" do
          it "returns the ranking considering only sibling questions" do
            result = helper.ranking_for(question1, question_votes_count: :desc)

            expect(result).to eq(ranking: 1, total: 4)
          end

          it "breaks ties by ordering by ID" do
            result = helper.ranking_for(question3, question_votes_count: :desc)

            expect(result).to eq(ranking: 3, total: 4)
          end
        end
      end
    end
  end
end
