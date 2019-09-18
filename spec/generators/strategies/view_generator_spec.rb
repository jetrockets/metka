# frozen_string_literal: true

require 'spec_helper'
require 'generators/metka/strategies/view/view_generator'

RSpec.describe Metka::Generators::Strategies::ViewGenerator, type: :generator do
  destination File.expand_path('../../tmp', __dir__)

  let(:args) { ['--source-table-name=notes'] }

  before do
    prepare_destination
    run_generator(args)
  end

  describe 'trigger migration' do
    subject { migration_file('db/migrate/create_tagged_notes_view.rb') }

    it 'creates migration', :aggregate_failures do
      is_expected.to exist
      is_expected.to contain(/CREATE OR REPLACE VIEW tagged_notes/i)
    end
  end
end
