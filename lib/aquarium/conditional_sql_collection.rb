require 'aquarium/sql_collection'
module Aquarium

  class ConditionalSqlCollection < Aquarium::SqlCollection

    def initialize(condition,expected_result)
      @condition = condition
      @expected_result = expected_result
      super()
    end

    def to_a(database)
      dbh = database.dbh
      begin
      row = dbh.select_one(@condition)
      rescue Exception => e
        raise "Error executing conditional SQL -> #{@condition}\n#{e.to_s}"
      end
      result = (!row[0].nil? && row[0] > 0)
      if result  == @expected_result
        @sql_collection
      else
        return []
      end
    end
  end
end
