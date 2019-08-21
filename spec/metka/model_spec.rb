# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Metka::Model, :db do  
  context 'class methods' do
    let(:klass) { TaggableModel }
    let(:taggable) do
      klass.new.tap do |u|
        u.tag_list = 'ruby, rails, crystal'
      end
    end
    
    describe '#tagged_with' do
      it 'should respond to #tagged_with method' do
        expect(klass).to respond_to(:tagged_with)
      end

      it 'should return an empty scope for empty tags' do
        ['', ' ', nil, []].each do |tag|
          expect(TaggableModel.tagged_with(tag)).to be_empty
        end
      end

      it 'should be able to find by tag' do
        taggable.save!
        expect(TaggableModel.tagged_with('ruby').first).to eq(taggable)
      end
    end
  end
end