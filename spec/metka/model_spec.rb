# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Metka::Model do
  let(:klass) { TaggableModel }
  let(:model) { klass.new }

  context 'class methods' do
    describe '#tagged_with' do
      it 'should respond to #tagged_with method' do
        expect(klass).to respond_to(:tagged_with)
      end

      it 'should return an empty scope for empty tags' do
        ['', ' ', nil, []].each do |tag|
          expect(TaggableModel.tagged_with(tag)).to be_empty
        end
      end
    end
  end
end