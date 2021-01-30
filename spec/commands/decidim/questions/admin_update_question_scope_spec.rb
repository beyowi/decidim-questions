# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Questions
    module Admin
      describe UpdateQuestionScope do
        describe "call" do
          let!(:question) { create :question }
          let!(:questions) { create_list(:question, 3, component: question.component) }
          let!(:scope_one) { create :scope, organization: question.organization }
          let!(:scope) { create :scope, organization: question.organization }

          context "with no scope" do
            it "broadcasts invalid_scope" do
              expect { described_class.call(nil, question.id) }.to broadcast(:invalid_scope)
            end
          end

          context "with no questions" do
            it "broadcasts invalid_question_ids" do
              expect { described_class.call(scope.id, nil) }.to broadcast(:invalid_question_ids)
            end
          end

          describe "with a scope and questions" do
            context "when the scope is the same as the question's scope" do
              before do
                question.update!(scope: scope)
              end

              it "doesn't update the question" do
                expect(question).not_to receive(:update!)
                described_class.call(question.scope.id, question.id)
              end
            end

            context "when the scope is diferent from the question's scope" do
              before do
                questions.each { |p| p.update!(scope: scope_one) }
              end

              it "broadcasts update_questions_scope" do
                expect { described_class.call(scope.id, questions.pluck(:id)) }.to broadcast(:update_questions_scope)
              end

              it "updates the question" do
                described_class.call(scope.id, question.id)

                expect(question.reload.scope).to eq(scope)
              end
            end
          end
        end
      end
    end
  end
end
