# frozen_string_literal: true

module Decidim
  module Questions
    module Admin
      module FilterableHelper
        def extra_dropdown_submenu_options_items(filter, i18n_scope)
          options = case filter
                    when :state_eq
                      content_tag(:li, filter_link_value(:state_null, true, i18n_scope))
                    end
          [options].compact
        end
      end
    end
  end
end
