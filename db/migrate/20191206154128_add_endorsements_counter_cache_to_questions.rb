# frozen_string_literal: true

class AddEndorsementsCounterCacheToQuestions < ActiveRecord::Migration[5.2]
  def change
    add_column :decidim_questions_questions, :endorsements_count, :integer, null: false, default: 0
  end
end
