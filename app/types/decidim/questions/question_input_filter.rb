# frozen_string_literal: true

module Decidim
  module Questions
    class QuestionInputFilter < Decidim::Core::BaseInputFilter
      include Decidim::Core::HasPublishableInputFilter

      graphql_name "QuestionFilter"
      description "A type used for filtering questions inside a participatory space.

A typical query would look like:

```
  {
    participatoryProcesses {
      components {
        ...on Questions {
          questions(filter:{ publishedBefore: \"2020-01-01\" }) {
            id
          }
        }
      }
    }
  }
```
"
    end
  end
end
