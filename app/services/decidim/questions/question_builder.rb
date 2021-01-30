# frozen_string_literal: true

require "open-uri"

module Decidim
  module Questions
    # A factory class to ensure we always create Questions the same way since it involves some logic.
    module QuestionBuilder
      # Public: Creates a new Question.
      #
      # attributes        - The Hash of attributes to create the Question with.
      # author            - An Authorable the will be the first coauthor of the Question.
      # user_group_author - A User Group to, optionally, set it as the author too.
      # action_user       - The User to be used as the user who is creating the question in the traceability logs.
      #
      # Returns a Question.
      def create(attributes:, author:, action_user:, user_group_author: nil)
        Decidim.traceability.perform_action!(:create, Question, action_user, visibility: "all") do
          question = Question.new(attributes)
          question.add_coauthor(author, user_group: user_group_author)
          question.save!
          question
        end
      end

      module_function :create

      # Public: Creates a new Question with the authors of the `original_question`.
      #
      # attributes - The Hash of attributes to create the Question with.
      # action_user - The User to be used as the user who is creating the question in the traceability logs.
      # original_question - The question from which authors will be copied.
      #
      # Returns a Question.
      def create_with_authors(attributes:, action_user:, original_question:)
        Decidim.traceability.perform_action!(:create, Question, action_user, visibility: "all") do
          question = Question.new(attributes)
          original_question.coauthorships.each do |coauthorship|
            question.add_coauthor(coauthorship.author, user_group: coauthorship.user_group)
          end
          question.save!
          question
        end
      end

      module_function :create_with_authors

      # Public: Creates a new Question by copying the attributes from another one.
      #
      # original_question - The Question to be used as base to create the new one.
      # author            - An Authorable the will be the first coauthor of the Question.
      # user_group_author - A User Group to, optionally, set it as the author too.
      # action_user       - The User to be used as the user who is creating the question in the traceability logs.
      # extra_attributes  - A Hash of attributes to create the new question, will overwrite the original ones.
      # skip_link         - Whether to skip linking the two questions or not (default false).
      #
      # Returns a Question
      #
      # rubocop:disable Metrics/ParameterLists
      def copy(original_question, author:, action_user:, user_group_author: nil, extra_attributes: {}, skip_link: false)
        origin_attributes = original_question.attributes.except(
          "id",
          "created_at",
          "updated_at",
          "state",
          "answer",
          "answered_at",
          "decidim_component_id",
          "reference",
          "question_votes_count",
          "endorsements_count",
          "question_notes_count"
        ).merge(
          "category" => original_question.category
        ).merge(
          extra_attributes
        )

        question = if author.nil?
                     create_with_authors(
                       attributes: origin_attributes,
                       original_question: original_question,
                       action_user: action_user
                     )
                   else
                     create(
                       attributes: origin_attributes,
                       author: author,
                       user_group_author: user_group_author,
                       action_user: action_user
                     )
                   end

        question.link_resources(original_question, "copied_from_component") unless skip_link
        copy_attachments(original_question, question)

        question
      end
      # rubocop:enable Metrics/ParameterLists

      module_function :copy

      def copy_attachments(original_question, question)
        original_question.attachments.each do |attachment|
          new_attachment = Decidim::Attachment.new(attachment.attributes.slice("content_type", "description", "file", "file_size", "title", "weight"))
          new_attachment.attached_to = question

          if File.exist?(attachment.file.file.path)
            new_attachment.file = File.open(attachment.file.file.path)
          else
            new_attachment.remote_file_url = attachment.url
          end

          new_attachment.save!
        rescue Errno::ENOENT, OpenURI::HTTPError => e
          Rails.logger.warn("[ERROR] Couldn't copy attachment from question #{original_question.id} when copying to component due to #{e.message}")
        end
      end

      module_function :copy_attachments
    end
  end
end
