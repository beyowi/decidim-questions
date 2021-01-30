# frozen_string_literal: true

require "spec_helper"

describe Decidim::Questions::Admin::Permissions do
  subject { described_class.new(user, permission_action, context).permissions.allowed? }

  let(:user) { build :user, :admin }
  let(:current_component) { create(:question_component) }
  let(:question) { nil }
  let(:extra_context) { {} }
  let(:context) do
    {
      question: question,
      current_component: current_component,
      current_settings: current_settings,
      component_settings: component_settings
    }.merge(extra_context)
  end
  let(:component_settings) do
    double(
      official_questions_enabled: official_questions_enabled?,
      question_answering_enabled: component_settings_question_answering_enabled?,
      participatory_texts_enabled?: component_settings_participatory_texts_enabled?
    )
  end
  let(:current_settings) do
    double(
      creation_enabled?: creation_enabled?,
      question_answering_enabled: current_settings_question_answering_enabled?,
      publish_answers_immediately: current_settings_publish_answers_immediately?
    )
  end
  let(:creation_enabled?) { true }
  let(:official_questions_enabled?) { true }
  let(:component_settings_question_answering_enabled?) { true }
  let(:component_settings_participatory_texts_enabled?) { true }
  let(:current_settings_question_answering_enabled?) { true }
  let(:current_settings_publish_answers_immediately?) { true }
  let(:permission_action) { Decidim::PermissionAction.new(action) }

  shared_examples "can create question notes" do
    describe "question note creation" do
      let(:action) do
        { scope: :admin, action: :create, subject: :question_note }
      end

      context "when the space allows it" do
        it { is_expected.to eq true }
      end
    end
  end

  shared_examples "can answer questions" do
    describe "question answering" do
      let(:action) do
        { scope: :admin, action: :create, subject: :question_answer }
      end

      context "when everything is OK" do
        it { is_expected.to eq true }
      end

      context "when answering is disabled in the step level" do
        let(:current_settings_question_answering_enabled?) { false }

        it { is_expected.to eq false }
      end

      context "when answering is disabled in the component level" do
        let(:component_settings_question_answering_enabled?) { false }

        it { is_expected.to eq false }
      end
    end
  end

  shared_examples "can export questions" do
    describe "export questions" do
      let(:action) do
        { scope: :admin, action: :export, subject: :questions }
      end

      context "when everything is OK" do
        it { is_expected.to eq true }
      end
    end
  end

  context "when user is a valuator" do
    let(:organization) { space.organization }
    let(:space) { current_component.participatory_space }
    let!(:valuator_role) { create :participatory_process_user_role, user: user, role: :valuator, participatory_process: space }
    let!(:user) { create :user, organization: organization }

    context "and can valuate the current question" do
      let(:question) { create :question, component: current_component }
      let!(:assignment) { create :valuation_assignment, question: question, valuator_role: valuator_role }

      it_behaves_like "can create question notes"
      it_behaves_like "can answer questions"
      it_behaves_like "can export questions"
    end

    context "when current user is the valuator" do
      describe "unassign questions from themselves" do
        let(:action) do
          { scope: :admin, action: :unassign_from_valuator, subject: :questions }
        end
        let(:extra_context) { { valuator: user } }

        it { is_expected.to eq true }
      end
    end
  end

  it_behaves_like "can create question notes"
  it_behaves_like "can answer questions"
  it_behaves_like "can export questions"

  describe "question creation" do
    let(:action) do
      { scope: :admin, action: :create, subject: :question }
    end

    context "when everything is OK" do
      it { is_expected.to eq true }
    end

    context "when creation is disabled" do
      let(:creation_enabled?) { false }

      it { is_expected.to eq false }
    end

    context "when official questions are disabled" do
      let(:official_questions_enabled?) { false }

      it { is_expected.to eq false }
    end
  end

  describe "question edition" do
    let(:action) do
      { scope: :admin, action: :edit, subject: :question }
    end

    context "when the question is not official" do
      let(:question) { create :question, component: current_component }

      it_behaves_like "permission is not set"
    end

    context "when the question is official" do
      let(:question) { create :question, :official, component: current_component }

      context "when everything is OK" do
        it { is_expected.to eq true }
      end

      context "when it has some votes" do
        before do
          create :question_vote, question: question
        end

        it_behaves_like "permission is not set"
      end
    end
  end

  describe "update question category" do
    let(:action) do
      { scope: :admin, action: :update, subject: :question_category }
    end

    it { is_expected.to eq true }
  end

  describe "import questions from another component" do
    let(:action) do
      { scope: :admin, action: :import, subject: :questions }
    end

    it { is_expected.to eq true }
  end

  describe "split questions" do
    let(:action) do
      { scope: :admin, action: :split, subject: :questions }
    end

    it { is_expected.to eq true }
  end

  describe "merge questions" do
    let(:action) do
      { scope: :admin, action: :merge, subject: :questions }
    end

    it { is_expected.to eq true }
  end

  describe "question answers publishing" do
    let(:user) { create(:user) }
    let(:action) do
      { scope: :admin, action: :publish_answers, subject: :questions }
    end

    it { is_expected.to eq false }

    context "when user is an admin" do
      let(:user) { create(:user, :admin) }

      it { is_expected.to eq true }
    end
  end

  describe "assign questions to a valuator" do
    let(:action) do
      { scope: :admin, action: :assign_to_valuator, subject: :questions }
    end

    it { is_expected.to eq true }
  end

  describe "unassign questions from a valuator" do
    let(:action) do
      { scope: :admin, action: :unassign_from_valuator, subject: :questions }
    end

    it { is_expected.to eq true }
  end

  describe "manage participatory texts" do
    let(:action) do
      { scope: :admin, action: :manage, subject: :participatory_texts }
    end

    it { is_expected.to eq true }
  end
end
