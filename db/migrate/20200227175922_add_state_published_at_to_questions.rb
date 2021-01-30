# frozen_string_literal: true

class AddStatePublishedAtToQuestions < ActiveRecord::Migration[5.2]
  def change
    add_column :decidim_questions_questions, :state_published_at, :datetime
  end
end
