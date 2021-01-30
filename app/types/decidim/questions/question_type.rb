# frozen_string_literal: true

module Decidim
  module Questions
    QuestionType = GraphQL::ObjectType.define do
      name "Question"
      description "A question"

      interfaces [
        -> { Decidim::Comments::CommentableInterface },
        -> { Decidim::Core::CoauthorableInterface },
        -> { Decidim::Core::CategorizableInterface },
        -> { Decidim::Core::ScopableInterface },
        -> { Decidim::Core::AttachableInterface },
        -> { Decidim::Core::FingerprintInterface },
        -> { Decidim::Core::AmendableInterface },
        -> { Decidim::Core::AmendableEntityInterface },
        -> { Decidim::Core::TraceableInterface },
        -> { Decidim::Core::EndorsableInterface },
        -> { Decidim::Core::TimestampsInterface }
      ]

      field :id, !types.ID
      field :title, !types.String, "This question's title"
      field :body, types.String, "This question's body"
      field :address, types.String, "The physical address (location) of this question"
      field :coordinates, Decidim::Core::CoordinatesType, "Physical coordinates for this question" do
        resolve ->(question, _args, _ctx) {
          [question.latitude, question.longitude]
        }
      end
      field :reference, types.String, "This question's unique reference"
      field :state, types.String, "The answer status in which question is in"
      field :answer, Decidim::Core::TranslatedFieldType, "The answer feedback for the status for this question"

      field :answeredAt, Decidim::Core::DateTimeType do
        description "The date and time this question was answered"
        property :answered_at
      end

      field :publishedAt, Decidim::Core::DateTimeType do
        description "The date and time this question was published"
        property :published_at
      end

      field :participatoryTextLevel, types.String do
        description "If it is a participatory text, the level indicates the type of paragraph"
        property :participatory_text_level
      end
      field :position, types.Int, "Position of this question in the participatory text"

      field :official, types.Boolean, "Whether this question is official or not", property: :official?
      field :createdInMeeting, types.Boolean, "Whether this question comes from a meeting or not", property: :official_meeting?
      field :meeting, Decidim::Meetings::MeetingType do
        description "If the question comes from a meeting, the related meeting"
        resolve ->(question, _, _) {
          question.authors.first if question.official_meeting?
        }
      end

      field :voteCount, types.Int do
        description "The total amount of votes the question has received"
        resolve ->(question, _args, _ctx) {
          current_component = question.component
          question.question_votes_count unless current_component.current_settings.votes_hidden?
        }
      end
    end
  end
end
