# frozen_string_literal: true

require "spec_helper"
require "decidim/api/test/type_context"
require "decidim/core/test"
require "decidim/core/test/shared_examples/input_filter_examples"

module Decidim
  module Questions
    describe QuestionInputFilter, type: :graphql do
      include_context "with a graphql type"
      let(:type_class) { Decidim::Questions::QuestionsType }

      let(:model) { create(:question_component) }
      let!(:models) { create_list(:question, 3, :published, component: model) }

      context "when filtered by published_at" do
        include_examples "connection has before/since input filter", "questions", "published"
      end
    end
  end
end
