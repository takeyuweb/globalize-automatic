# frozen_string_literal: true

require 'rails_helper'

$ar_class = 0
def next_ar_class
  $ar_class += $ar_class.succ
  $ar_class
end

RSpec.describe Post, type: :model do
  before do
    allow(Globalize::Automatic::Translator)
  end

  describe 'translates *attr_names, automatic:' do

    def with_test_objects(klass)
      migrator = Class.new(ActiveRecord::Migration)

      translation_column_types = klass.translated_attribute_names.inject({}) do |data, attr_name|
        data.tap { data[attr_name] = :string }
      end

      if klass.superclass == ActiveRecord::Base

        migrator.define_singleton_method(:up) do
          create_table klass.table_name, force: true do |t|
            t.timestamps null: false
          end
          klass.create_translation_table! translation_column_types
          klass.create_automatic_translation_table! *klass.translated_attribute_names
        end
        migrator.define_singleton_method(:down) do
          drop_table(klass.table_name)
          klass.drop_translation_table!
          klass.drop_automatic_translation_table!
        end
      else
        # use sti

        migrator.define_singleton_method(:up) do
          change_table klass.table_name, force: true do |t|
            t.string :type
          end
          translation_column_types.each do |column_name, column_type|
            unless klass.translation_class.connection.column_exists?(klass.translation_class.table_name, column_name)
              klass.add_translation_fields! column_name => column_type
              klass.add_automatic_translation_fields! column_name
            end
          end
        end
        migrator.define_singleton_method(:down) do
          translation_column_types.keys.each do |field|
            remove_column klass.translation_class.table_name, field
            #remove_column klass.automatic_translation_class.table_name, "#{field}_automatically"
          end
        end
      end
      Object.const_set(klass.name + 'Migration', migrator)
      begin
        migrator.up
        yield
      ensure
        migrator.down
      end
    end

    def with_test_class(superclass: nil, translate_options: [])
      superclass ||= ActiveRecord::Base
      klass = Class.new(superclass)
      Object.const_set("TestModel#{next_ar_class}", klass)
      klass.class_eval do
        self.table_name = :test_objects
      end
    translate_options.each do |translate_option|
        klass.translates *translate_option
      end
      if block_given?
        with_test_objects(klass) do
          yield(klass)
        end
      end
    end

    it do
      with_test_class(translate_options: [[:title, automatic: :en]]) do |klass|
        post = klass.new
        expect(post.title_en_automatic).to be_falsey
        expect(post.title_ja_automatic).to be_truthy
        expect(post.title_fr_automatic).to be_truthy
        expect(post.title_zh_hans_automatic).to be_truthy
        expect(post.title_zh_hant_automatic).to be_truthy
        expect(post.title_ko_automatic).to be_truthy
        expect(post.title_th_automatic).to be_truthy
        expect(post.title_vi_automatic).to be_truthy
        expect(post.title_fr_automatic).to be_truthy
      end
    end

    it do
      with_test_class(translate_options: [[:title, automatic: %i(en ja)]]) do |klass|
        post = klass.new
        expect(post.title_en_automatic).to be_falsey
        expect(post.title_ja_automatic).to be_falsey
        expect(post.title_fr_automatic).to be_truthy
        expect(post.title_zh_hans_automatic).to be_truthy
        expect(post.title_zh_hant_automatic).to be_truthy
        expect(post.title_ko_automatic).to be_truthy
        expect(post.title_th_automatic).to be_truthy
        expect(post.title_vi_automatic).to be_truthy
        expect(post.title_fr_automatic).to be_truthy
      end
    end

    it do
      expect {
        with_test_class(translate_options: [[:title, automatic: {from: :en}]])
      }.to raise_error(ArgumentError)
    end

    it do
      expect {
        with_test_class(translate_options: [[:title, automatic: {to: :fr}]])
      }.to raise_error(ArgumentError)
    end

    it do
      with_test_class(translate_options: [[:title, automatic: {from: :en, to: %i(fr zh-hans)}]]) do |klass|
        post = klass.new
        expect(post.title_en_automatic).to be_falsey
        expect(post).to_not be_respond_to(:title_ja_automatic)
      end

    end

    it do
      with_test_class(translate_options: [[:title, automatic: {from: %i(en ja), to: :fr}]]) do |klass|
        post = klass.new
        expect(post.title_en_automatic).to be_falsey
        expect(post.title_ja_automatic).to be_falsey
      end
    end

    it do
      with_test_class(translate_options: [[:title, automatic: {from: %i(en ja), to: %i(fr zh-hans)}]]) do |klass|
        post = klass.new
        expect(post.title_en_automatic).to be_falsey
        expect(post.title_ja_automatic).to be_falsey
        expect(post.title_fr_automatic).to be_truthy
        expect(post.title_zh_hans_automatic).to be_truthy
        expect(post).to_not be_respond_to(:title_zh_hant_automatic)
      end
    end

    it '同じフィールドに対して２回指定した場合最後に指定された方' do
      with_test_class(translate_options: [[:title, automatic: %i(en ja)], [:title, automatic: :fr]]) do |klass|
        post = klass.new
        expect(post.title_en_automatic).to be_truthy
        expect(post.title_ja_automatic).to be_truthy
        expect(post.title_fr_automatic).to be_falsey
        expect(post.title_zh_hans_automatic).to be_truthy
        expect(post.title_zh_hant_automatic).to be_truthy
        expect(post.title_ko_automatic).to be_truthy
        expect(post.title_th_automatic).to be_truthy
        expect(post.title_vi_automatic).to be_truthy
      end
    end

    it '異なるフィールドに対して指定した場合別々に' do
      with_test_class(translate_options: [[:title, automatic: %i(en ja)], [:text, automatic: :fr]]) do |klass|
        post = klass.new
        expect(post.title_en_automatic).to be_falsey
        expect(post.title_ja_automatic).to be_falsey
        expect(post.title_fr_automatic).to be_truthy
        expect(post.text_en_automatic).to be_truthy
        expect(post.text_ja_automatic).to be_truthy
        expect(post.text_fr_automatic).to be_falsey
      end
    end

    describe 'STI対応' do
      it '' do
        with_test_class(translate_options: [[:title, automatic: %i(en ja)]]) do |superclass|
          with_test_class(superclass: superclass, translate_options: [[:text, automatic: :fr]]) do |klass|
            post = klass.new
            expect(post.title_en_automatic).to be_falsey
            expect(post.title_ja_automatic).to be_falsey
            expect(post.title_fr_automatic).to be_truthy
            expect(post.text_en_automatic).to be_truthy
            expect(post.text_ja_automatic).to be_truthy
            expect(post.text_fr_automatic).to be_falsey
          end
        end

      end
    end


  end

