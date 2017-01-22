RSpec.shared_examples 'Globalize::Automatic::Translator' do |translator|

  let(:text) { 'TEXT' }
  let(:translated) { 'TRANSLATED' }
  let(:from) { :en }
  let(:to) { :ja }
  let(:attr_name) { :title }
  let(:translation_from) do
    double(Globalize::ActiveRecord::Translation, locale: from, title: text).tap do |obj|
      obj.define_singleton_method(:[]) do |attr_name|
        obj.send(attr_name)
      end
    end
  end
  let(:automatic_translation) do
    double(Globalize::Automatic::Translation,
           locale: to,
           translation_from: translation_from,
           resolve: true)
  end

  before do
    allow(translator).to receive_messages(translate: translated)
  end

  describe '#run' do
    it 'call before_translate(text, from, to)' do
      expect(translator).to receive(:before_translate).with(text, from, to).and_return([text, from, to])
      translator.run(automatic_translation, attr_name)
    end

    it 'call translate(text, from, to)' do
      expect(translator).to receive(:translate).with(text, from, to).and_return(translated)
      translator.run(automatic_translation, attr_name)
    end

    it 'call after_translate(text, from, to, translated)' do
      expect(translator).to receive(:after_translate).with(text, from, to, translated).and_return([text, from, to, translated])
      translator.run(automatic_translation, attr_name)
    end

    it 'call AutomaticTranslation#resolve(attr_name, translated)' do
      expect(automatic_translation).to receive(:resolve).with(attr_name, translated).and_return(true)
      translator.run(automatic_translation, attr_name)
    end
  end

  describe '#before_translate(text, from, to)' do
    it 'returns [new_text, new_from, new_to]' do

    end
  end

  describe '#after_translate(text, from, to)' do
    it 'returns [new_text, new_from, new_to]' do

    end
  end

end