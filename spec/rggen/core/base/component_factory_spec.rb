# frozen_string_literal: true

require 'spec_helper'

module RgGen::Core::Base
  describe ComponentFactory do
    def define_factory(&body)
      Class.new(ComponentFactory) do
        def finalize(component)
        end

        body && class_eval(&body)
      end
    end

    let(:component_name) { 'component' }

    let(:component_class) { Class.new(Component) }

    let(:child_component_class) { Class.new(Component) }

    let(:child_factory) do
      define_factory.new(component_name) { |f| f.target_component child_component_class }
    end

    let(:feature_factory_class) do
      Class.new(FeatureFactory) do
        def create(component, *args)
          create_feature(component, *args)
        end
      end
    end

    let(:foo_feature) { Class.new(Feature) }

    let(:foo_feature_factory) do
      feature_factory_class.new(:foo) { |f| f.target_feature foo_feature }
    end

    let(:bar_feature) { Class.new(Feature) }

    let(:bar_feature_factory) do
      feature_factory_class.new(:bar) { |f| f.target_feature bar_feature }
    end

    let(:parent) { Class.new(Component).new(component_name) }

    let(:arguments) { [2, 1] }

    describe '#create' do
      let(:factory) do
        define_factory.new(component_name) { |f| f.target_component component_class }
      end

      it '#target_componentで登録されたコンポーネントオブジェクトを生成する' do
        component = factory.create(parent, *arguments)
        expect(component).to be_instance_of(component_class)
      end

      specify 'コンポーネントオブジェクトは、ファクトリ生成時に指定されたコンポーネント名を持つ' do
        component = factory.create(parent, *arguments)
        expect(component.component_name).to eq component_name
      end

      context 'ルートファクトリのとき' do
        before { factory.root_factory }

        it 'ルートコンポーネントを生成する' do
          component = factory.create
          expect(component.parent).to be_nil
        end

        it '引数すべてに対して、#preprocessを実行し、引数の前処理を行う' do
          allow(factory).to receive(:preprocess).and_call_original
          factory.create(*arguments)
          expect(factory).to have_received(:preprocess).with(match(arguments))
        end

        it '#finalizeを実行し、仕上げ処理を行う' do
          allow(factory).to receive(:finalize)
          component = factory.create
          expect(factory).to have_received(:finalize).with(equal(component))
        end
      end

      context 'ルートファクトリではないとき' do
        it '親コンポーネントの子コンポーネントを生成する' do
          component = factory.create(parent)
          expect(component.parent).to equal parent
        end

        it '#add_childを呼び出して、親コンポーネントに生成したコンポーネントを登録する' do
          allow(parent).to receive(:add_child).and_call_original
          component = factory.create(parent)
          expect(parent).to have_received(:add_child).with(equal(component))
        end

        it '先頭の親コンポーネントを除いた引数に対して、#preprocessを呼び出して、引数の前処理を行う' do
          allow(factory).to receive(:preprocess).and_call_original
          factory.create(parent, *arguments)
          expect(factory).to have_received(:preprocess).with(match(arguments))
        end

        it '仕上げ処理は行わない' do
          expect(factory).not_to receive(:finalize)
          factory.create(parent)
        end
      end

      context '子コンポーネントファクトリが登録されているとき' do
        let(:factory) do
          define_factory {
            def create_children(component, *args)
              args[0].times { create_child(component, args[1]) }
            end
          }.new(component_name) { |f|
            f.target_component component_class
            f.child_factory child_factory
          }
        end

        it '子コンポーネントを含むコンポーネントオブジェクトを生成する' do
          component = factory.create(parent, *arguments)
          expect(component.children).to match [
            be_instance_of(child_component_class), be_instance_of(child_component_class)
          ]
        end

        context '生成したコンポーネントが子コンポーネントを必要としない場合' do
          before do
            allow_any_instance_of(component_class).to receive(:need_children?).and_return(false)
          end

          it '子コンポーネントを含まないコンポーネントオブジェクトを生成する' do
            expect(child_factory).not_to receive(:create)
            component = factory.create(parent, *arguments)
            expect(component.children).to be_empty
          end
        end
      end

      context 'フィーチャーファクトリが登録されているとき' do
        let(:factory) do
          define_factory {
            def create_features(component, *args)
              @feature_factories.each_value { |f| create_feature(component, f, *args) }
            end
          }.new(component_name) { |f|
            f.target_component Class.new(Component)
            f.feature_factories(foo: foo_feature_factory, bar: bar_feature_factory)
          }
        end

        it 'フィーチャーを含むコンポーネントオブジェクトを生成する' do
          component = factory.create(parent)
          expect(component.features).to match [
            be_instance_of(foo_feature), be_instance_of(bar_feature)
          ]
        end
      end

      it 'フィーチャー、及び、子コンポーネント生成後に #post_build を呼び出す' do
        captured_values = []

        factory = define_factory {
          def create_features(component, *args)
            @feature_factories.each_value { |f| create_feature(component, f, *args) }
          end
          def create_children(component, *args)
            2.times { create_child(component, *args) }
          end
          define_method(:post_build) do |component|
            captured_values << component.parent.children.size
            captured_values << component.children.size
            captured_values << component.features.size
          end
        }.new(component_name) do |f|
          f.target_component Class.new(Component)
          f.feature_factories(foo: foo_feature_factory, bar: bar_feature_factory)
          f.child_factory(child_factory)
        end

        factory.create(parent)
        expect(captured_values).to match([0, 2, 2])
      end
    end
  end
end
