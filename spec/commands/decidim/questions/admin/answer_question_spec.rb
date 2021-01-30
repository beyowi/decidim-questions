# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Questions
    module Admin
      describe AnswerQuestion do
        subject { command.call }

        let(:command) { described_class.new(form, question) }
        let(:question) { create(:question) }
        let(:current_user) { create(:user, :admin) }
        let(:form) do
          QuestionAnswerForm.from_params(form_params).with_context(
            current_user: current_user,
            current_component: question.component,
            current_organization: question.component.organization
          )
        end

        let(:form_params) do
          {
            internal_state: "rejected",
            answer: { en: "Foo" },
            cost: 2000,
            cost_report: { en: "Cost report" },
            execution_period: { en: "Execution period" }
          }
        end

        it "broadcasts ok" do
          expect { subject }.to broadcast(:ok)
        end

        it "publish the question answer" do
          expect { subject }.to change { question.reload.published_state? } .to(true)
        end

        it "changes the question state" do
          expect { subject }.to change { question.reload.state } .to("rejected")
        end

        it "traces the action", versioning: true do
          expect(Decidim.traceability)
            .to receive(:perform_action!)
            .with("answer", question, form.current_user)
            .and_call_original

          expect { subject }.to change(Decidim::ActionLog, :count)
          action_log = Decidim::ActionLog.last
          expect(action_log.version).to be_present
          expect(action_log.version.event).to eq "update"
        end

        it "notifies the question answer" do
          expect(NotifyQuestionAnswer)
            .to receive(:call)
            .with(question, nil)

          subject
        end

        context "when the form is not valid" do
          before do
            expect(form).to receive(:invalid?).and_return(true)
          end

          it "broadcasts invalid" do
            expect { subject }.to broadcast(:invalid)
          end

          it "doesn't change the question state" do
            expect { subject }.not_to(change { question.reload.state })
          end
        end

        context "when applying over an already answered question" do
          let(:question) { create(:question, :accepted) }

          it "broadcasts ok" do
            expect { subject }.to broadcast(:ok)
          end

          it "changes the question state" do
            expect { subject }.to change { question.reload.state } .to("rejected")
          end

          it "notifies the question new answer" do
            expect(NotifyQuestionAnswer)
              .to receive(:call)
              .with(question, "accepted")

            subject
          end
        end

        context "when question answer should not be published immediately" do
          let(:question) { create(:question, component: component) }
          let(:component) { create(:question_component, :without_publish_answers_immediately) }

          it "broadcasts ok" do
            expect { subject }.to broadcast(:ok)
          end

          it "changes the question internal state" do
            expect { subject }.to change { question.reload.internal_state } .to("rejected")
          end

          it "doesn't publish the question answer" do
            expect { subject }.not_to change { question.reload.published_state? } .from(false)
          end

          it "doesn't notify the question answer" do
            expect(NotifyQuestionAnswer)
              .not_to receive(:call)

            subject
          end
        end
      end
    end
  end
end
