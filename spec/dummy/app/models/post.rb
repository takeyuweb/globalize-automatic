class Post < ApplicationRecord
  translates :title, :text, automatic: %i(en ja)
  translates :author
end
