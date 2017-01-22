class Globalize::Automatic::Translation < ActiveRecord::Base
  self.abstract_class = true

  def from_locale
    :en
  end

  def translation_from
    automatic_translated_model.translation_for(from_locale)
  end

  def translation_to
    automatic_translated_model.translation_for(locale)
  end

  def resolve(attr_name, translated)

  end

  def reject

  end

  class << self
    def create_table!(*fields)
      connection.create_table(table_name) do |t|
        t.references automatic_translated_model_foreign_key.sub(/_id$/, ''), null: false, index: false
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

    private
    def automatically_column_name(field)
      :"#{field}_automatically"
    end

    def automatically_column_args(field)
      args = [automatically_column_name(field), default: false, null: false]
    end
  end

end
