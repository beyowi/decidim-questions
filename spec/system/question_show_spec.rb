# frozen_string_literal: true

require "spec_helper"

describe "Show a Question", type: :system do
  include_context "with a component"
  let(:manifest_name) { "questions" }
  let(:question) { create :question, component: component }

  def visit_question
    visit resource_locator(question).path
  end

  describe "question show" do
    it_behaves_like "editable content for admins" do
      let(:target_path) { resource_locator(question).path }
    end

    context "when requesting the question path" do
      before do
        visit_question
      end

      describe "extra admin link" do
        before do
          login_as user, scope: :user
          visit current_path
        end

        context "when I'm an admin user" do
          let(:user) { create(:user, :admin, :confirmed, organization: organization) }

          it "has a link to answer to the question at the admin" do
            within ".topbar" do
              expect(page).to have_link("Answer", href: /.*admin.*question-answer.*/)
            end
          end
        end

        context "when I'm a regular user" do
          let(:user) { create(:user, :confirmed, organization: organization) }

          it "does not have a link to answer the question at the admin" do
            within ".topbar" do
              expect(page).not_to have_link("Answer")
            end
          end
        end
      end
    end
  end
end
