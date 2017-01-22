Globalize Automatic
-

## Installation

```ruby
gem install globalize-automatic
```

### Rails 5.0

In your Gemfile

```ruby
gem 'globalize-automatic', github: 'takeyuweb/globalize-automatic', branch: 'rails-5-0'
```

and

```bash
bundle install
```

## Configuration

```ruby
# config/initializers/globalize_automatic.rb
require 'globalize-automatic'
Globalize::Automatic.translator = 
  Globalize::Automatic::Translator::EasyTranslate.new

# EasyTranslate configuration
EasyTranslate.api_key = 'xxx'
```

## Example

### 宣言

```ruby
class Post
  # Automatically translated from English.
  translates :title, :text, automatic: :en
end
```

```ruby
class Post
  # Automatically translated from English or Japanese. (English preferred)
  translates :title, :text, automatic: %i(en ja)
end
```

```ruby
class Post
  # Automatically translated from English
  translates :title, :text, automatic: { from: :en, to: %i(ja fr vi) }
end
```

```ruby
class CreatePostAutomatics < ActiveRecord::Migration
  def up
    Post.create_translation_table! title: :string, text: :text
    Post.create_automatic_translation_table! :title, :text
  end
    
  def down
    Post.drop_translation_table!
    Post.drop_automatic_translation_table!
  end
end
```

#### 自動翻訳対象を追加

```ruby
class AddPostAutomatics < ActiveRecord::Migration
  def up
    Post.add_translation_fields! description: :text
    Post.add_automatic_translation_fields! :description
  end
    
  def down
    remove_column :post_automatic_translations, :description
    remove_column :post_automatic_translations, :description_automatically
  end
end
```

### 更新

#### 自動翻訳

```ruby
I18n.locale = :en
post.title = 'globalize'
post.save!

post.title_ja_automatic # => false
post.title_vi_automatic # => true

post.reload

I18n.locale = :ja
post.title # => nil
I18n.locale = :vi
post.title # => 'โลกาภิวัฒน์'
```

```ruby
post.attributes = {
   title_en: 'globalize',
   title_ja_automatic: true
}
post.save!

post.reload

I18n.locale = :en
post.title # => 'globalize'
I18n.locale = :ja
post.title # => '国際化'
```

#### 自動翻訳無効化

```ruby
post.attributes = {
   title_en: 'globalize',
   title_fr_automatic: false,
   title_fr: 'Hoge'
}
post.save!

post.reload

I18n.locale = :en
post.title # => 'globalize'
I18n.locale = :vi
post.title # => 'โลกาภิวัฒน์'
I18n.locale = :fr
post.title # => 'hoge'
```

### 自動翻訳の原文優先順位

```ruby
class Post
  # Automatically translated from English or Japanese. (English preferred)
  translates :title, :text, automatic: %i(en ja)
end

post = Post.new
post.attributes = {
    title_en: 'English',
    title_ja: '日本語'
}
post.save!

post.reload

I18n.locale = :fr
post.title # => 'Anglais' # It means 'English'.
```

```ruby
class Post
  # Automatically translated from English or Japanese. (English preferred)
  translates :title, :text, automatic: %i(en ja)
end

post = Post.new
post.attributes = {
    title_en: nil,
    title_ja: '日本語'
}
post.save!

post.reload

I18n.locale = :fr
post.title # => 'Japonais' # It means '日本語'.
```

### 取得

#### 翻訳文属性名

[globalize-accessors](https://github.com/globalize/globalize-accessors)

```ruby
Post.globalize_attribute_names # => [:title_ja, :title_en, :title_fr, :title_vi, :text_ja, :text_en, :text_fr, :text_vi]
```

#### 自動翻訳有効/無効属性名

```ruby
Post.automatic_translation_attribute_names # => [:title_ja_automatically, :title_en_automatically, :title_fr_automatically, :title_vi_automatically, :text_ja_automatically, :text_en_automatically, :text_fr_automatically, :text_vi_automatically]
```

strong parameters

```ruby
permitted = Post.globalize_attribute_names + Post.automatic_translation_attribute_names
params.require(:post).permit(*permitted)
```

### 非同期

ActiveJobを利用による非同期翻訳

```ruby
# config/initializers/globalize_automatic.rb
Globalize::Automatic.asynchronously = true
```

### 他の翻訳ライブラリやサービスへの対応

Translatorクラスを書けば対応できます。

```ruby
class YourTranslator < Globalize::Automatic::Translator
  def translate(text, from, to)
    # 適当な翻訳処理を行って訳文を返す
    return translated
  end
end

Globalize::Automatic.translator = YourTranslator::EasyTranslate.new
```

## TODO

- EasyTranslate依存の切り出し
  - 他の翻訳ライブラリやサービスへの対応。
    - Microsoft Translator
    - Gengo etc


## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/takeyuweb/globalize_automatic. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the Contributor Covenant code of conduct.

## Licence

Copyright (c) 2017 Yuichi Takeuchi released under the MIT license

This project rocks and uses MIT-LICENSE.
