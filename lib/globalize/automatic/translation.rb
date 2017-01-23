class Globalize::Automatic::Translation < ActiveRecord::Base
  self.abstract_class = true

  def from_locale(attr_name)
    automatic_translated_model.automatic_translation_locale(attr_name)
  end

  def translation_from(attr_name)
    translation_for(from_locale(attr_name))
  end

  def translation_to
    translation_for(locale)
  end

  def translation_for(target_locale)
    automatic_translated_model.translation_for(target_locale)
  end

  def translate(attr_name)
    if automatically_for?(attr_name)
      Globalize::Automatic.asynchronously ?
          Globalize::Automatic::TranslationJob.perform_later(self, attr_name) :
          Globalize::Automatic::TranslationJob.perform_now(self, attr_name)
    end
  end

  def resolve(attr_name, translated)
    obj = translation_to
    obj.transaction do
      obj.lock!
      obj[attr_name] = translated
      obj.save!(validate: false)
    end
  end

  def reject(attr_name, error); end

  private
  def automatically_for?(attr_name)
    self[self.class.automatically_column_name(attr_name)]
  end

  class << self
    def create_table!(*fields)
      connection.create_table(table_name) do |t|
        t.references automatic_translated_model_foreign_key.sub(/_id$/, ''), null: false
        t.string :locale, null: false
        fields.each do |field|
          t.boolean *automatically_column_args(field)
        end
        t.timestamps null: false
      end
    end

    def drop_table!
      connection.drop_table(table_name)
    end

    def add_fields!(*fields)
      connection.change_table(table_name) do |t|
        fields.each do |field|
          t.boolean *automatically_column_args(field)
        end
      end
    end

    def automatically_column_name(field)
      :"#{field}_automatically"
    end

    private
    def automatically_column_args(field)
      args = [automatically_column_name(field), default: false, null: false]
    end
  end

end
