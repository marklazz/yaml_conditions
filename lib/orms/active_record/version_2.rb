module Orms
  module ActiveRecordVersion2

   include Yaml::Conditions

    def __build_yaml_conditions__(yaml_conditions)
      yaml_conditions.inject("") do |conditions, (serialized_field,v)|
        __join_yaml_conditions__(conditions, __build_yaml_attributes__(serialized_field, v))
      end
    end

    def __build_individual_yaml_conditions__(field, k,v)
      "#{field} LIKE '%#{k}: #{v.is_a?(Symbol) ? ':' + v.to_s : v}%' "
    end

    def __build_yaml_attributes__(field, yaml_conditions)
      current_conditions = ''
      __filter_yaml_attributes_to_check_on__(yaml_conditions).each do |k,v|
        conditions = if v.is_a?(Hash)
          __build_yaml_attributes__(field, v)
        else
          __build_individual_yaml_conditions__(field, k, v)
        end
        current_conditions = __join_yaml_conditions__(current_conditions, conditions)
      end
      current_conditions
    end

    def __check_yaml_nested_hierarchy__(value, yaml_conditions)
      return value == yaml_conditions unless yaml_conditions.is_a?(Hash)
      yaml_conditions.inject(true) do |accept, (field, conditions)|
        accept &= begin
          nested_value = __yaml_method_or_key__(value, field)
          if conditions.is_a?(Hash)
            (conditions[:class].blank? || __yaml_same_class__(conditions[:class].to_s, nested_value)) &&
            __check_yaml_nested_hierarchy__(nested_value, __filter_yaml_attributes_to_check_on__(conditions.symbolize_keys!))
          else
            __check_yaml_nested_hierarchy__(nested_value, conditions)
          end
        end
      end
    end

    def __yaml_method_or_key__(object, key)
      value = if object.is_a?(Hash)
        object.symbolize_keys![key.to_sym]
      elsif object.respond_to?(key.to_sym)
        object.send(key)
      end
      if value.is_a?(String)
        __yaml_load_object_recursively__(value)
      else
        value
      end
    rescue
        nil
    end

    def __yaml_load_object_recursively__(object)
      yaml_object = __yaml_deserialize__(object)
      if yaml_object.respond_to?(:value) && yaml_object.respond_to?(:type_id) && yaml_object.type_id == 'struct'
        yaml_object = yaml_object.value
        yaml_object = yaml_object.keys.inject(yaml_object) do |yobject, key|
          yobject[key] = yobject[key].is_a?(String) ? __yaml_load_object_recursively__(yobject[key]) : yobject[key]
          yobject
        end
        yaml_object[:class] = yaml_object.class.to_s
        yaml_object
      else
        yaml_object
      end
    end

    def __yaml_deserialize__(source)
      handler = YAML.load(source) rescue nil

      unless handler.present?
        if handler.nil? && source =~ ParseObjectFromYaml
          handler_class = $1
        end
        __attempt_to_load__(handler_class || handler.class) rescue nil
        handler = YAML.load(source)
      end
      handler
    end

    def __attempt_to_load__(klass)
       klass.constantize
    end

    def __yaml_same_class__(class_string, nested_value)
      klazz_s = class_string.gsub('Struct::', '')
      klazz =  klazz_s.constantize rescue nil
      struct_klazz = nested_value.class.to_s[/^Struct::(.*)$/, 1]
      klazz.present? && nested_value.is_a?(klazz) || struct_klazz.present? && struct_klazz == klazz_s
    end

    def __filter_yaml_attributes_to_check_on__(yaml_conditions)
      yaml_conditions.reject { |k,v| k.to_s == 'class' }
    end

    def __join_yaml_conditions__(current_conditions, conditions)
      if current_conditions.blank?
        conditions
      elsif conditions.blank?
        current_conditions
      else
        [ "(#{conditions})", "(#{current_conditions})" ].join(' AND ')
      end
    end

    def find_with_yaml_conditions(*args)
      options = args.last.is_a?(::Hash) ? args.last : {}
      yaml_conditions = options[:yaml_conditions]
      return find_without_yaml_conditions(*args) if yaml_conditions.blank?
      options = args.extract_options!
      adapted_args = args << refactor_options(options)
      objects = find(*adapted_args)
      case objects
        when Array
          objects.select { |o| __check_yaml_nested_hierarchy__(o, yaml_conditions) }
        when Object
          objects if __check_yaml_nested_hierarchy__(objects, yaml_conditions)
      end
    end

    def refactor_options(options)
      sql_conditions = sanitize_sql(options.delete(:conditions))
      yaml_conditions = options.delete(:yaml_conditions)
      yaml_conditions.symbolize_keys! if yaml_conditions.is_a?(Hash)
      options.merge!({ :conditions => __join_yaml_conditions__(sql_conditions, __build_yaml_conditions__(yaml_conditions)) })
    end
  end

  module DelayedJob
    extend self
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
