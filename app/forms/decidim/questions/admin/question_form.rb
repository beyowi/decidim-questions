# frozen_string_literal: true

module Decidim
  module Questions
    module Admin
      # A form object to be used when admin users want to create a question.
      class QuestionForm < Admin::QuestionBaseForm
        validates :title, length: { in: 15..150 }
      end
    end
  end
end
