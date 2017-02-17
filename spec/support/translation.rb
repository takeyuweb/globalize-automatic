RSpec.shared_examples 'Globalize::Automatic::Translation' do |automatic_translation_class, attr_name|

  let(:automatic_translation) do
    stub_model(automatic_translation_class, locale: :en) { |obj| obj.create_automatic_translated_model }
  end

  describe '#translate(attr_name)' do
    context 'When attr_name is the target of automatic translation.' do
      before do
        allow(automatic_translation).to receive_messages(automatically_for?: true)
      end

      it 'Persist an argument when it is not persisted.' do
        automatic_translation.as_new_record
        expect(automatic_translation).to receive(:save).and_return(true)
        automatic_translation.translate(attr_name)
      end

      describe 'launch the translation job' do
        before { @asynchronously = Globalize::Automatic.asynchronously }
        after { Globalize::Automatic.asynchronously = @asynchronously }

        it 'run perform_now(automatic_translation, stringify attr_name) when the asynchronously disabled.' do
          Globalize::Automatic.asynchronously = false
          expect(Globalize::Automatic::TranslationJob).to receive(:perform_now).with(automatic_translation, attr_name.to_s)
          automatic_translation.translate(attr_name)
        end

        it 'run perform_now(automatic_translation, stringify attr_name) when the asynchronously enabled.' do
          Globalize::Automatic.asynchronously = true
          expect(Globalize::Automatic::TranslationJob).to receive(:perform_later).with(automatic_translation, attr_name.to_s)
          automatic_translation.translate(attr_name)
        end
      end
    end

    context 'When attr_name is not the target of automatic translation.' do
      before do
        allow(automatic_translation).to receive_messages(automatically_for?: false)
      end

      it 'Not persist an argument when it is not persisted.' do
        automatic_translation.as_new_record
        expect(automatic_translation).to_not receive(:save)
        automatic_translation.translate(attr_name)
      end

      describe 'Does not launch the job' do
        before { @asynchronously = Globalize::Automatic.asynchronously }
        after { Globalize::Automatic.asynchronously = @asynchronously }

        it 'run perform_now(automatic_translation, stringify attr_name) when the asynchronously disabled.' do
          Globalize::Automatic.asynchronously = false
          expect(Globalize::Automatic::TranslationJob).to_not receive(:perform_now)
          automatic_translation.translate(attr_name)
        end

        it 'run perform_now(automatic_translation, stringify attr_name) when the asynchronously enabled.' do
          Globalize::Automatic.asynchronously = true
          expect(Globalize::Automatic::TranslationJob).to_not receive(:perform_later)
          automatic_translation.translate(attr_name)
        end
      end

    end

  end
end
