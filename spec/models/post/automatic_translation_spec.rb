# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Post::AutomaticTranslation, type: :model do
  it_behaves_like 'Globalize::Automatic::Translation', Post::AutomaticTranslation, :text
end
