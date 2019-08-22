# frozen_string_literal: true

require "spec_helper"

RSpec.describe Metka::GenericParser do
  subject { Metka::GenericParser.instance }

  it "should return empty array if empty tag is passed" do
    ["", " ", nil, []].each do |tag|
      expect(subject.call(tag)).to be_empty
    end
  end

  it "should separate tags by comma" do
    expect(subject.call("cool,data,,I,have").to_a).to eq(%w[cool data I have])
  end
end
