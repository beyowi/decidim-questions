# frozen_string_literal: true

class AddCostsToQuestions < ActiveRecord::Migration[5.2]
  def change
    add_column :decidim_questions_questions, :cost, :decimal
    add_column :decidim_questions_questions, :cost_report, :jsonb
    add_column :decidim_questions_questions, :execution_period, :jsonb
  end
end
