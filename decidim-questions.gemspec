# frozen_string_literal: true

$LOAD_PATH.push File.expand_path("lib", __dir__)

# Maintain your gem's version:
require "decidim/questions/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.version = Decidim::Questions.version
  s.authors = ["cedrtang"]
  s.email = ["cedric@beyowi.com"]
  s.license = "AGPL-3.0"
  s.homepage = "https://github.com/beyowi/decidim-questions"
  s.required_ruby_version = ">= 2.5"

  s.name = "decidim-questions"
  s.summary = "Decidim questions module"
  s.description = "A questions component for decidim's participatory spaces."

  s.files = Dir["{app,config,db,lib}/**/*", "LICENSE-AGPLv3.txt", "Rakefile", "README.md"]

  s.add_dependency "acts_as_list", "~> 0.9"
  s.add_dependency "cells-erb", "~> 0.1.0"
  s.add_dependency "cells-rails", "~> 0.0.9"
  s.add_dependency "decidim-comments", Decidim::Questions.version
  s.add_dependency "decidim-core", Decidim::Questions.version
  s.add_dependency "doc2text", "~> 0.4.2"
  s.add_dependency "kaminari", "~> 1.2", ">= 1.2.1"
  s.add_dependency "ransack", "~> 2.1.1"
  s.add_dependency "redcarpet", "~> 3.4"

  s.add_development_dependency "decidim-admin", Decidim::Questions.version
  s.add_development_dependency "decidim-assemblies", Decidim::Questions.version
  s.add_development_dependency "decidim-budgets", Decidim::Questions.version
  s.add_development_dependency "decidim-dev", Decidim::Questions.version
  s.add_development_dependency "decidim-meetings", Decidim::Questions.version
  s.add_development_dependency "decidim-participatory_processes", Decidim::Questions.version
end
