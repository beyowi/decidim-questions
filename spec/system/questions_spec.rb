# frozen_string_literal: true

require "spec_helper"

describe "Questions", type: :system do
  include ActionView::Helpers::TextHelper
  include_context "with a component"
  let(:manifest_name) { "questions" }

  let!(:category) { create :category, participatory_space: participatory_process }
  let!(:scope) { create :scope, organization: organization }
  let!(:user) { create :user, :confirmed, organization: organization }
  let(:scoped_participatory_process) { create(:participatory_process, :with_steps, organization: organization, scope: scope) }

  let(:address) { "Carrer Pare Llaurador 113, baixos, 08224 Terrassa" }
  let(:latitude) { 40.1234 }
  let(:longitude) { 2.1234 }

  before do
    stub_geocoding(address, [latitude, longitude])
  end

  matcher :have_author do |name|
    match { |node| node.has_selector?(".author-data", text: name) }
    match_when_negated { |node| node.has_no_selector?(".author-data", text: name) }
  end

  matcher :have_creation_date do |date|
    match { |node| node.has_selector?(".author-data__extra", text: date) }
    match_when_negated { |node| node.has_no_selector?(".author-data__extra", text: date) }
  end

  context "when viewing a single question" do
    let!(:component) do
      create(:question_component,
             manifest: manifest,
             participatory_space: participatory_process)
    end

    let!(:questions) { create_list(:question, 3, component: component) }

    it "allows viewing a single question" do
      question = questions.first

      visit_component

      click_link question.title

      expect(page).to have_content(question.title)
      expect(page).to have_content(strip_tags(question.body).strip)
      expect(page).to have_author(question.creator_author.name)
      expect(page).to have_content(question.reference)
      expect(page).to have_creation_date(I18n.l(question.published_at, format: :decidim_short))
    end

    context "when process is not related to any scope" do
      let!(:question) { create(:question, component: component, scope: scope) }

      it "can be filtered by scope" do
        visit_component
        click_link question.title
        expect(page).to have_content(translated(scope.name))
      end
    end

    context "when process is related to a child scope" do
      let!(:question) { create(:question, component: component, scope: scope) }
      let(:participatory_process) { scoped_participatory_process }

      it "does not show the scope name" do
        visit_component
        click_link question.title
        expect(page).to have_no_content(translated(scope.name))
      end
    end

    context "when it is an official question" do
      let(:content) { generate_localized_title }
      let!(:official_question) { create(:question, :official, body: content, component: component) }

      before do
        visit_component
        click_link official_question.title
      end

      it "shows the author as official" do
        expect(page).to have_content("Official question")
      end

      it_behaves_like "rendering safe content", ".columns.mediumlarge-8.large-9"
    end

    context "when rich text editor is enabled for participants" do
      let!(:question) { create(:question, body: content, component: component) }

      before do
        organization.update(rich_text_editor_in_public_views: true)
        visit_component
        click_link question.title
      end

      it_behaves_like "rendering safe content", ".columns.mediumlarge-8.large-9"
    end

    context "when rich text editor is NOT enabled for participants" do
      let!(:question) { create(:question, body: content, component: component) }

      before do
        visit_component
        click_link question.title
      end

      it_behaves_like "rendering unsafe content", ".columns.mediumlarge-8.large-9"
    end

    context "when it is a question with card image enabled" do
      let!(:component) do
        create(:question_component,
               :with_card_image_allowed,
               manifest: manifest,
               participatory_space: participatory_process)
      end

      let!(:question) { create(:question, component: component) }
      let!(:image) { create(:attachment, attached_to: question) }

      it "shows the card image" do
        visit_component
        within "#question_#{question.id}" do
          expect(page).to have_selector(".card__image")
        end
      end
    end

    context "when it is an official meeting question" do
      include_context "with rich text editor content"
      let!(:question) { create(:question, :official_meeting, body: content, component: component) }

      before do
        visit_component
        click_link question.title
      end

      it "shows the author as meeting" do
        expect(page).to have_content(translated(question.authors.first.title))
      end

      it_behaves_like "rendering safe content", ".columns.mediumlarge-8.large-9"
    end

    context "when a question has comments" do
      let(:question) { create(:question, component: component) }
      let(:author) { create(:user, :confirmed, organization: component.organization) }
      let!(:comments) { create_list(:comment, 3, commentable: question) }

      it "shows the comments" do
        visit_component
        click_link question.title

        comments.each do |comment|
          expect(page).to have_content(comment.body)
        end
      end
    end

    context "when a question has costs" do
      let!(:question) do
        create(
          :question,
          :accepted,
          :with_answer,
          component: component,
          cost: 20_000,
          cost_report: { en: "My cost report" },
          execution_period: { en: "My execution period" }
        )
      end
      let!(:author) { create(:user, :confirmed, organization: component.organization) }

      it "shows the costs" do
        component.update!(
          step_settings: {
            component.participatory_space.active_step.id => {
              answers_with_costs: true
            }
          }
        )

        visit_component
        click_link question.title

        expect(page).to have_content("20,000.00")
        expect(page).to have_content("MY EXECUTION PERIOD")
        expect(page).to have_content("My cost report")
      end
    end

    context "when a question has been linked in a meeting" do
      let(:question) { create(:question, component: component) }
      let(:meeting_component) do
        create(:component, manifest_name: :meetings, participatory_space: question.component.participatory_space)
      end
      let(:meeting) { create(:meeting, component: meeting_component) }

      before do
        meeting.link_resources([question], "questions_from_meeting")
      end

      it "shows related meetings" do
        visit_component
        click_link question.title

        expect(page).to have_i18n_content(meeting.title)
      end
    end

    context "when a question has been linked in a result" do
      let(:question) { create(:question, component: component) }
      let(:accountability_component) do
        create(:component, manifest_name: :accountability, participatory_space: question.component.participatory_space)
      end
      let(:result) { create(:result, component: accountability_component) }

      before do
        result.link_resources([question], "included_questions")
      end

      it "shows related resources" do
        visit_component
        click_link question.title

        expect(page).to have_i18n_content(result.title)
      end
    end

    context "when a question is in evaluation" do
      let!(:question) { create(:question, :with_answer, :evaluating, component: component) }

      it "shows a badge and an answer" do
        visit_component
        click_link question.title

        expect(page).to have_content("Evaluating")

        within ".callout.warning" do
          expect(page).to have_content("This question is being evaluated")
          expect(page).to have_i18n_content(question.answer)
        end
      end
    end

    context "when a question has been rejected" do
      let!(:question) { create(:question, :with_answer, :rejected, component: component) }

      it "shows the rejection reason" do
        visit_component
        uncheck "Accepted"
        uncheck "Evaluating"
        uncheck "Not answered"
        page.find_link(question.title, wait: 30)
        click_link question.title

        expect(page).to have_content("Rejected")

        within ".callout.alert" do
          expect(page).to have_content("This question has been rejected")
          expect(page).to have_i18n_content(question.answer)
        end
      end
    end

    context "when a question has been accepted" do
      let!(:question) { create(:question, :with_answer, :accepted, component: component) }

      it "shows the acceptance reason" do
        visit_component
        click_link question.title

        expect(page).to have_content("Accepted")

        within ".callout.success" do
          expect(page).to have_content("This question has been accepted")
          expect(page).to have_i18n_content(question.answer)
        end
      end
    end

    context "when the question answer has not been published" do
      let!(:question) { create(:question, :accepted_not_published, component: component) }

      it "shows the acceptance reason" do
        visit_component
        click_link question.title

        expect(page).not_to have_content("Accepted")
        expect(page).not_to have_content("This question has been accepted")
        expect(page).not_to have_i18n_content(question.answer)
      end
    end

    context "when the questions'a author account has been deleted" do
      let(:question) { questions.first }

      before do
        Decidim::DestroyAccount.call(question.creator_author, Decidim::DeleteAccountForm.from_params({}))
      end

      it "the user is displayed as a deleted user" do
        visit_component

        click_link question.title

        expect(page).to have_content("Participant deleted")
      end
    end
  end

  context "when a question has been linked in a project" do
    let(:component) do
      create(:question_component,
             manifest: manifest,
             participatory_space: participatory_process)
    end
    let(:question) { create(:question, component: component) }
    let(:budget_component) do
      create(:component, manifest_name: :budgets, participatory_space: question.component.participatory_space)
    end
    let(:project) { create(:project, component: budget_component) }

    before do
      project.link_resources([question], "included_questions")
    end

    it "shows related projects" do
      visit_component
      click_link question.title

      expect(page).to have_i18n_content(project.title)
    end
  end

  context "when listing questions in a participatory process" do
    shared_examples_for "a random question ordering" do
      let!(:lucky_question) { create(:question, component: component) }
      let!(:unlucky_question) { create(:question, component: component) }

      it "lists the questions ordered randomly by default" do
        visit_component

        expect(page).to have_selector("a", text: "Random")
        expect(page).to have_selector(".card--question", count: 2)
        expect(page).to have_selector(".card--question", text: lucky_question.title)
        expect(page).to have_selector(".card--question", text: unlucky_question.title)
        expect(page).to have_author(lucky_question.creator_author.name)
      end
    end

    it "lists all the questions" do
      create(:question_component,
             manifest: manifest,
             participatory_space: participatory_process)

      create_list(:question, 3, component: component)

      visit_component
      expect(page).to have_css(".card--question", count: 3)
    end

    describe "editable content" do
      it_behaves_like "editable content for admins" do
        let(:target_path) { main_component_path(component) }
      end
    end

    context "when comments have been moderated" do
      let(:question) { create(:question, component: component) }
      let(:author) { create(:user, :confirmed, organization: component.organization) }
      let!(:comments) { create_list(:comment, 3, commentable: question) }
      let!(:moderation) { create :moderation, reportable: comments.first, hidden_at: 1.day.ago }

      it "displays unhidden comments count" do
        visit_component

        within("#question_#{question.id}") do
          within(".card-data__item:last-child") do
            expect(page).to have_content(2)
          end
        end
      end
    end

    describe "default ordering" do
      it_behaves_like "a random question ordering"
    end

    context "when voting phase is over" do
      let!(:component) do
        create(:question_component,
               :with_votes_blocked,
               manifest: manifest,
               participatory_space: participatory_process)
      end

      let!(:most_voted_question) do
        question = create(:question, component: component)
        create_list(:question_vote, 3, question: question)
        question
      end

      let!(:less_voted_question) { create(:question, component: component) }

      before { visit_component }

      it "lists the questions ordered by votes by default" do
        expect(page).to have_selector("a", text: "Most supported")
        expect(page).to have_selector("#questions .card-grid .column:first-child", text: most_voted_question.title)
        expect(page).to have_selector("#questions .card-grid .column:last-child", text: less_voted_question.title)
      end

      it "shows a disabled vote button for each question, but no links to full questions" do
        expect(page).to have_button("Supports disabled", disabled: true, count: 2)
        expect(page).to have_no_link("View question")
      end
    end

    context "when voting is disabled" do
      let!(:component) do
        create(:question_component,
               :with_votes_disabled,
               manifest: manifest,
               participatory_space: participatory_process)
      end

      describe "order" do
        it_behaves_like "a random question ordering"
      end

      it "shows only links to full questions" do
        create_list(:question, 2, component: component)

        visit_component

        expect(page).to have_no_button("Supports disabled", disabled: true)
        expect(page).to have_no_button("Vote")
        expect(page).to have_link("View question", count: 2)
      end
    end

    context "when there are a lot of questions" do
      before do
        create_list(:question, Decidim::Paginable::OPTIONS.first + 5, component: component)
      end

      it "paginates them" do
        visit_component

        expect(page).to have_css(".card--question", count: Decidim::Paginable::OPTIONS.first)

        click_link "Next"

        expect(page).to have_selector(".pagination .current", text: "2")

        expect(page).to have_css(".card--question", count: 5)
      end
    end

    shared_examples "ordering questions by selected option" do |selected_option|
      before do
        visit_component
        within ".order-by" do
          expect(page).to have_selector("ul[data-dropdown-menu$=dropdown-menu]", text: "Random")
          page.find("a", text: "Random").click
          click_link(selected_option)
        end
      end

      it "lists the questions ordered by selected option" do
        expect(page).to have_selector("#questions .card-grid .column:first-child", text: first_question.title)
        expect(page).to have_selector("#questions .card-grid .column:last-child", text: last_question.title)
      end
    end

    context "when ordering by 'most_voted'" do
      let!(:component) do
        create(:question_component,
               :with_votes_enabled,
               manifest: manifest,
               participatory_space: participatory_process)
      end
      let!(:most_voted_question) { create(:question, component: component) }
      let!(:votes) { create_list(:question_vote, 3, question: most_voted_question) }
      let!(:less_voted_question) { create(:question, component: component) }

      it_behaves_like "ordering questions by selected option", "Most supported" do
        let(:first_question) { most_voted_question }
        let(:last_question) { less_voted_question }
      end
    end

    context "when ordering by 'recent'" do
      let!(:older_question) { create(:question, component: component, created_at: 1.month.ago) }
      let!(:recent_question) { create(:question, component: component) }

      it_behaves_like "ordering questions by selected option", "Recent" do
        let(:first_question) { recent_question }
        let(:last_question) { older_question }
      end
    end

    context "when ordering by 'most_followed'" do
      let!(:most_followed_question) { create(:question, component: component) }
      let!(:follows) { create_list(:follow, 3, followable: most_followed_question) }
      let!(:less_followed_question) { create(:question, component: component) }

      it_behaves_like "ordering questions by selected option", "Most followed" do
        let(:first_question) { most_followed_question }
        let(:last_question) { less_followed_question }
      end
    end

    context "when ordering by 'most_commented'" do
      let!(:most_commented_question) { create(:question, component: component, created_at: 1.month.ago) }
      let!(:comments) { create_list(:comment, 3, commentable: most_commented_question) }
      let!(:less_commented_question) { create(:question, component: component) }

      it_behaves_like "ordering questions by selected option", "Most commented" do
        let(:first_question) { most_commented_question }
        let(:last_question) { less_commented_question }
      end
    end

    context "when ordering by 'most_endorsed'" do
      let!(:most_endorsed_question) { create(:question, component: component, created_at: 1.month.ago) }
      let!(:endorsements) do
        3.times.collect do
          create(:endorsement, resource: most_endorsed_question, author: build(:user, organization: organization))
        end
      end
      let!(:less_endorsed_question) { create(:question, component: component) }

      it_behaves_like "ordering questions by selected option", "Most endorsed" do
        let(:first_question) { most_endorsed_question }
        let(:last_question) { less_endorsed_question }
      end
    end

    context "when ordering by 'with_more_authors'" do
      let!(:most_authored_question) { create(:question, component: component, created_at: 1.month.ago) }
      let!(:coauthorships) { create_list(:coauthorship, 3, coauthorable: most_authored_question) }
      let!(:less_authored_question) { create(:question, component: component) }

      it_behaves_like "ordering questions by selected option", "With more authors" do
        let(:first_question) { most_authored_question }
        let(:last_question) { less_authored_question }
      end
    end

    context "when paginating" do
      let!(:collection) { create_list :question, collection_size, component: component }
      let!(:resource_selector) { ".card--question" }

      it_behaves_like "a paginated resource"
    end

    context "when component is not commentable" do
      let!(:ressources) { create_list(:question, 3, component: component) }

      it_behaves_like "an uncommentable component"
    end
  end
end
