require 'globalize-automatic'
Globalize::Automatic.translator =
    Globalize::Automatic::Translator::EasyTranslate.new.tap do |translator|
      translator.define_singleton_method(:language_to_google_translate_locale) do |locale|
        case locale.to_s
          when /zh-hant/i
            :'zh-TW'
          when /zh-hans/i
            :'zh-CN'
          else
            locale.to_sym
        end
      end
      translator.define_singleton_method(:before_translate) do |text, from, to|
        [text, language_to_google_translate_locale(from), language_to_google_translate_locale(to)]
      end
end