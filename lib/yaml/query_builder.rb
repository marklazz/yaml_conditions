module Yaml
  module QueryBuilder

    ParseObjectFromYaml = /\!ruby\/\w+\:([^\s]+)/

    def __include_db_adapter_if_necessary__
      adapter_name = self.connection.adapter_name
      adapter_capitalized = adapter_name.upcase[0].chr + adapter_name.downcase[1..-1]
      adapter_module = ::Yaml::QueryBuilder::Sql.const_get("#{adapter_capitalized}Adapter".to_sym)
      self.send(:include, adapter_module)
      @db_adapter_included = true
    end

    def __build_yaml_conditions__(yaml_conditions)
      yaml_conditions.inject("") do |conditions, (serialized_field,v)|
        __join_yaml_conditions__(conditions, __build_yaml_attributes__(serialized_field, v))
      end
    end

    def __prepare_yaml_conditions__(yaml_conditions)
      yaml_conditions
    end

    def __serialize__to_yaml_value__(v)
      return '' if v.nil?
      v_s = v.to_s
      v_s == '*' ? "" : v_s
    end

    def __build_yaml_conditions_for_list__(field, k,v)
      v.map { |item| __resolve_yaml_conditions_by_structure__(field, k, item, true) }.join('AND ')
    end


    def __build_individual_yaml_conditions__(field, k,v, skip_key = false)
      return "1 = 1" if v.is_a?(Yaml::NotSerializedField)
      key_s = skip_key ? '' : "#{k}: "
      "#{field} LIKE '%#{key_s}#{v.is_a?(Symbol) ? ':' + v.to_s : __serialize__to_yaml_value__(v)}%' "
    end

    def __resolve_yaml_conditions_by_structure__(field, k, v, skip_key = false)
      if v.is_a?(Hash)
        __build_yaml_attributes__(field, v, skip_key)
      elsif v.is_a?(Array)
        __build_yaml_conditions_for_list__(field, k, v)
      else
        __build_individual_yaml_conditions__(field, k, v, skip_key)
      end
    end

    def __build_yaml_attributes__(field, yaml_conditions, skip_key = false)
      current_conditions = ''
      __filter_yaml_attributes_to_check_on__(yaml_conditions).each do |k,v|
        conditions = __resolve_yaml_conditions_by_structure__(field, k, v, skip_key)
        current_conditions = __join_yaml_conditions__(current_conditions, conditions)
      end
      current_conditions
    end

    def __check_yaml_nested_hierarchy_on_list__(value, yaml_conditions)
      return false if !value.is_a?(Array)
      yaml_conditions = if value.length != yaml_conditions.length
        if value.length > yaml_conditions.length
          yaml_conditions + (['*'] * (value.length - yaml_conditions.length))
        else
          yaml_conditions[0..-1+(value.length-yaml_conditions.length)]
        end
      else
        yaml_conditions
      end
      yaml_conditions.zip(value).inject(true) do |result, (cond, nested_value)|
          result &= __check_yaml_nested_hierarchy__(nested_value, cond)
      end
    end

    def __check_yaml_nested_hierarchy__(value, yaml_conditions)
      return true if value.nil? && yaml_conditions.nil? || yaml_conditions == '*'
      return false if value.nil? || yaml_conditions.nil?
      unless yaml_conditions.is_a?(Hash) || yaml_conditions.is_a?(Array)
        object_built_from_conds = value.is_a?(String) ? __yaml_load_object_recursively__(value) : value
        return yaml_conditions == object_built_from_conds
      end
      return __check_yaml_nested_hierarchy_on_list__(value, yaml_conditions) if yaml_conditions.is_a?(Array)
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
        object[key.to_sym] || object[key.to_s]
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
      return nil if object.nil?
      return object.map { |v| __yaml_load_object_recursively__(v) } if object.is_a?(Array)
      if object.is_a?(Hash)
        return object.keys.inject({}) do |result, k|
          result[__yaml_load_object_recursively__(k).to_sym] = __yaml_load_object_recursively__(object[k])
          result
        end
      elsif object.is_a?(Symbol)
        return object
      end
      yaml_object = __yaml_deserialize__(object)
      if yaml_object.is_a?(Struct) || (yaml_object.respond_to?(:value) && yaml_object.respond_to?(:type_id) && yaml_object.type_id == 'struct')
        yaml_object = yaml_object.respond_to?(:value) ? yaml_object.value : yaml_object
        keys = yaml_object.respond_to?(:members) ? yaml_object.members : yaml_object.keys
        yaml_object = keys.inject(yaml_object) do |yobject, key|
          value = yobject.respond_to?(key.to_sym) ? yobject.send(key.to_sym) : yobject[key]
          yobject[key] = begin
            if value.is_a?(Array) || value.is_a?(String)
              __yaml_load_object_recursively__(value)
            else
              value
            end
          end
          yobject
        end
        yaml_object[:class]=(yaml_object.class.to_s) unless yaml_object.is_a?(Struct)
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
      yaml_conditions.reject { |k,v| k.to_s == 'class' || k.to_s == 'flat_check' }
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
  end
end
