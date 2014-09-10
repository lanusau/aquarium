require 'simplecov'
SimpleCov.start do
  add_filter "spec/"
end

require_relative '../lib/aquarium/change'
require_relative '../lib/aquarium/change_collection'
require_relative '../lib/aquarium/conditional_sql_collection'
require_relative '../lib/aquarium/sql_collection'
require_relative '../lib/aquarium/tag'
require_relative '../lib/aquarium/parser'
require_relative '../lib/aquarium/database'
