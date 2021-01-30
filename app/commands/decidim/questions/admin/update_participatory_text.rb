# frozen_string_literal: true

module Decidim
  module Questions
    module Admin
      # A command with all the business logic when an admin updates participatory text questions.
      class UpdateParticipatoryText < Rectify::Command
        # Public: Initializes the command.
        #
        # form - A PreviewParticipatoryTextForm form object with the params.
        def initialize(form)
          @form = form
        end

        # Executes the command. Broadcasts these events:
        #
        # - :ok when everything is valid.
        # - :invalid if the form wasn't valid and we couldn't proceed.
        #
        # Returns nothing.
        def call
          transaction do
            @failures = {}
            update_contents_and_resort_questions(form)
          end

          if @failures.any?
            broadcast(:invalid, @failures)
          else
            broadcast(:ok)
          end
        end

        private

        attr_reader :form

        # Prevents PaperTrail from creating versions while updating participatory text questions.
        # A first version will be created when publishing the Participatory Text.
        def update_contents_and_resort_questions(form)
          PaperTrail.request(enabled: false) do
            form.questions.each do |prop_form|
              question = Question.where(component: form.current_component).find(prop_form.id)
              question.set_list_position(prop_form.position) if question.position != prop_form.position
              question.title = prop_form.title
              question.body = prop_form.body if question.participatory_text_level == ParticipatoryTextSection::LEVELS[:article]

              add_failure(question) unless question.save
            end
          end
          raise ActiveRecord::Rollback if @failures.any?
        end

        def add_failure(question)
          @failures[question.id] = question.errors.full_messages
        end
      end
    end
  end
end
