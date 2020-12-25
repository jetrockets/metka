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

  describe 'custom delimeters' do
    around do |example|
      delimiter = Metka.config.delimiter
      example.run
      Metka.config.delimiter = delimiter
    end

    it 'should work with utf8 delimiter' do
      Metka.config.delimiter = '的'
      parsed_data = subject.call('我的东西可能是不见了，还好有备份')
      expect(parsed_data.to_a).to eq(%w[我 东西可能是不见了，还好有备份])
    end

    it 'should escape single quote' do
      parsed_data = subject.call("'I, have', code")
      expect(parsed_data.to_a).to eq(['I, have', 'code'])
    end
  end
end
