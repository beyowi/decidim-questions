# frozen_string_literal: true

class FixUserGroupsIdsInQuestionsEndorsements < ActiveRecord::Migration[5.2]
  class QuestionEndorsement < ApplicationRecord
    self.table_name = :decidim_questions_question_endorsements
  end

  # rubocop:disable Rails/SkipsModelValidations
  def change
    Decidim::UserGroup.find_each do |group|
      old_id = group.extended_data["old_user_group_id"]
      next unless old_id

      Decidim::Questions::QuestionEndorsement
        .where(decidim_user_group_id: old_id)
        .update_all(decidim_user_group_id: group.id)
    end
  end
  # rubocop:enable Rails/SkipsModelValidations
end
