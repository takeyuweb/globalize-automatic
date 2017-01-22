# frozen_string_literal: true

class Globalize::Automatic::TranslationJob < ActiveJob::Base
  queue_as :default

  def perform(automatic_translation, attr_name)
    Globalize::Automatic.translator.run(automatic_translation, attr_name)
  end

end
