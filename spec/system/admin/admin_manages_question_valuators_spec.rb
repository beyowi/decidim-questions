# frozen_string_literal: true

require "spec_helper"

describe "Admin manages questions valuators", type: :system do
  let(:manifest_name) { "questions" }
  let!(:question) { create :question, component: current_component }
  let!(:reportables) { create_list(:question, 3, component: current_component) }
  let(:participatory_process) { create(:participatory_process, :with_steps, organization: organization) }
  let(:participatory_space_path) do
    decidim_admin_participatory_processes.edit_participatory_process_path(participatory_process)
  end
  let!(:valuator) { create :user, organization: organization }
  let!(:valuator_role) { create :participatory_process_user_role, role: :valuator, user: valuator, participatory_process: participatory_process }

  include Decidim::ComponentPathHelper

  include_context "when managing a component as an admin"

  context "when assigning to a valuator" do
    before do
      visit current_path

      within find("tr", text: question.title) do
        page.first(".js-question-list-check").set(true)
      end

      click_button "Actions"
      click_button "Assign to valuator"
    end

    it "shows the component select" do
      expect(page).to have_css("#js-form-assign-questions-to-valuator select", count: 1)
    end

    it "shows an update button" do
      expect(page).to have_css("button#js-submit-assign-questions-to-valuator", count: 1)
    end

    context "when submitting the form" do
      before do
        within "#js-form-assign-questions-to-valuator" do
          select valuator.name, from: :valuator_role_id
          page.find("button#js-submit-assign-questions-to-valuator").click
        end
      end

      it "assigns the questions to the valuator" do
        expect(page).to have_content("Questions assigned to a valuator successfully")

        within find("tr", text: question.title) do
          expect(page).to have_selector("td.valuators-count", text: 1)
        end
      end
    end
  end

  context "when filtering questions by assigned valuator" do
    let!(:unassigned_question) { create :question, component: component }
    let(:assigned_question) { question }

    before do
      create :valuation_assignment, question: question, valuator_role: valuator_role

      visit current_path
    end

    it "only shows the questions assigned to the selected valuator" do
      expect(page).to have_content(assigned_question.title)
      expect(page).to have_content(unassigned_question.title)

      within ".filters__section" do
        find("a.dropdown", text: "Filter").hover
        find("a", text: "Assigned to valuator").hover
        find("a", text: valuator.name).click
      end

      expect(page).to have_content(assigned_question.title)
      expect(page).to have_no_content(unassigned_question.title)
    end
  end

  context "when unassigning valuators from a question from the questions index page" do
    let(:assigned_question) { question }

    before do
      create :valuation_assignment, question: question, valuator_role: valuator_role

      visit current_path

      within find("tr", text: question.title) do
        page.first(".js-question-list-check").set(true)
      end

      click_button "Actions"
      click_button "Unassign from valuator"
    end

    it "shows the component select" do
      expect(page).to have_css("#js-form-unassign-questions-from-valuator select", count: 1)
    end

    it "shows an update button" do
      expect(page).to have_css("button#js-submit-unassign-questions-from-valuator", count: 1)
    end

    context "when submitting the form" do
      before do
        within "#js-form-unassign-questions-from-valuator" do
          select valuator.name, from: :valuator_role_id
          page.find("button#js-submit-unassign-questions-from-valuator").click
        end
      end

      it "unassigns the questions to the valuator" do
        expect(page).to have_content("Valuator unassigned from questions successfully")

        within find("tr", text: question.title) do
          expect(page).to have_selector("td.valuators-count", text: 0)
        end
      end
    end
  end

  context "when unassigning valuators from a question from the question show page" do
    let(:assigned_question) { question }

    before do
      create :valuation_assignment, question: question, valuator_role: valuator_role

      visit current_path

      find("a", text: question.title).click
    end

    it "can unassign a valuator" do
      within "#valuators" do
        expect(page).to have_content(valuator.name)

        accept_confirm do
          find("a.red-icon").click
        end
      end

      expect(page).to have_content("Valuator unassigned from questions successfully")

      expect(page).to have_no_selector("#valuators")
    end
  end
end
