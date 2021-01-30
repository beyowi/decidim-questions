# frozen_string_literal: true

require "spec_helper"
require "decidim/api/test/type_context"
require "decidim/core/test"
require "decidim/core/test/shared_examples/input_sort_examples"

module Decidim
  module Questions
    describe QuestionInputSort, type: :graphql do
      include_context "with a graphql type"

      let(:type_class) { Decidim::Questions::QuestionsType }

      let(:model) { create(:question_component) }
      let!(:models) { create_list(:question, 3, :published, component: model) }

      context "when sorting by questions id" do
        include_examples "connection has input sort", "questions", "id"
      end

      context "when sorting by published_at" do
        include_examples "connection has input sort", "questions", "publishedAt"
      end

      context "when sorting by endorsement_count" do
        let!(:most_endorsed) { create(:question, :published, :with_endorsements, component: model) }

        include_examples "connection has endorsement_count sort", "questions"
      end

      context "when sorting by vote_count" do
        let!(:votes) { create_list(:question_vote, 3, question: models.last) }

        describe "ASC" do
          let(:query) { %[{ questions(order: {voteCount: "ASC"}) { edges { node { id } } } }] }

          it "returns the most voted last" do
            expect(response["questions"]["edges"].count).to eq(3)
            expect(response["questions"]["edges"].last["node"]["id"]).to eq(models.last.id.to_s)
          end
        end

        describe "DESC" do
          let(:query) { %[{ questions(order: {voteCount: "DESC"}) { edges { node { id } } } }] }

          it "returns the most voted first" do
            expect(response["questions"]["edges"].count).to eq(3)
            expect(response["questions"]["edges"].first["node"]["id"]).to eq(models.last.id.to_s)
          end
        end
      end
    end
  end
end
