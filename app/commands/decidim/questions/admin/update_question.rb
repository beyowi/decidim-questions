# frozen_string_literal: true

module Decidim
  module Questions
    module Admin
      # A command with all the business logic when a user updates a question.
      class UpdateQuestion < Rectify::Command
        include ::Decidim::AttachmentMethods
        include GalleryMethods
        include HashtagsMethods

        # Public: Initializes the command.
        #
        # form         - A form object with the params.
        # question - the question to update.
        def initialize(form, question)
          @form = form
          @question = question
          @attached_to = question
        end

        # Executes the command. Broadcasts these events:
        #
        # - :ok when everything is valid, together with the question.
        # - :invalid if the form wasn't valid and we couldn't proceed.
        #
        # Returns nothing.
        def call
          return broadcast(:invalid) if form.invalid?

          if process_attachments?
            @question.attachments.destroy_all

            build_attachment
            return broadcast(:invalid) if attachment_invalid?
          end

          if process_gallery?
            build_gallery
            return broadcast(:invalid) if gallery_invalid?
          end

          transaction do
            update_question
            update_question_author
            create_attachment if process_attachments?
            create_gallery if process_gallery?
            photo_cleanup!
          end

          broadcast(:ok, question)
        end

        private

        attr_reader :form, :question, :attachment, :gallery

        def update_question
          Decidim.traceability.update!(
            question,
            form.current_user,
            title: title_with_hashtags,
            body: body_with_hashtags,
            category: form.category,
            scope: form.scope,
            address: form.address,
            latitude: form.latitude,
            longitude: form.longitude,
            created_in_meeting: form.created_in_meeting
          )
        end

        def update_question_author
          question.coauthorships.clear
          question.add_coauthor(form.author)
          question.save!
          question
        end
      end
    end
  end
end
