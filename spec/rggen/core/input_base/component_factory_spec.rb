# frozen_string_literal: true

require 'spec_helper'

module RgGen::Core::InputBase
  describe ComponentFactory do
    let(:parent) { Component.new('component') }

    let(:factory_class) do
      Class.new(ComponentFactory) do
        def create_input_data(&block)
          InputData.new(valid_value_lists, &block)
        end
      end
    end

    let(:foo_features) do
      {
        foo_0: Class.new(Feature) { build {} }, foo_2: Class.new(Feature), foo_1: Class.new(Feature) { build {} }
      }
    end

    let(:foo_feature_factories) do
      {}.tap do |factories|
        foo_features.each do |feature_name, feature|
          factories[feature_name] = FeatureFactory.new(feature_name) { |f| f.target_feature feature }
        end
      end
    end

    let(:foo_component) { Class.new(Component) }

    let(:foo_factory) do
      factory_class.new('component') do |f|
        f.target_component foo_component
        f.feature_factories foo_feature_factories
        f.child_factory bar_factory
      end
    end

    let(:bar_features) do
      {
        bar_0: Class.new(Feature) { build {} }, bar_1: Class.new(Feature) { build {} }, bar_2: Class.new(Feature)
      }
    end

    let(:bar_feature_factories) do
      {}.tap do |factories|
        bar_features.each do |feature_name, feature|
          factories[feature_name] = FeatureFactory.new(feature_name) { |f| f.target_feature feature }
        end
      end
    end

    let(:bar_component) { Class.new(Component) }

    let(:bar_factory) do
      factory_class.new('component') do |f|
        f.target_component bar_component
        f.feature_factories bar_feature_factories
      end
    end

    let(:valid_value_lists) { [[:foo_0, :foo_1], [:bar_0, :bar_1]] }

    let(:input_data) do
      InputData.new(valid_value_lists) do |data|
        data.foo_0 0; data.foo_1 1;
        data.child { bar_0 2; bar_1 3 }
        data.child { bar_0 4; bar_1 5 }
      end
    end

    let(:other_input_data) { Object.new }

    describe '#create' do
      let(:component) { Component.new('component', parent) }

      before do
        allow(foo_component).to receive(:new).and_wrap_original do |*args, &block|
          block && block.call(component)
          component
        end
      end

      describe 'フィーチャーの生成' do
        describe '能動フィーチャーの生成' do
          it '生成したコンポーネントと、引数の末尾から取り出した入力値を引数として、能動フィーチャーを生成する' do
            expect(foo_feature_factories[:foo_0]).to receive(:create).with(equal(component), equal(input_data[:foo_0])).and_call_original
            expect(foo_feature_factories[:foo_1]).to receive(:create).with(equal(component), equal(input_data[:foo_1])).and_call_original
            foo_factory.create(parent, other_input_data, input_data)
          end
        end

        describe '受動フィーチャーの生成' do
          it '生成したコンポーネントを引数として、受動フィーチャーを生成する' do
            expect(foo_feature_factories[:foo_2]).to receive(:create).with(equal(component)).and_call_original
            foo_factory.create(parent, other_input_data, input_data)
          end
        end

        it '#verifyを呼び出して、コンポーネントの検証を行う' do
          expect(component).to receive(:verify).with(:component).ordered.and_call_original
          expect(parent).to receive(:add_child).ordered.and_call_original
          foo_factory.create(parent, other_input_data, input_data)
        end
      end

      describe '子コンポーネントの生成' do
        it '生成したコンポーネント、子入力データ、及び、残りの引数を用いて、子コンポーネントを生成する' do
          expect(bar_factory).to receive(:create).with(
            equal(component), equal(other_input_data), equal(input_data.children[0])
          ).and_call_original
          expect(bar_factory).to receive(:create).with(
            equal(component), equal(other_input_data), equal(input_data.children[1])
          ).and_call_original
          foo_factory.create(parent, other_input_data, input_data)
        end
      end

      describe '入力データの生成と入力ファイルの読み出し' do
        let(:rb_loader) do
          Class.new(Loader) do
            support_types [:rb]
            def read_file(file)
              input_data.load_file(file)
            end
          end
        end

        let(:foo_load_data) do
          <<~'DATA'
            foo_0 0
          DATA
        end

        let(:bar_load_data) do
          <<~'DATA'
            child { bar_0 1 }
          DATA
        end

        let(:input_files) { ['foo.rb', 'bar.rb'] }

        before do
          foo_factory.root_factory
          foo_factory.loaders [rb_loader]
        end

        before do
          allow(File).to receive(:readable?).and_return(true)
          allow(File).to receive(:binread).with(input_files[0]).and_return(foo_load_data)
          allow(File).to receive(:binread).with(input_files[1]).and_return(bar_load_data)
        end

        it '自身及び配下のコンポーネントの能動フィーチャー一覧を引数として、入力データを生成する' do
          allow(InputData).to receive(:new).and_call_original
          foo_factory.create(other_input_data, input_files)
          expect(InputData).to have_received(:new).with(match(valid_value_lists))
        end

        context '入力するファイルが対応する拡張子を持つ場合' do
          let(:input_datas) { [] }

          before do
            allow(InputData).to receive(:new).and_wrap_original do |m, *args, &block|
              m.call(*args, &block).tap { |input_data| input_datas << input_data }
            end
          end

          it '対応するローダを使って、ファイルを読み出す' do
            allow(rb_loader).to receive(:load_file).and_call_original
            foo_factory.create(other_input_data, input_files)
            expect(rb_loader).to have_received(:load_file).with(input_files[0], equal(input_datas[1]), valid_value_lists)
            expect(rb_loader).to have_received(:load_file).with(input_files[1], equal(input_datas[1]), valid_value_lists)
          end

          specify '読み出したデータは、自身、及び、配下のコンポーネントの組み立てに使われる' do
            allow(foo_feature_factories[:foo_0]).to receive(:create).and_call_original
            allow(bar_factory).to receive(:create).and_call_original

            foo_factory.create(other_input_data, input_files)

            expect(foo_feature_factories[:foo_0]).to have_received(:create).with(anything, equal(input_datas[1][:foo_0]))
            expect(bar_factory).to have_received(:create).with(anything, anything, equal(input_datas[0]))
          end
        end

        context '対応する拡張子を持たない場合' do
          it 'RgGen::Core::LoadErrorを起こす' do
            expect {
              foo_factory.create(other_input_data, ['foo.txt'])
            }.to raise_rggen_error RgGen::Core::LoadError, 'unsupported file type', 'foo.txt'
          end
        end

        context '空のファイルリストを与えた場合' do
          it '欠損値使って、自身の組み立てを行う' do
            expect(foo_feature_factories[:foo_0]).to receive(:create).with(anything, equal(NAValue))
            expect(foo_feature_factories[:foo_1]).to receive(:create).with(anything, equal(NAValue))
            expect(bar_factory).not_to receive(:create)
            foo_factory.create(other_input_data, [])
          end
        end
      end

      describe '生成したコンポーネントの検査' do
        context 'ルートファクトリの場合' do
          let(:loader) do
            Class.new(Loader) do
              def self.support?(file); true end
              def read_file(file); end
            end
          end

          before do
            allow(InputData).to receive(:new).and_return(input_data)
          end

          before do
            foo_factory.root_factory
            foo_factory.loaders [loader]
          end

          it '生成後に、配下のフィーチャー、コンポーネントの統合検証を行う' do
            expect(component).to receive(:add_feature).exactly(3).times.ordered.and_call_original
            expect(component).to receive(:add_child).twice.ordered.and_call_original
            expect(component).to receive(:verify).with(:component).ordered.and_call_original
            expect(component).to receive(:verify).with(:all).ordered.and_call_original

            foo_factory.create(['foo.rb'])
          end
        end

        context 'ルートファクトリではない場合' do
          it '生成したフィーチャー、コンポーネントの検査を行わない' do
            expect(component).not_to receive(:verify).with(:all)
            foo_factory.create(parent, input_data)
          end
        end
      end
    end
  end
end
