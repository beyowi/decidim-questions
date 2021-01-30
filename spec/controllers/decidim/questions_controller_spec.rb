# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Questions
    describe QuestionsController, type: :controller do
      routes { Decidim::Questions::Engine.routes }

      let(:user) { create(:user, :confirmed, organization: component.organization) }

      let(:question_params) do
        {
          component_id: component.id
        }
      end
      let(:params) { { question: question_params } }

      before do
        request.env["decidim.current_organization"] = component.organization
        request.env["decidim.current_participatory_space"] = component.participatory_space
        request.env["decidim.current_component"] = component
      end

      describe "GET index" do
        context "when participatory texts are disabled" do
          let(:component) { create(:question_component) }

          it "sorts questions by search defaults" do
            get :index
            expect(response).to have_http_status(:ok)
            expect(subject).to render_template(:index)
            expect(assigns(:questions).order_values).to eq(["RANDOM()"])
          end
        end

        context "when participatory texts are enabled" do
          let(:component) { create(:question_component, :with_participatory_texts_enabled) }

          it "sorts questions by position" do
            get :index
            expect(response).to have_http_status(:ok)
            expect(subject).to render_template(:participatory_text)
            expect(assigns(:questions).order_values.first.expr.name).to eq("position")
          end

          context "when emendations exist" do
            let!(:amendable) { create(:question, component: component) }
            let!(:emendation) { create(:question, component: component) }
            let!(:amendment) { create(:amendment, amendable: amendable, emendation: emendation, state: "accepted") }

            it "does not include emendations" do
              get :index
              expect(response).to have_http_status(:ok)
              emendations = assigns(:questions).select(&:emendation?)
              expect(emendations).to be_empty
            end
          end
        end
      end

      describe "GET new" do
        let(:component) { create(:question_component, :with_creation_enabled) }

        before { sign_in user }

        context "when NO draft questions exist" do
          it "renders the empty form" do
            get :new, params: params
            expect(response).to have_http_status(:ok)
            expect(subject).to render_template(:new)
          end
        end

        context "when draft questions exist from other users" do
          let!(:others_draft) { create(:question, :draft, component: component) }

          it "renders the empty form" do
            get :new, params: params
            expect(response).to have_http_status(:ok)
            expect(subject).to render_template(:new)
          end
        end
      end

      describe "POST create" do
        before { sign_in user }

        context "when creation is not enabled" do
          let(:component) { create(:question_component) }

          it "raises an error" do
            post :create, params: params

            expect(flash[:alert]).not_to be_empty
          end
        end

        context "when creation is enabled" do
          let(:component) { create(:question_component, :with_creation_enabled) }
          let(:question_params) do
            {
              component_id: component.id,
              title: "Lorem ipsum dolor sit amet, consectetur adipiscing elit",
              body: "Ut sed dolor vitae purus volutpat venenatis. Donec sit amet sagittis sapien. Curabitur rhoncus ullamcorper feugiat. Aliquam et magna metus."
            }
          end

          it "creates a question" do
            post :create, params: params

            expect(flash[:notice]).not_to be_empty
            expect(response).to have_http_status(:found)
          end
        end
      end

      describe "withdraw a question" do
        let(:component) { create(:question_component, :with_creation_enabled) }

        before { sign_in user }

        context "when an authorized user is withdrawing a question" do
          let(:question) { create(:question, component: component, users: [user]) }

          it "withdraws the question" do
            put :withdraw, params: params.merge(id: question.id)

            expect(flash[:notice]).to eq("Question successfully updated.")
            expect(response).to have_http_status(:found)
            question.reload
            expect(question.withdrawn?).to be true
          end

          context "and the question already has supports" do
            let(:question) { create(:question, :with_votes, component: component, users: [user]) }

            it "is not able to withdraw the question" do
              put :withdraw, params: params.merge(id: question.id)

              expect(flash[:alert]).to eq("This question can not be withdrawn because it already has supports.")
              expect(response).to have_http_status(:found)
              question.reload
              expect(question.withdrawn?).to be false
            end
          end
        end

        describe "when current user is NOT the author of the question" do
          let(:current_user) { create(:user, organization: component.organization) }
          let(:question) { create(:question, component: component, users: [current_user]) }

          context "and the question has no supports" do
            it "is not able to withdraw the question" do
              expect(WithdrawQuestion).not_to receive(:call)

              put :withdraw, params: params.merge(id: question.id)

              expect(flash[:alert]).to eq("You are not authorized to perform this action")
              expect(response).to have_http_status(:found)
              question.reload
              expect(question.withdrawn?).to be false
            end
          end
        end
      end

      describe "GET show" do
        let!(:component) { create(:question_component, :with_amendments_enabled) }
        let!(:amendable) { create(:question, component: component) }
        let!(:emendation) { create(:question, component: component) }
        let!(:amendment) { create(:amendment, amendable: amendable, emendation: emendation) }
        let(:active_step_id) { component.participatory_space.active_step.id }

        context "when the question is an amendable" do
          it "shows the question" do
            get :show, params: params.merge(id: amendable.id)
            expect(response).to have_http_status(:ok)
            expect(subject).to render_template(:show)
          end

          context "and the user is not logged in" do
            it "shows the question" do
              get :show, params: params.merge(id: amendable.id)
              expect(response).to have_http_status(:ok)
              expect(subject).to render_template(:show)
            end
          end
        end

        context "when the question is an emendation" do
          context "and amendments VISIBILITY is set to 'participants'" do
            before do
              component.update!(step_settings: { active_step_id => { amendments_visibility: "participants" } })
            end

            context "when the user is not logged in" do
              it "redirects to 404" do
                expect do
                  get :show, params: params.merge(id: emendation.id)
                end.to raise_error(ActionController::RoutingError)
              end
            end

            context "when the user is logged in" do
              before { sign_in user }

              context "and the user is the author of the emendation" do
                let(:user) { amendment.amender }

                it "shows the question" do
                  get :show, params: params.merge(id: emendation.id)
                  expect(response).to have_http_status(:ok)
                  expect(subject).to render_template(:show)
                end
              end

              context "and is NOT the author of the emendation" do
                it "redirects to 404" do
                  expect do
                    get :show, params: params.merge(id: emendation.id)
                  end.to raise_error(ActionController::RoutingError)
                end

                context "when the user is an admin" do
                  let(:user) { create(:user, :admin, :confirmed, organization: component.organization) }

                  it "shows the question" do
                    get :show, params: params.merge(id: emendation.id)
                    expect(response).to have_http_status(:ok)
                    expect(subject).to render_template(:show)
                  end
                end
              end
            end
          end

          context "and amendments VISIBILITY is set to 'all'" do
            before do
              component.update!(step_settings: { active_step_id => { amendments_visibility: "all" } })
            end

            context "when the user is not logged in" do
              it "shows the question" do
                get :show, params: params.merge(id: emendation.id)
                expect(response).to have_http_status(:ok)
                expect(subject).to render_template(:show)
              end
            end

            context "when the user is logged in" do
              before { sign_in user }

              context "and is NOT the author of the emendation" do
                it "shows the question" do
                  get :show, params: params.merge(id: emendation.id)
                  expect(response).to have_http_status(:ok)
                  expect(subject).to render_template(:show)
                end
              end
            end
          end
        end
      end
    end
  end
end
