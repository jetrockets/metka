# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Metka::AnyTagsQuery do
  let!(:model) { Post }
  let!(:column_name) { 'tags' }
  let!(:tag_list) { ['ruby', 'rails'] }

  let(:klass) { described_class }

  describe '.call' do
    it 'responds to .call' do
      expect(klass.instance).to respond_to(:call)
    end

    it 'returns Arel::Nodes::InfixOperation object' do
      expect(klass.instance.call(model, column_name, tag_list).class).to eq(
        Arel::Nodes::InfixOperation
      )
    end

    it 'returns correct sql' do
      expect(klass.instance.call(model, column_name, tag_list).to_sql).to eq(
        "\"posts\".\"tags\" && ARRAY['ruby','rails']::varchar[]"
      )
    end
  end
end
