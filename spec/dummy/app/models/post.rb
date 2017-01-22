class Post < ActiveRecord::Base
  translates :title, :text, automatic: %i(en ja)
end
