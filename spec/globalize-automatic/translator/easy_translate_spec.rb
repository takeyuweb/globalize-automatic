# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Globalize::Automatic::Translator::EasyTranslate do
  before do
    allow(::EasyTranslate).to receive_messages(translate: 'TRANSLATED')
  end

  it_behaves_like 'Globalize::Automatic::Translator', Globalize::Automatic::Translator::EasyTranslate.new

  describe '#translate(text, from, to)' do
    let(:translator) { Globalize::Automatic::Translator::EasyTranslate.new }
    let(:text) { 'TEXT' }
    let(:from) { :en }
    let(:to) { :ja }

    it 'call EasyTranslate#translate(text, from: from, to: to)' do
      expect(::EasyTranslate).to receive(:translate).with(text, from: from, to: to).and_return('TRANSLATED')
      translator.translate(text, from, to)
    end

    it 'returns TRANSLATED' do
      expect(translator.translate(text, from, to)).to eq('TRANSLATED')
    end
  end
end