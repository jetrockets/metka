# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Metka::AnyTagsQuery do
  let!(:model) { Post }
  let!(:column_name) { 'tags' }
  let!(:tag_list) { ['ruby', 'rails'] }

  let(:klass) { described_class }

  describe '.call' do
    it 'should respond to .call' do
      expect(klass.instance).to respond_to(:call)
    end

    it 'should return Arel::Nodes::InfixOperation object' do
      expect(klass.instance.call(model, column_name, tag_list).class).to eq(
        Arel::Nodes::InfixOperation
      )
    end

    it 'should return correct sql' do
      expect(klass.instance.call(model, column_name, tag_list).to_sql).to eq(
        "CAST(\"posts\".\"tags\" AS text[]) && CAST(ARRAY['ruby','rails'] AS text[])"
      )
    end
  end
end