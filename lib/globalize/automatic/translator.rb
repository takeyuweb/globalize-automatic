# frozen_string_literal: true

class Globalize::Automatic::Translator

  def run(automatic_translation, attr_name)
    attr_name = attr_name.to_sym
    translation = automatic_translation.translation_from(attr_name)
    text = translation[attr_name]
    from = translation.locale
    to = automatic_translation.locale
    _text, _from, _to = before_translate(text, from, to)
    translated = translate(_text, _from, _to)
    _text, _from, _to, _translated = after_translate(_text, _from, _to, translated)
    automatic_translation.resolve(attr_name, _translated)
  end

  def translate(text, from, to); end

  def before_translate(text, from, to)
    [text, from, to]
  end

  def after_translate(text, from, to, result)
    [text, from, to, result]
  end

end
