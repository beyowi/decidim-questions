# frozen_string_literal: true

require "spec_helper"

describe "show", type: :system do
  include_context "with a component"
  let(:manifest_name) { "questions" }

  let!(:question) { create(:question, component: component) }

  before do
    visit_component
    click_link question.title[I18n.locale.to_s], class: "card__link"
  end

  context "when shows the question component" do
    it "shows the question title" do
      expect(page).to have_content question.title[I18n.locale.to_s]
    end

    it_behaves_like "going back to list button"
  end
end
