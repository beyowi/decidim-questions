# frozen_string_literal: true

require "active_support/concern"

module Decidim
  module Questions
    module Admin
      module Picker
        extend ActiveSupport::Concern

        included do
          helper Decidim::Questions::Admin::QuestionsPickerHelper
        end

        def questions_picker
          render :questions_picker, layout: false
        end
      end
    end
  end
end
