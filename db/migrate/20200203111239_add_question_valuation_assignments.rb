# frozen_string_literal: true

class AddQuestionValuationAssignments < ActiveRecord::Migration[5.2]
  def change
    create_table :decidim_questions_valuation_assignments do |t|
      t.references :decidim_question, null: false, index: { name: "decidim_questions_valuation_assignment_question" }
      t.references :valuator_role, polymorphic: true, null: false, index: { name: "decidim_questions_valuation_assignment_valuator_role" }

      t.timestamps
    end
  end
end
