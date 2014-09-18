require 'aquarium/sql_collection'

module Aquarium

  # SQL collection that depends on specified condition
  class ConditionalSqlCollection < Aquarium::SqlCollection

    # Create new object with specified condition
    # Condition is an SQL statement returning value of 0 or greater in first column
    # If value is greater than 0, condition is considered to be true, otherwise fals
    # Expected result is boolean value (true|false), if matches that of condition,
    # SQL statements will be included.
    def initialize(condition,expected_result)
      @condition = condition
      @expected_result = expected_result
      super()
    end

    # Return printable value of condition
    def conditional_sql            
      return [
        "--##{@expected_result ? "if": "ifnot"} #{@condition}\n"
      ].concat(@sql_collection)

    end

    # Return list of SQLs for particular database
    def to_a(database)

      return conditional_sql if database.nil?
      database.condition_met?(@condition,@expected_result) ? @sql_collection : []

    end
  end
end
