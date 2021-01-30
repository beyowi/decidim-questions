# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Questions
    module Admin
      describe NotifyQuestionAnswer do
        subject { command.call }

        let(:command) { described_class.new(question, initial_state) }
        let(:question) { create(:question, :accepted) }
        let(:initial_state) { nil }
        let(:current_user) { create(:user, :admin) }
        let(:follow) { create(:follow, followable: question, user: follower) }
        let(:follower) { create(:user, organization: question.organization) }

        before do
          follow

          # give question author initial points to avoid unwanted events during tests
          Decidim::Gamification.increment_score(question.creator_author, :accepted_questions)
        end

        it "broadcasts ok" do
          expect { subject }.to broadcast(:ok)
        end

        it "notifies the question followers" do
          expect(Decidim::EventsManager)
            .to receive(:publish)
            .with(
              event: "decidim.events.questions.question_accepted",
              event_class: Decidim::Questions::AcceptedQuestionEvent,
              resource: question,
              affected_users: match_array([question.creator_author]),
              followers: match_array([follower])
            )

          subject
        end

        it "increments the accepted questions counter" do
          expect { subject }.to change { Gamification.status_for(question.creator_author, :accepted_questions).score } .by(1)
        end

        context "when the question is rejected after being accepted" do
          let(:question) { create(:question, :rejected) }
          let(:initial_state) { "accepted" }

          it "broadcasts ok" do
            expect { subject }.to broadcast(:ok)
          end

          it "notifies the question followers" do
            expect(Decidim::EventsManager)
              .to receive(:publish)
              .with(
                event: "decidim.events.questions.question_rejected",
                event_class: Decidim::Questions::RejectedQuestionEvent,
                resource: question,
                affected_users: match_array([question.creator_author]),
                followers: match_array([follower])
              )

            subject
          end

          it "decrements the accepted questions counter" do
            expect { subject }.to change { Gamification.status_for(question.coauthorships.first.author, :accepted_questions).score } .by(-1)
          end
        end

        context "when the question published state has not changed" do
          let(:initial_state) { "accepted" }

          it "broadcasts ok" do
            expect { command.call }.to broadcast(:ok)
          end

          it "doesn't notify the question followers" do
            expect(Decidim::EventsManager)
              .not_to receive(:publish)

            subject
          end

          it "doesn't modify the accepted questions counter" do
            expect { subject }.not_to(change { Gamification.status_for(current_user, :accepted_questions).score })
          end
        end
      end
    end
  end
end
