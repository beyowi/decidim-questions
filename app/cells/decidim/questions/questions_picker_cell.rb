# frozen_string_literal: true

require "cell/partial"

module Decidim
  module Questions
    # This cell renders a questions picker.
    class QuestionsPickerCell < Decidim::ViewModel
      MAX_QUESTIONS = 1000

      def show
        if filtered?
          render :questions
        else
          render
        end
      end

      alias component model

      def filtered?
        !search_text.nil?
      end

      def picker_path
        request.path
      end

      def search_text
        params[:q]
      end

      def more_questions?
        @more_questions ||= more_questions_count.positive?
      end

      def more_questions_count
        @more_questions_count ||= questions_count - MAX_QUESTIONS
      end

      def questions_count
        @questions_count ||= filtered_questions.count
      end

      def decorated_questions
        filtered_questions.limit(MAX_QUESTIONS).each do |question|
          yield Decidim::Questions::QuestionPresenter.new(question)
        end
      end

      def filtered_questions
        @filtered_questions ||= if filtered?
                                  questions.where("title ILIKE ?", "%#{search_text}%")
                                           .or(questions.where("reference ILIKE ?", "%#{search_text}%"))
                                           .or(questions.where("id::text ILIKE ?", "%#{search_text}%"))
                                else
                                  questions
                                end
      end

      def questions
        @questions ||= Decidim.find_resource_manifest(:questions).try(:resource_scope, component)
                       &.published
                       &.order(id: :asc)
      end

      def questions_collection_name
        Decidim::Questions::Question.model_name.human(count: 2)
      end
    end
  end
end
