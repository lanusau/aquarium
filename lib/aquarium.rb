# Aquarium is a simple tool to parse and apply database changes stored
# in change files.
#
# Author::    Laimonas Anusauskas
# Copyright:: Copyright (c) 2014 United Online, Inc.
# License::   MIT
       
module Aquarium
  autoload :CommandLine, 'aquarium/command_line'
  autoload :Parser, 'aquarium/parser'
  autoload :Database, 'aquarium/database'
  autoload :ChangeCollection, 'aquarium/change_collection'
  autoload :Change, 'aquarium/change'

  module Executors
    autoload :ApplyChange, 'aquarium/executors/apply_change'
    autoload :RollbackChange, 'aquarium/executors/rollback_change'
  end
end
