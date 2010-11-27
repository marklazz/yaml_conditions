module Orms
  module ActiveRecordVersion2

    include Yaml::Conditions
    include Yaml::QueryBuilder

    def __include_delayedjob_adapter_if_necessary__
      self.send(:include, ::Orms::ActiveRecordVersion2::DelayedJob)
      @delayed_adapter_included = true
    end

    def find_with_yaml_conditions(*args)
      options = args.last.is_a?(::Hash) ? args.last : {}
      yaml_conditions = options[:yaml_conditions]
      return find_without_yaml_conditions(*args) if yaml_conditions.blank?
      __include_db_adapter_if_necessary__ if @db_adapter_included.nil?
      __include_delayedjob_adapter_if_necessary__ if defined?(Delayed::Job) && self == Delayed::Job && @delayed_adapter_included.nil?
      options = args.extract_options!
      adapted_args = args << refactor_options(options)
      selector = adapted_args.shift
      result = find_without_yaml_conditions(:all, *adapted_args).select do |o|
          __check_yaml_nested_hierarchy__(o, __prepare_yaml_conditions__(yaml_conditions))
      end
      selector == :all ? result : result.send(selector.to_sym)
    end

    def refactor_options(options)
      sql_conditions = sanitize_sql(options.delete(:conditions))
      yaml_conditions = __prepare_yaml_conditions__(options.delete(:yaml_conditions))
      yaml_conditions.symbolize_keys! if yaml_conditions.is_a?(Hash)
      options.merge!({ :conditions => __join_yaml_conditions__(sql_conditions, __build_yaml_conditions__(yaml_conditions)) })
    end
  end
end

module ActiveRecord
  class Base
   class << self
     include Orms::ActiveRecordVersion2

     alias_method :find_without_yaml_conditions, :find
     alias_method :find, :find_with_yaml_conditions
    end
  end
end
