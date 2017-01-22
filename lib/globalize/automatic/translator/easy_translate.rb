# frozen_string_literal: true

require 'globalize/automatic/translator'
require 'easy_translate'

class Globalize::Automatic::Translator::EasyTranslate < Globalize::Automatic::Translator

  def translate(text, from, to)
    ::EasyTranslate.translate(text, from: from, to: to)
  end

end
