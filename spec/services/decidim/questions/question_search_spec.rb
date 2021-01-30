# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Questions
    describe QuestionSearch do
      let(:component) { create(:component, manifest_name: "questions") }
      let(:scope1) { create :scope, organization: component.organization }
      let(:scope2) { create :scope, organization: component.organization }
      let(:subscope1) { create :scope, organization: component.organization, parent: scope1 }
      let(:participatory_process) { component.participatory_space }
      let(:user) { create(:user, organization: component.organization) }
      let!(:question) { create(:question, component: component, scope: scope1) }

      describe "results" do
        subject do
          described_class.new(
            component: component,
            activity: activity,
            search_text: search_text,
            state: states,
            origin: origins,
            related_to: related_to,
            scope_id: scope_ids,
            category_id: category_ids,
            current_user: user
          ).results
        end

        let(:activity) { [] }
        let(:search_text) { nil }
        let(:origins) { nil }
        let(:related_to) { nil }
        let(:states) { nil }
        let(:scope_ids) { nil }
        let(:category_ids) { nil }

        it "only includes questions from the given component" do
          other_question = create(:question)

          expect(subject).to include(question)
          expect(subject).not_to include(other_question)
        end

        describe "search_text filter" do
          let(:search_text) { "dog" }

          it "returns the questions containing the search in the title or the body" do
            create_list(:question, 3, component: component)
            create(:question, title: "A dog", component: component)
            create(:question, body: "There is a dog in the office", component: component)

            expect(subject.size).to eq(2)
          end
        end

        describe "activity filter" do
          context "when filtering by supported" do
            let(:activity) { "voted" }

            it "returns the questions voted by the user" do
              create_list(:question, 3, component: component)
              create(:question_vote, question: Question.first, author: user)

              expect(subject.size).to eq(1)
            end
          end

          context "when filtering by my questions" do
            let(:activity) { "my_questions" }

            it "returns the questions created by the user" do
              create_list(:question, 3, component: component)
              create(:question, component: component, users: [user])

              expect(subject.size).to eq(1)
            end
          end
        end

        describe "origin filter" do
          context "when filtering official questions" do
            let(:origins) { %w(official) }

            it "returns only official questions" do
              official_questions = create_list(:question, 3, :official, component: component)
              create_list(:question, 3, component: component)

              expect(subject.size).to eq(3)
              expect(subject).to match_array(official_questions)
            end
          end

          context "when filtering citizen questions" do
            let(:origins) { %w(citizens) }
            let(:another_user) { create(:user, organization: component.organization) }

            it "returns only citizen questions" do
              create_list(:question, 3, :official, component: component)
              citizen_questions = create_list(:question, 2, component: component)
              question.add_coauthor(another_user)
              citizen_questions << question

              expect(subject.size).to eq(3)
              expect(subject).to match_array(citizen_questions)
            end
          end

          context "when filtering user groups questions" do
            let(:origins) { %w(user_group) }
            let(:user_group) { create :user_group, :verified, users: [user], organization: user.organization }

            it "returns only user groups questions" do
              create(:question, :official, component: component)
              user_group_question = create(:question, component: component)
              user_group_question.coauthorships.clear
              user_group_question.add_coauthor(user, user_group: user_group)

              expect(subject.size).to eq(1)
              expect(subject).to eq([user_group_question])
            end
          end

          context "when filtering meetings questions" do
            let(:origins) { %w(meeting) }
            let(:meeting) { create :meeting }

            it "returns only meeting questions" do
              create(:question, :official, component: component)
              meeting_question = create(:question, :official_meeting, component: component)

              expect(subject.size).to eq(1)
              expect(subject).to eq([meeting_question])
            end
          end
        end

        describe "state filter" do
          context "when filtering for default states" do
            it "returns all except withdrawn questions" do
              create_list(:question, 3, :withdrawn, component: component)
              other_questions = create_list(:question, 3, component: component)
              other_questions << question

              expect(subject.size).to eq(4)
              expect(subject).to match_array(other_questions)
            end
          end

          context "when filtering :except_rejected questions" do
            let(:states) { %w(accepted evaluating not_answered) }

            it "hides withdrawn and rejected questions" do
              create(:question, :withdrawn, component: component)
              create(:question, :rejected, component: component)
              accepted_question = create(:question, :accepted, component: component)

              expect(subject.size).to eq(2)
              expect(subject).to match_array([accepted_question, question])
            end
          end

          context "when filtering accepted questions" do
            let(:states) { %w(accepted) }

            it "returns only accepted questions" do
              accepted_questions = create_list(:question, 3, :accepted, component: component)
              create_list(:question, 3, component: component)

              expect(subject.size).to eq(3)
              expect(subject).to match_array(accepted_questions)
            end
          end

          context "when filtering rejected questions" do
            let(:states) { %w(rejected) }

            it "returns only rejected questions" do
              create_list(:question, 3, component: component)
              rejected_questions = create_list(:question, 3, :rejected, component: component)

              expect(subject.size).to eq(3)
              expect(subject).to match_array(rejected_questions)
            end
          end

          context "when filtering withdrawn questions" do
            let(:states) { %w(withdrawn) }

            it "returns only withdrawn questions" do
              create_list(:question, 3, component: component)
              withdrawn_questions = create_list(:question, 3, :withdrawn, component: component)

              expect(subject.size).to eq(3)
              expect(subject).to match_array(withdrawn_questions)
            end
          end
        end

        describe "scope_id filter" do
          let!(:question2) { create(:question, component: component, scope: scope2) }
          let!(:question3) { create(:question, component: component, scope: subscope1) }

          context "when a parent scope id is being sent" do
            let(:scope_ids) { [scope1.id] }

            it "filters questions by scope" do
              expect(subject).to match_array [question, question3]
            end
          end

          context "when a subscope id is being sent" do
            let(:scope_ids) { [subscope1.id] }

            it "filters questions by scope" do
              expect(subject).to eq [question3]
            end
          end

          context "when multiple ids are sent" do
            let(:scope_ids) { [scope2.id, scope1.id] }

            it "filters questions by scope" do
              expect(subject).to match_array [question, question2, question3]
            end
          end

          context "when `global` is being sent" do
            let!(:resource_without_scope) { create(:question, component: component, scope: nil) }
            let(:scope_ids) { ["global"] }

            it "returns questions without a scope" do
              expect(subject).to eq [resource_without_scope]
            end
          end

          context "when `global` and some ids is being sent" do
            let!(:resource_without_scope) { create(:question, component: component, scope: nil) }
            let(:scope_ids) { ["global", scope2.id, scope1.id] }

            it "returns questions without a scope and with selected scopes" do
              expect(subject).to match_array [resource_without_scope, question, question2, question3]
            end
          end
        end

        describe "category_id filter" do
          let(:category1) { create :category, participatory_space: participatory_process }
          let(:category2) { create :category, participatory_space: participatory_process }
          let(:child_category) { create :category, participatory_space: participatory_process, parent: category2 }
          let!(:question2) { create(:question, component: component, category: category1) }
          let!(:question3) { create(:question, component: component, category: category2) }
          let!(:question4) { create(:question, component: component, category: child_category) }

          context "when no category filter is present" do
            it "includes all questions" do
              expect(subject).to match_array [question, question2, question3, question4]
            end
          end

          context "when a category is selected" do
            let(:category_ids) { [category2.id] }

            it "includes only questions for that category and its children" do
              expect(subject).to match_array [question3, question4]
            end
          end

          context "when a subcategory is selected" do
            let(:category_ids) { [child_category.id] }

            it "includes only questions for that category" do
              expect(subject).to eq [question4]
            end
          end

          context "when `without` is being sent" do
            let(:category_ids) { ["without"] }

            it "returns questions without a category" do
              expect(subject).to eq [question]
            end
          end

          context "when `without` and some category id is being sent" do
            let(:category_ids) { ["without", category1.id] }

            it "returns questions without a category and with the selected category" do
              expect(subject).to match_array [question, question2]
            end
          end
        end

        describe "related_to filter" do
          context "when filtering by related to meetings" do
            let(:related_to) { "Decidim::Meetings::Meeting".underscore }
            let(:meetings_component) { create(:component, manifest_name: "meetings", participatory_space: participatory_process) }
            let(:meeting) { create :meeting, component: meetings_component }

            it "returns only questions related to meetings" do
              related_question = create(:question, :accepted, component: component)
              related_question2 = create(:question, :accepted, component: component)
              create_list(:question, 3, component: component)
              meeting.link_resources([related_question], "questions_from_meeting")
              related_question2.link_resources([meeting], "questions_from_meeting")

              expect(subject).to match_array([related_question, related_question2])
            end
          end

          context "when filtering by related to resources" do
            let(:related_to) { "Decidim::DummyResources::DummyResource".underscore }
            let(:dummy_component) { create(:component, manifest_name: "dummy", participatory_space: participatory_process) }
            let(:dummy_resource) { create :dummy_resource, component: dummy_component }

            it "returns only questions related to results" do
              related_question = create(:question, :accepted, component: component)
              related_question2 = create(:question, :accepted, component: component)
              create_list(:question, 3, component: component)
              dummy_resource.link_resources([related_question], "included_questions")
              related_question2.link_resources([dummy_resource], "included_questions")

              expect(subject).to match_array([related_question, related_question2])
            end
          end
        end
      end
    end
  end
end
