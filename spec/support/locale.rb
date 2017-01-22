# frozen_string_literal: true

RSpec.configure do |config|

  config.before(:each) do
    @locale = I18n.locale
  end

  config.after(:each) do
    I18n.locale = @locale
  end

end
