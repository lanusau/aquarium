ENV['NLS_LANG']='AMERICAN_AMERICA.US7ASCII'

require 'simplecov'
SimpleCov.start do
  add_filter "spec/"
end

RSpec::Expectations.configuration.warn_about_potential_false_positives = false

require_relative '../lib/aquarium/change'
require_relative '../lib/aquarium/change_collection'
require_relative '../lib/aquarium/conditional_sql_collection'
require_relative '../lib/aquarium/sql_collection'
require_relative '../lib/aquarium/tag'
require_relative '../lib/aquarium/parser'
require_relative '../lib/aquarium/database'
require_relative '../lib/aquarium/executor'
require_relative '../lib/aquarium/command_line'


def silence_stream(stream)
  old_stream = stream.dup
  stream.reopen('/dev/null')
  stream.sync = true
  yield
ensure
  stream.reopen(old_stream)
  old_stream.close
end