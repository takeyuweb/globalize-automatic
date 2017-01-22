# frozen_string_literal: true

require 'globalize'
require 'globalize-accessors'
require 'globalize/automatic/translation'
require 'globalize/automatic/translator/easy_translate'

module Globalize::Automatic
  mattr_accessor :asynchronously, :translator

  module Concern
    extend ActiveSupport::Concern

    class_methods do
      def automatic_translation_class
        return @automatic_translation_class if defined?(@automatic_translation_class)
        if self.const_defined?(:AutomaticTranslation, false)
          klass = self.const_get(AutomaticTranslation, false)
        else
          klass = Class.new(Globalize::Automatic::Translation)
          self.const_set(:AutomaticTranslation, klass)
        end
        foreign_key = name.foreign_key
        klass.belongs_to :automatic_translated_model,
                         class_name: name,
                         foreign_key: foreign_key,
                         inverse_of: :automatic_translations
        klass.define_singleton_method(:automatic_translated_model_foreign_key) do
          foreign_key
        end
        @automatic_translation_class = klass
      end

      def add_automatic_translated_fields!(fields, locales)
        fields.each do |field|
          automatic_translated_fields[field] = locales
        end
      end

      def field_translate_automatic?(field, locale)
        if automatic_translated_fields[field].include?(locale)
          true
        else
          if superclass.include?(Globalize::Automatic::Concern)
            superclass.field_translate_automatic?(field, locale)
          else
            false
          end
        end
      end

      private
      def automatic_translated_fields
        @automatic_translated_fields ||= Hash.new { [] }
      end

      public
      def create_automatic_translation_table!(*fields)
        automatic_translation_class.create_table!(*fields)
      end

      def drop_automatic_translation_table!
        automatic_translation_class.drop_table!
      end

      def add_automatic_translation_fields!(*fields)
        automatic_translation_class.add_fields!(*fields)
      end

    end

    def automatic_translation_for(locale)
      automatic_translations.where(locale: locale).
          first_or_initialize(default_translation_automatically(locale))
    end

    private
    def default_translation_automatically(locale)
      translated_attribute_names.inject({}) do |defaults, attr_name|
        defaults[:"#{attr_name}_automatically"] = self.class.field_translate_automatic?(attr_name, locale)
        defaults
      end
    end

  end


  module_function

  def setup_automatic_translation!(klass, attr_names, options)
    automatic_options = validate_options(parse_options(options))
    locales = automatic_options[:from] + automatic_options[:to]
    klass.globalize_accessors locales: locales, attributes: attr_names
    unless klass.include?(Globalize::Automatic::Concern)
      klass.include Globalize::Automatic::Concern

      klass.has_many :automatic_translations,
                     dependent: :destroy,
                     autosave: true,
                     class_name: klass.automatic_translation_class.name,
                     foreign_key: klass.name.foreign_key
      automatic_table_name = "#{klass.table_name.singularize}_automatic_translations"
      klass.automatic_translation_class.table_name = automatic_table_name
      klass.automatic_translation_class.define_singleton_method(:table_name) { automatic_table_name }
    end

    #klass.add_automatic_translation_originals!(automatic_options[:from])
    klass.add_automatic_translated_fields!(attr_names, automatic_options[:to])

    attr_names.each do |attr_name|
      locales.each do |locale|
        klass.class_eval(<<"EVAL")
        def #{attr_name}_#{locale.to_s.underscore}_automatic
          automatic_translation_for(#{locale.inspect}).#{attr_name}_automatically
        end

        def #{attr_name}_#{locale.to_s.underscore}_automatic=(automatically)
          automatic_translation_for(#{locale.inspect}).#{attr_name}_automatically = automatically
        end
EVAL
      end
    end
  end

  def parse_options(options)
    case options
      when Hash
        from_locales = normalize_locales(options[:from])
        to_locales = normalize_locales(options[:to])
      else
        from_locales = normalize_locales(options)
        to_locales = I18n.available_locales - from_locales
    end
    {from: from_locales, to: to_locales}
  end

  def normalize_locales(locales)
    [locales].flatten.compact.map(&:to_sym)
  end

  def validate_options(options)
    if options[:from].empty?
      raise ArgumentError.new('missing :from option')
    elsif options[:to].empty?
      raise ArgumentError.new('missing :to option')
    else
      options
    end
  end
end
Globalize::Automatic.asynchronously = false
Globalize::Automatic.translator = Globalize::Automatic::Translator::EasyTranslate.new

Globalize::ActiveRecord::ActMacro.module_eval do

  def translates_with_automatic(*attr_names)
    translates_without_automatic(*attr_names).tap do
      options = attr_names.extract_options!
      automatic_options = options.delete(:automatic)
      if automatic_options.present?
        Globalize::Automatic.setup_automatic_translation!(self, attr_names, automatic_options)
      end
    end
  end

  alias_method_chain :translates, :automatic

end
