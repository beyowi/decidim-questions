# frozen_string_literal: true

require "decidim/dev/test/rspec_support/capybara_data_picker"

module Capybara
  module QuestionsPicker
    include DataPicker

    RSpec::Matchers.define :have_questions_picked do |expected|
      match do |questions_picker|
        data_picker = questions_picker.data_picker

        expected.each do |question|
          expect(data_picker).to have_selector(".picker-values div input[value='#{question.id}']", visible: :all)
          expect(data_picker).to have_selector(:xpath, "//div[contains(@class,'picker-values')]/div/a[text()[contains(.,\"#{question.title}\")]]")
        end
      end
    end

    RSpec::Matchers.define :have_questions_not_picked do |expected|
      match do |questions_picker|
        data_picker = questions_picker.data_picker

        expected.each do |question|
          expect(data_picker).not_to have_selector(".picker-values div input[value='#{question.id}']", visible: :all)
          expect(data_picker).not_to have_selector(:xpath, "//div[contains(@class,'picker-values')]/div/a[text()[contains(.,\"#{question.title}\")]]")
        end
      end
    end

    def questions_pick(questions_picker, questions)
      data_picker = questions_picker.data_picker

      expect(data_picker).to have_selector(".picker-prompt")
      data_picker.find(".picker-prompt").click

      questions.each do |question|
        data_picker_choose_value(question.id)
      end
      data_picker_close

      expect(questions_picker).to have_questions_picked(questions)
    end
  end
end

RSpec.configure do |config|
  config.include Capybara::QuestionsPicker, type: :system
end
