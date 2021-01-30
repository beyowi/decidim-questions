# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Questions
    module Admin
      describe CreateQuestionNote do
        describe "call" do
          let(:question) { create(:question) }
          let(:organization) { question.component.organization }
          let(:current_user) { create(:user, :admin, organization: organization) }
          let!(:another_admin) { create(:user, :admin, organization: organization) }
          let(:valuation_assignment) { create(:valuation_assignment, question: question) }
          let!(:valuator) { valuation_assignment.valuator }
          let(:form) { QuestionNoteForm.from_params(form_params).with_context(current_user: current_user, current_organization: organization) }

          let(:form_params) do
            {
              body: "A reasonable private note"
            }
          end

          let(:command) { described_class.new(form, question) }

          describe "when the form is not valid" do
            before do
              expect(form).to receive(:invalid?).and_return(true)
            end

            it "broadcasts invalid" do
              expect { command.call }.to broadcast(:invalid)
            end

            it "doesn't create the question note" do
              expect do
                command.call
              end.to change(QuestionVote, :count).by(0)
            end
          end

          describe "when the form is valid" do
            before do
              expect(form).to receive(:invalid?).and_return(false)
            end

            it "broadcasts ok" do
              expect { command.call }.to broadcast(:ok)
            end

            it "creates the question notes" do
              expect do
                command.call
              end.to change(QuestionNote, :count).by(1)
            end

            it "traces the action", versioning: true do
              expect(Decidim.traceability)
                .to receive(:create!)
                .with(QuestionNote, current_user, hash_including(:body, :question, :author), resource: hash_including(:title))
                .and_call_original

              expect { command.call }.to change(ActionLog, :count)
              action_log = Decidim::ActionLog.last
              expect(action_log.version).to be_present
            end

            it "notifies the admins and the valuators" do
              expect(Decidim::EventsManager)
                .to receive(:publish)
                .once
                .ordered
                .with(
                  event: "decidim.events.questions.admin.question_note_created",
                  event_class: Decidim::Questions::Admin::QuestionNoteCreatedEvent,
                  resource: question,
                  affected_users: a_collection_containing_exactly(another_admin, valuator)
                )

              command.call
            end
          end
        end
      end
    end
  end
end