=begin

  it do
    I18n.locale = :en
    post = Post.new
    post.title = 'globalize'
    post.save!
    expect(post.title).to eq('globalize')

    I18n.locale = :ja
    expect(post.title).to eq(nil)

    I18n.locale = :fr
    expect(post.title).to eq('globalize (fr)')
  end

  it do
    I18n.locale = :en
    post = Post.new
    post.title = 'globalize'
    post.save!
    expect(post.title).to eq('globalize')

    I18n.locale = :ja
    expect(post.title).to eq(nil)

    I18n.locale = :fr
    expect(post.title).to eq('globalize (fr)')
  end

  it do
    post = Post.new
    post.attributes = {
        title_en: 'globalize',
        title_ja_automatic: true
    }
    post.save!

    I18n.locale = :en
    expect(post.title).to eq('globalize')
    I18n.locale = :ja
    expect(post.title).to eq('globalize (ja)')
  end

  it do
    post = Post.new
    post.attributes = {
        title_en: 'globalize',
        title_fr_automatic: false,
        title_fr: 'Hoge'
    }
    post.save!

    I18n.locale = :en
    expect(post.title).to eq('globalize')
    I18n.locale = :vi
    expect(post.title).to eq('globalize (vi)')
    I18n.locale = :fr
    expect(post.title).to eq('Hoge')
  end

  it do
    post = Post.new
    post.attributes = {
        title_en: 'English',
        title_ja: '日本語'
    }
    post.save!

    I18n.locale = :fr
    expect(post.title).to eq('English (fr)')
  end

  it do
    post = Post.new
    post.attributes = {
        title_en: nil,
        title_ja: '日本語'
    }
    post.save!

    I18n.locale = :fr
    expect(post.title).to eq('日本語 (fr)')
  end

  it do
    globalize_attribute_names = %i(
      title_ja title_en title_zh_hans title_zh_hant title_ko title_th title_vi title_fr text_ja
      text_en text_zh_hans text_zh_hant text_ko text_th text_vi text_fr
    )
    expect(Post.globalize_attribute_names).to contain_exactly(*globalize_attribute_names)
  end

  it do
    automatic_translation_attribute_names = %i(
      title_ja_automatically title_en_automatically title_zh_hans_automatically title_zh_hant_automatically
      title_ko_automatically title_th_automatically title_vi_automatically title_fr_automatically text_ja_automatically
      text_en_automatically text_zh_hans_automatically text_zh_hant_automatically
      text_ko_automatically text_th_automatically text_vi_automatically text_fr_automatically
    )
    expect(Post.automatic_translation_attribute_names).to contain_exactly(*automatic_translation_attribute_names)
  end
=end

end
