# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Metka::GenericParser do
  subject { Metka::GenericParser.instance }

  it 'should return empty array if empty tag is passed' do
    ['', ' ', nil, []].each do |tag|
      expect(subject.call(tag)).to be_empty
    end
  end

  it 'should separate tags by comma' do
    expect(subject.call('cool,data,,I,have').to_a).to eq(%w[cool data I have])
  end

  describe 'Multiple Delimiter' do
    before do
      @old_delimiter = Metka.config.delimiter
    end

    after do
      Metka.config.delimiter = @old_delimiter
    end

    it 'should separate tags by delimiters' do
      Metka.config.delimiter = [',', ' ', '|']
      parsed_data = subject.call('cool, data|I have')
      expect(parsed_data.to_a).to eq(%w[cool data I have])
    end

    it 'should work for utf8 delimiter and long delimiter' do
      Metka.config.delimiter = ['，', '的', '可能是']
      parsed_data = subject.call('我的东西可能是不见了，还好有备份')
      expect(parsed_data.to_a).to eq(%w[我 东西 不见了 还好有备份])
    end

    it 'should escape single quote' do
      Metka.config.delimiter = [',', ' ', '|']
      parsed_data = subject.call("'I have'|cool, data")

      expect(parsed_data.to_a).to eq(['I have', 'cool', 'data'])
    end

    it 'should escape single quote' do
      parsed_data = subject.call("'I, have', code")
      expect(parsed_data.to_a).to eq(['I, have', 'code'])
    end

    it 'should escape double quote' do
      Metka.config.delimiter = [',']
      parsed_data = subject.call('"Ruby Monsters", "eat Katzenzungen"')

      expect(parsed_data.to_a).to eq(['Ruby Monsters', 'eat Katzenzungen'])
    end
  end
end
