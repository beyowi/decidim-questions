# frozen_string_literal: true

module Decidim
  module Questions
    module Admin
      class ValuationAssignmentsController < Admin::ApplicationController
        def create
          enforce_permission_to :assign_to_valuator, :questions

          @form = form(Admin::ValuationAssignmentForm).from_params(params)

          Admin::AssignQuestionsToValuator.call(@form) do
            on(:ok) do |_question|
              flash[:notice] = I18n.t("valuation_assignments.create.success", scope: "decidim.questions.admin")
              redirect_to EngineRouter.admin_proxy(current_component).root_path
            end

            on(:invalid) do
              flash.now[:alert] = I18n.t("valuation_assignments.create.invalid", scope: "decidim.questions.admin")
              redirect_to EngineRouter.admin_proxy(current_component).root_path
            end
          end
        end

        def destroy
          @form = form(Admin::ValuationAssignmentForm).from_params(destroy_params)

          enforce_permission_to :unassign_from_valuator, :questions, valuator: @form.valuator_user

          Admin::UnassignQuestionsFromValuator.call(@form) do
            on(:ok) do |_question|
              flash.keep[:notice] = I18n.t("valuation_assignments.delete.success", scope: "decidim.questions.admin")
              redirect_back fallback_location: EngineRouter.admin_proxy(current_component).root_path
            end

            on(:invalid) do
              flash.keep[:alert] = I18n.t("valuation_assignments.delete.invalid", scope: "decidim.questions.admin")
              redirect_back fallback_location: EngineRouter.admin_proxy(current_component).root_path
            end
          end
        end

        private

        def destroy_params
          {
            id: params.dig(:valuator_role, :id) || params[:id],
            question_ids: params[:question_ids] || [params[:question_id]]
          }
        end

        def skip_manage_component_permission
          true
        end
      end
    end
  end
end
