# frozen_string_literal: true

module Decidim
  module Questions
    module Admin
      # A form object to be used when admin users want to create a question
      # through the participatory texts.
      class ParticipatoryTextQuestionForm < Admin::QuestionBaseForm
        validates :title, length: { maximum: 150 }
      end
    end
  end
end
