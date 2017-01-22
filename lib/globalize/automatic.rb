# frozen_string_literal: true

require 'globalize'
require 'globalize-accessors'
require 'globalize/automatic/translation'
require 'globalize/automatic/translation_job'
require 'globalize/automatic/translator/easy_translate'
require 'after_commit_action'

module Globalize::Automatic
  mattr_accessor :asynchronously, :translator

  module TranslatedExtension
    extend ActiveSupport::Concern

    included do
      class_attribute :automatic_translation_attribute_names,
                      :automatic_translation_field_locales,
                      :automatic_translated_field_locales
      self.automatic_translation_attribute_names = []
      self.automatic_translation_field_locales = Hash.new { [] }
      self.automatic_translated_field_locales = Hash.new { [] }
    end

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

      # 翻訳元フィールドと言語
      def add_automatic_translation_field_locales!(fields, locales)
        fields.each do |field|
          automatic_translation_field_locales[field] = locales
        end
      end

      # 翻訳先フィールドと言語
      def add_automatic_translated_field_locales!(fields, locales)
        fields.each do |field|
          automatic_translated_field_locales[field] = locales
        end
      end

      # field が locale で自動翻訳元指定されているか
      def translate_field_automatically?(field, locale)
        automatic_translation_field_locales[field].include?(locale)
      end

      # field が locale で自動翻訳先指定されているか
      def translated_field_automatically?(field, locale)
        automatic_translated_field_locales[field].include?(locale)
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

    # from_locale から attribute_names を自動翻訳
    # 自動翻訳が対象でない場合なにもしない
    def run_automatic_translation(from_locale: , attribute_names:)
      attribute_names.each do |attr_name|
        # 自動翻訳対象以外
        next unless automatic_translation_field_locales[attr_name].include?(from_locale)
        # 自動翻訳先としては無効化されている
        next if automatic_translation_for(from_locale)[:"#{attr_name}_automatically"]
        automatic_translated_field_locales[attr_name].each do |to_locale|
          next if to_locale == from_locale
          automatic_translation_for(to_locale).translate(attr_name)
        end
      end
      true
    end

    # 自動翻訳元言語
    # attr_nameの自動変換が有効なとき
    # 現在設定されている中で一番優先度の高い翻訳元localeを返す
    # どの言語も設定されてない場合は一番優先度の高いもの
    # 自動翻訳元でない場合nil
    def automatic_translation_locale(attr_name)
      locales = automatic_translation_field_locales[attr_name]
      locales.each do |locale|
        return locale unless translation_for(locale)[attr_name].blank?
      end
      locales.first
    end

    private
    def default_translation_automatically(locale)
      # 自動翻訳元指定されていなくて、
      # 自動翻訳先指定されているものを
      # デフォルトで自動翻訳ONにする
      translated_attribute_names.inject({}) do |defaults, attr_name|
        defaults[:"#{attr_name}_automatically"] =
            self.class.translated_field_automatically?(attr_name, locale) &&
                !self.class.translate_field_automatically?(attr_name, locale)
        defaults
      end
    end

  end

  module TranslationExtension
    extend ActiveSupport::Concern
    included do
      include AfterCommitAction unless include?(AfterCommitAction)
      after_save :after_save
    end

    private
    def after_save
      changed_attr_names =
          globalized_model.translated_attribute_names & changes.keys.map(&:to_sym)

      execute_after_commit do
        globalized_model.run_automatic_translation(from_locale: locale,
                                                   attribute_names: changed_attr_names)
        true
      end
      true
    end
  end

  module_function

  def setup_automatic_translation!(klass, attr_names, options)
    automatic_options = validate_options(parse_options(options))
    locales = (automatic_options[:from] + automatic_options[:to]).uniq
    klass.globalize_accessors locales: locales, attributes: attr_names
    unless klass.include?(Globalize::Automatic::TranslatedExtension)
      klass.include Globalize::Automatic::TranslatedExtension

      klass.has_many :automatic_translations,
                     dependent: :destroy,
                     autosave: true,
                     class_name: klass.automatic_translation_class.name,
                     foreign_key: klass.name.foreign_key,
                     inverse_of: :automatic_translated_model
      automatic_table_name = "#{klass.table_name.singularize}_automatic_translations"
      klass.automatic_translation_class.table_name = automatic_table_name
      klass.automatic_translation_class.define_singleton_method(:table_name) { automatic_table_name }
    end

    klass.add_automatic_translation_field_locales!(attr_names, automatic_options[:from])
    klass.add_automatic_translated_field_locales!(attr_names, automatic_options[:to])

    attr_names.each do |attr_name|
      locales.each do |locale|
        klass.class_eval(<<"EVAL")
        def #{attr_name}_#{locale.to_s.underscore}_automatically
          automatic_translation_for(#{locale.inspect}).#{attr_name}_automatically
        end

        def #{attr_name}_#{locale.to_s.underscore}_automatically=(automatically)
          automatic_translation_for(#{locale.inspect}).#{attr_name}_automatically = automatically
        end
 
        self.automatic_translation_attribute_names.push(:#{attr_name}_#{locale.to_s.underscore}_automatically)
EVAL
      end
    end

    unless klass.translation_class.include?(Globalize::Automatic::TranslationExtension)
      klass.translation_class.include Globalize::Automatic::TranslationExtension
    end
  end

  def parse_options(options)
    case options
      when Hash
        from_locales = normalize_locales(options[:from])
        to_locales = normalize_locales(options[:to])
      else
        from_locales = normalize_locales(options)
        to_locales = I18n.available_locales
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
