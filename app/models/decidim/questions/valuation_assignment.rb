# frozen_string_literal: true

module Decidim
  module Questions
    # A valuation assignment links a question and a Valuator user role.
    # Valuators will be users in charge of defining the monetary cost of a
    # question.
    class ValuationAssignment < ApplicationRecord
      include Decidim::Traceable
      include Decidim::Loggable

      belongs_to :question, foreign_key: "decidim_question_id", class_name: "Decidim::Questions::Question"
      belongs_to :valuator_role, polymorphic: true

      def self.log_presenter_class_for(_log)
        Decidim::Questions::AdminLog::ValuationAssignmentPresenter
      end

      def valuator
        valuator_role.user
      end
    end
  end
end
