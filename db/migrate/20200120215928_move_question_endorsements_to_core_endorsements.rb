# frozen_string_literal: true

# This migration must be executed after CreateDecidimEndorsements migration in decidim-core.
class MoveQuestionEndorsementsToCoreEndorsements < ActiveRecord::Migration[5.2]
  class QuestionEndorsement < ApplicationRecord
    self.table_name = :decidim_questions_question_endorsements
  end
  class Endorsement < ApplicationRecord
    self.table_name = :decidim_endorsements
  end
  # Move QuestionEndorsements to Endorsements
  def up
    non_duplicated_group_endorsements = QuestionEndorsement.select(
      "MIN(id) as id, decidim_user_group_id"
    ).group(:decidim_user_group_id).where.not(decidim_user_group_id: nil).map(&:id)

    QuestionEndorsement.where("id IN (?) OR decidim_user_group_id IS NULL", non_duplicated_group_endorsements).find_each do |prop_endorsement|
      Endorsement.create!(
        resource_type: Decidim::Questions::Question.name,
        resource_id: prop_endorsement.decidim_question_id,
        decidim_author_type: prop_endorsement.decidim_author_type,
        decidim_author_id: prop_endorsement.decidim_author_id,
        decidim_user_group_id: prop_endorsement.decidim_user_group_id
      )
    end
    # update new `decidim_questions_question.endorsements_count` counter cache
    Decidim::Questions::Question.select(:id).all.find_each do |question|
      Decidim::Questions::Question.reset_counters(question.id, :endorsements)
    end
  end

  def down
    non_duplicated_group_endorsements = Endorsement.select(
      "MIN(id) as id, decidim_user_group_id"
    ).group(:decidim_user_group_id).where.not(decidim_user_group_id: nil).map(&:id)

    Endorsement
      .where(resource_type: "Decidim::Questions::Question")
      .where("id IN (?) OR decidim_user_group_id IS NULL", non_duplicated_group_endorsements).find_each do |endorsement|
      QuestionEndorsement.find_or_create_by!(
        decidim_question_id: endorsement.resource_id,
        decidim_author_type: endorsement.decidim_author_type,
        decidim_author_id: endorsement.decidim_author_id,
        decidim_user_group_id: endorsement.decidim_user_group_id
      )
    end
    # update `decidim_questions_question.question_endorsements_count` counter cache
    Decidim::Questions::Question.select(:id).all.find_each do |question|
      Decidim::Questions::Question.reset_counters(question.id, :question_endorsements)
    end
  end
end
