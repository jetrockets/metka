# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Metka::BaseQuery do
  let!(:model) { Post }
  let!(:column_name) { 'tags' }
  let!(:tag_list) { ['ruby'] }

  let(:klass) { described_class }

  describe '.call' do
    it 'responds to .call' do
      expect(klass.instance).to respond_to(:call)
    end

    it 'returns Arel::Nodes::Equality object' do
      expect(klass.instance.call(model, column_name, tag_list).class).to eq(
        Arel::Nodes::Equality
      )
    end

    it 'returns correct sql' do
      expect(klass.instance.call(model, column_name, tag_list).to_sql).to eq(
        "'ruby' = ANY(\"posts\".\"tags\")"
      )
    end
  end
end
