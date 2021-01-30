# frozen_string_literal: true

require "spec_helper"

describe "Index questions", type: :system do
  include_context "with a component"
  let(:manifest_name) { "questions" }

  context "when there are questions" do
    let!(:questions) { create_list(:question, 3, component: component) }

    it "doesn't display empty message" do
      visit_component

      expect(page).to have_no_content("There is no question yet")
    end
  end

  context "when there are no questions" do
    context "when there are no filters" do
      it "shows generic empty message" do
        visit_component

        expect(page).to have_content("There is no question yet")
      end
    end

    context "when there are filters" do
      let!(:questions) { create(:question, :with_answer, :accepted, component: component) }

      it "shows filters empty message" do
        visit_component

        uncheck "Accepted"

        expect(page).to have_content("There isn't any question with this criteria")
      end
    end
  end
end
