# frozen_string_literal: true

require "spec_helper"

describe "Questions", type: :system do
  include_context "with a component"
  let(:manifest_name) { "questions" }
  let!(:user) { create :user, :confirmed, organization: organization }
  let!(:component) do
    create(:question_component,
           :with_creation_enabled,
           manifest: manifest,
           participatory_space: participatory_process)
  end

  before do
    login_as user, scope: :user
  end

  context "when creating a new question" do
    before do
      login_as user, scope: :user
      visit_component
    end

    context "and draft question exists for current users" do
      let!(:draft) { create(:question, :draft, component: component, users: [user]) }

      it "redirects to edit draft" do
        click_link "New question"
        path = "#{main_component_path(component)}questions/#{draft.id}/edit_draft?component_id=#{component.id}&question_slug=#{component.participatory_space.slug}"
        expect(page).to have_current_path(path)
      end
    end

    context "when rich text editor is enabled for participants" do
      before do
        organization.update(rich_text_editor_in_public_views: true)
        click_link "New question"
      end

      it_behaves_like "having a rich text editor", "new_question", "basic"

      it "has helper character counter" do
        within "form.new_question" do
          expect(find(".editor").sibling(".form-input-extra-before")).to have_content("at least 15 characters", count: 1)
        end
      end
    end
  end
end
