require 'spec_helper'

module RgGen::Core::Configuration
  describe YAMLLoader do
    let(:loader) { YAMLLoader }

    describe ".support?" do
      let(:files) { ['foo.yaml', 'foo.yml'] }

      it "yaml/yml形式のファイルに対応する" do
        files.each do |file|
          expect(loader.support?(file)).to be true
        end
      end
    end

    describe ".load_file" do
      let(:valid_value_lists) { [[:foo, :bar, :baz]] }

      let(:input_data) { RgGen::Core::InputBase::InputData.new(valid_value_lists) }

      let(:file) { 'foo.yaml' }

      let(:file_contents) do
        <<'YAML'
foo: 0
bar: 1
baz: 2
YAML
      end

      before do
        allow(File).to receive(:readable?).and_return(true)
        allow(File).to receive(:binread).and_return(file_contents)
      end

      before do
        loader.load_file(file, input_data, valid_value_lists)
      end

      it "入力ファイルを元に、入力データを組み立てる" do
        expect(input_data).to have_values([:foo, 0, file], [:bar, 1, file], [:baz, 2, file])
      end
    end
  end
end