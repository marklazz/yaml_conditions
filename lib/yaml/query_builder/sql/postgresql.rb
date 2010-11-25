module Yaml
  module QueryBuilder
    module Sql
      module PostgresqlAdapter

        def self.included(base)
          base.extend(ClassMethods)
        end

        module ClassMethods
        end
      end
    end
  end
end
