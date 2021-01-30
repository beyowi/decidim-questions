# frozen_string_literal: true

require "spec_helper"

describe "Follow questions", type: :system do
  let(:manifest_name) { "questions" }

  let!(:followable) do
    create(:question, component: component)
  end

  include_examples "follows"
end
