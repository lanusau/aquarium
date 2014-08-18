module Aquarium
  class ExecutionException < RuntimeError
    attr :index
    attr :sql
    def initialize(sql,index)
      @sql = sql
      @index = index
    end
  end
end