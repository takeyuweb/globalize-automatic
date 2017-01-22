RSpec.shared_examples 'Globalize::Automatic::TranslationJob' do |job_class|

  let(:attr_name) { :title }
  let(:automatic_translation) { double(Globalize::Automatic::Translation) }

  describe '#perform' do

    it do
      expect(Globalize::Automatic.translator).to receive(:run).with(automatic_translation, attr_name)
      job_class.perform_now(automatic_translation, attr_name)
    end

  end

end