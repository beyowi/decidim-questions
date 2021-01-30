# frozen_string_literal: true

class MoveQuestionEndorsedEventNotificationsToResourceEndorsedEvent < ActiveRecord::Migration[5.2]
  def up
    Decidim::Notification.where(event_name: "decidim.events.questions.question_endorsed", event_class: "Decidim::Questions::QuestionEndorsedEvent").find_each do |notification|
      notification.update(event_name: "decidim.events.resource_endorsed", event_class: "Decidim::ResourceEndorsedEvent")
    end
  end

  def down
    Decidim::Notification.where(
      event_name: "decidim.events.resource_endorsed",
      event_class: "Decidim::ResourceEndorsedEvent",
      decidim_resource_type: "Decidim::Questions::Question"
    )
                         .find_each do |notification|
      notification.update(event_name: "decidim.events.questions.question_endorsed", event_class: "Decidim::Questions::QuestionEndorsedEvent")
    end
  end
end
