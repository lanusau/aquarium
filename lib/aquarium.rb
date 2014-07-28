module Aquarium
  autoload :CommandLine, 'aquarium/command_line'
  autoload :Parser, 'aquarium/parser'
  autoload :Database, 'aquarium/database'

  module Executors
    autoload :ApplyChange, 'aquarium/executors/apply_change'
    autoload :RollbackChange, 'aquarium/executors/rollback_change'
  end
end
