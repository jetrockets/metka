# frozen_string_literal: true

require 'spec_helper'
require 'generators/metka/strategies/materialized_view/materialized_view_generator'

# rubocop:disable RSpec/FilePath
RSpec.describe Metka::Generators::Strategies::MaterializedViewGenerator, type: :generator do
  destination File.expand_path('../../tmp', __dir__)
  subject { migration_file('db/migrate/create_tagged_notes_materialized_view.rb') }

  let(:args) { ['--source-table-name=notes'] }

  before do
    prepare_destination
    run_generator(args)
  end

  describe 'trigger migration' do
    it 'creates migration', :aggregate_failures do
      expect(subject).to exist
    end

    context 'when up migration' do
      it 'creates function' do
        expect(subject).to contain(/CREATE OR REPLACE FUNCTION metka_refresh_tagged_notes_materialized_view/i)
      end

      it 'creates materialized view' do
        expect(subject).to contain(/CREATE MATERIALIZED VIEW tagged_notes/i)
      end

      it 'creates uniq index' do
        expect(subject).to contain(/CREATE UNIQUE INDEX/i)
      end

      it 'creates trigger' do
        expect(subject).to contain(/CREATE TRIGGER metka_on_notes/i)
      end
    end

    context 'when down migration' do
      it 'drop trigger' do
        expect(subject).to contain(/DROP TRIGGER IF EXISTS/i)
      end

      it 'drop function' do
        expect(subject).to contain(/DROP FUNCTION IF EXISTS/i)
      end

      it 'drop materialized view' do
        expect(subject).to contain(/DROP MATERIALIZED VIEW IF EXISTS/i)
      end
    end
  end
end
# rubocop:enable RSpec/FilePath
