# frozen_string_literal: true

module Decidim
  module Questions
    module Admin
      # A command with all the business logic when an admin creates a private note question.
      class CreateQuestionNote < Rectify::Command
        # Public: Initializes the command.
        #
        # form         - A form object with the params.
        # question - the question to relate.
        def initialize(form, question)
          @form = form
          @question = question
        end

        # Executes the command. Broadcasts these events:
        #
        # - :ok when everything is valid, together with the note question.
        # - :invalid if the form wasn't valid and we couldn't proceed.
        #
        # Returns nothing.
        def call
          return broadcast(:invalid) if form.invalid?

          create_question_note
          notify_admins_and_valuators

          broadcast(:ok, question_note)
        end

        private

        attr_reader :form, :question_note, :question

        def create_question_note
          @question_note = Decidim.traceability.create!(
            QuestionNote,
            form.current_user,
            {
              body: form.body,
              question: question,
              author: form.current_user
            },
            resource: {
              title: question.title
            }
          )
        end

        def notify_admins_and_valuators
          affected_users = Decidim::User.org_admins_except_me(form.current_user).all
          affected_users += Decidim::Questions::ValuationAssignment.includes(valuator_role: :user).where.not(id: form.current_user.id).where(question: question).map(&:valuator)

          data = {
            event: "decidim.events.questions.admin.question_note_created",
            event_class: Decidim::Questions::Admin::QuestionNoteCreatedEvent,
            resource: question,
            affected_users: affected_users
          }

          Decidim::EventsManager.publish(data)
        end
      end
    end
  end
end
