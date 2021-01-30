# frozen_string_literal: true

module Decidim
  module Questions
    module Admin
      # A command with all the business logic when an admin imports questions from
      # a participatory text.
      class PublishParticipatoryText < UpdateParticipatoryText
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
            publish_drafts
          end

          if @failures.any?
            broadcast(:invalid, @failures)
          else
            broadcast(:ok)
          end
        end

        private

        attr_reader :form

        def publish_drafts
          Decidim::Questions::Question.where(component: form.current_component).drafts.find_each do |question|
            add_failure(question) unless publish_question(question)
          end
          raise ActiveRecord::Rollback if @failures.any?
        end

        def add_failure(question)
          @failures[question.id] = question.errors.full_messages
        end

        # This will be the PaperTrail version shown in the version control feature (1 of 1).
        # For an attribute to appear in the new version it has to be reset
        # and reassigned, as PaperTrail only keeps track of object CHANGES.
        def publish_question(question)
          title, body = reset_question_title_and_body(question)

          Decidim.traceability.perform_action!(:create, question, form.current_user, visibility: "all") do
            question.update(title: title, body: body, published_at: Time.current)
          end
        end

        # Reset the attributes to an empty string and return the old values.
        def reset_question_title_and_body(question)
          title = question.title
          body = question.body

          PaperTrail.request(enabled: false) do
            question.update_columns(title: "", body: "") # rubocop:disable Rails/SkipsModelValidations
          end

          [title, body]
        end
      end
    end
  end
end
