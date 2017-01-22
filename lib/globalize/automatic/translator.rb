# frozen_string_literal: true

require 'globalize-automatic'

class Globalize::Automatic::Translator

  def run(automatic_translation, attr_name)
    process(automatic_translation, attr_name)
  end

  def translate(text, from, to); end

  private
  def process(automatic_translation, attr_name)
    translation = automatic_translation.translation_from
    text = translation[attr_name]
    from = translation.locale
    to = automatic_translation.to
    translated = translate(text, from, to)
    automatic_translation.resolve(attr_name, translated)
  end

end
