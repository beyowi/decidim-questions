# frozen_string_literal: true

module Decidim
  module Questions
    # This is the engine that runs on the public interface of `decidim-questions`.
    class AdminEngine < ::Rails::Engine
      isolate_namespace Decidim::Questions::Admin

      paths["db/migrate"] = nil
      paths["lib/tasks"] = nil

      routes do
        resources :questions, only: [:show, :index, :new, :create, :edit, :update] do
          resources :valuation_assignments, only: [:destroy]
          collection do
            post :update_category
            post :publish_answers
            post :update_scope
            resource :questions_import, only: [:new, :create]
            resource :questions_merge, only: [:create]
            resource :questions_split, only: [:create]
            resource :valuation_assignment, only: [:create, :destroy]
          end
          resources :question_answers, only: [:edit, :update]
          resources :question_notes, only: [:create]
        end

        resources :participatory_texts, only: [:index] do
          collection do
            get :new_import
            post :import
            patch :import
            post :update
            post :discard
          end
        end

        root to: "questions#index"
      end

      initializer "decidim_questions.admin_assets" do |app|
        app.config.assets.precompile += %w(admin/decidim_questions_manifest.js)
      end

      def load_seed
        nil
      end
    end
  end
end
