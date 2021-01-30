# frozen_string_literal: true

class SyncQuestionsStateWithAmendmentsState < ActiveRecord::Migration[5.2]
  def up
    execute <<-SQL.squish
      UPDATE decidim_questions_questions AS questions
      SET state = amendments.state
      FROM decidim_amendments AS amendments
      WHERE
        questions.state IS NULL AND
        amendments.decidim_emendation_type = 'Decidim::Questions::Question' AND
        amendments.decidim_emendation_id = questions.id AND
        amendments.state IS NOT NULL
    SQL
  end

  def down
    execute <<-SQL.squish
      UPDATE decidim_questions_questions AS questions
      SET state = NULL
      FROM decidim_amendments AS amendments
      WHERE
        amendments.decidim_emendation_type = 'Decidim::Questions::Question' AND
        amendments.decidim_emendation_id = questions.id AND
        amendments.state IS NOT NULL
    SQL
  end
end
