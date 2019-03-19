# frozen_string_literal: true

require 'spec_helper'

module RgGen::Core::Utility
  describe AttributeSetter do
    def create_test_object(&block)
      klass = Class.new do
        include AttributeSetter
      end
      klass.class_eval(&block)
      klass.new
    end

    let(:attributes) do
      { foo: rand(99), bar: rand(99) }
    end

    describe '.define_attribute' do
      it 'アトリビュートを定義する' do
        object = create_test_object do
          define_attribute :foo
          define_attribute :bar
        end

        object.foo(attributes[:foo])
        object.bar(attributes[:bar])

        expect(object.foo).to eq attributes[:foo]
        expect(object.bar).to eq attributes[:bar]
      end

      it '既定値を指定できる' do
        object = create_test_object do
          define_attribute :foo, :default_foo
        end

        expect(object.foo).to eq :default_foo

        object.foo(attributes[:foo])
        expect(object.foo).to eq attributes[:foo]
      end

      context '規定値としてブロックを与えた場合' do
        it 'オブジェクト上で実行した結果を規定値として返す' do
          object = create_test_object do
            define_attribute :foo, ->{ default_foo }
            def default_foo; :default_foo; end
          end

          expect(object.foo).to eq :default_foo

          object.foo(attributes[:foo])
          expect(object.foo).to eq attributes[:foo]
        end
      end
    end

    describe '#apply_attributes' do
      it 'アトリビュートを一括で設定する' do
        object = create_test_object do
          define_attribute :foo, :default_foo
          define_attribute :bar, :default_bar
          define_attribute :baz, :default_baz
        end

        object.apply_attributes(**attributes)

        expect(object.foo).to eq attributes[:foo]
        expect(object.bar).to eq attributes[:bar]
        expect(object.baz).to eq :default_baz
      end
    end
  end
end
