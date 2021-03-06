# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Questions
    describe QuestionSerializer do
      subject do
        described_class.new(question)
      end

      let!(:question) { create(:question, :accepted) }
      let!(:category) { create(:category, participatory_space: component.participatory_space) }
      let!(:scope) { create(:scope, organization: component.participatory_space.organization) }
      let(:participatory_process) { component.participatory_space }
      let(:component) { question.component }

      let!(:meetings_component) { create(:component, manifest_name: "meetings", participatory_space: participatory_process) }
      let(:meetings) { create_list(:meeting, 2, component: meetings_component) }

      let!(:questions_component) { create(:component, manifest_name: "questions", participatory_space: participatory_process) }
      let(:other_questions) { create_list(:question, 2, component: questions_component) }

      let(:expected_answer) do
        answer = question.answer
        Decidim.available_locales.each_with_object({}) do |locale, result|
          result[locale.to_s] = if answer.is_a?(Hash)
                                  answer[locale.to_s] || ""
                                else
                                  ""
                                end
        end
      end

      before do
        question.update!(category: category)
        question.update!(scope: scope)
        question.link_resources(meetings, "questions_from_meeting")
        question.link_resources(other_questions, "copied_from_component")
      end

      describe "#serialize" do
        let(:serialized) { subject.serialize }

        it "serializes the id" do
          expect(serialized).to include(id: question.id)
        end

        it "serializes the category" do
          expect(serialized[:category]).to include(id: category.id)
          expect(serialized[:category]).to include(name: category.name)
        end

        it "serializes the scope" do
          expect(serialized[:scope]).to include(id: scope.id)
          expect(serialized[:scope]).to include(name: scope.name)
        end

        it "serializes the title" do
          expect(serialized).to include(title: question.title)
        end

        it "serializes the body" do
          expect(serialized).to include(body: question.body)
        end

        it "serializes the amount of supports" do
          expect(serialized).to include(supports: question.question_votes_count)
        end

        it "serializes the amount of comments" do
          expect(serialized).to include(comments: question.comments.count)
        end

        it "serializes the date of creation" do
          expect(serialized).to include(published_at: question.published_at)
        end

        it "serializes the url" do
          expect(serialized[:url]).to include("http", question.id.to_s)
        end

        it "serializes the component" do
          expect(serialized[:component]).to include(id: question.component.id)
        end

        it "serializes the meetings" do
          expect(serialized[:meeting_urls].length).to eq(2)
          expect(serialized[:meeting_urls].first).to match(%r{http.*/meetings})
        end

        it "serializes the participatory space" do
          expect(serialized[:participatory_space]).to include(id: participatory_process.id)
          expect(serialized[:participatory_space][:url]).to include("http", participatory_process.slug)
        end

        it "serializes the state" do
          expect(serialized).to include(state: question.state)
        end

        it "serializes the reference" do
          expect(serialized).to include(reference: question.reference)
        end

        it "serializes the answer" do
          expect(serialized).to include(answer: expected_answer)
        end

        it "serializes the amount of attachments" do
          expect(serialized).to include(attachments: question.attachments.count)
        end

        it "serializes the endorsements" do
          expect(serialized[:endorsements]).to include(total_count: question.endorsements.count)
          expect(serialized[:endorsements]).to include(user_endorsements: question.endorsements.for_listing.map { |identity| identity.normalized_author&.name })
        end

        it "serializes related questions" do
          expect(serialized[:related_questions].length).to eq(2)
          expect(serialized[:related_questions].first).to match(%r{http.*/questions})
        end

        it "serializes if question is_amend" do
          expect(serialized).to include(is_amend: question.emendation?)
        end

        it "serializes the original question" do
          expect(serialized[:original_question]).to include(title: question&.amendable&.title)
          expect(serialized[:original_question][:url]).to be_nil || include("http", question.id.to_s)
        end

        context "with question having an answer" do
          let!(:question) { create(:question, :with_answer) }

          it "serializes the answer" do
            expect(serialized).to include(answer: expected_answer)
          end
        end
      end
    end
  end
end
