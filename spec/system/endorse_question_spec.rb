# frozen_string_literal: true

require "spec_helper"

describe "Endorse Question", type: :system do
  include_context "with resources to be endorsed or not"

  let(:manifest_name) { "questions" }
  let!(:resources) { create_list(:question, 3, component: component, skip_injection: true) }
  let!(:resource) { resources.first }
  let!(:resource_name) { resource.title }
  let!(:component) do
    create(:question_component,
           *component_traits,
           manifest: manifest,
           participatory_space: participatory_process)
  end

  it_behaves_like "Endorse resource system specs"
end
