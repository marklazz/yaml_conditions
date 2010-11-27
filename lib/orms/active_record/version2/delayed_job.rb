module Orms
  module ActiveRecordVersion2
    module DelayedJob

      def self.included(base)
        base.send(:include, InstanceMethods)
        base.extend(ClassMethods)
      end

      module InstanceMethods
      end

      module ClassMethods

        CLASS_STRING_FORMAT = /^CLASS\:([A-Z][\w\:]+)$/
        AR_STRING_FORMAT    = /^AR\:([A-Z][\w\:]+)\:(\d+)$/
        LOAD_AR_STRING_FORMAT    = /^LOAD;([A-Z][\w\:]+);(\d+)$/

        def __prepare_yaml_conditions__(yaml_conditions)
          return yaml_conditions if yaml_conditions.has_key?(:handler) || yaml_conditions.has_key?('handler')
          { :handler => yaml_conditions }
        end

        def __delayed_job_ar_to_string_(obj)
          Delayed::PerformableMethod.new(obj, :to_s, []).object
        end

        def __delayed_job_class_to_string_(obj)
          Delayed::PerformableMethod.new(obj, :to_s, []).object
        end

        def __serialize__to_yaml_value__(arg)
          case arg
            when Class              then __delayed_job_class_to_string_(arg)
            when ActiveRecord::Base then __delayed_job_ar_to_string_(arg)
            else super(arg)
          end
        end

        def __yaml_load_object_recursively__(arg)
          case arg
            when CLASS_STRING_FORMAT then $1.constantize
            when AR_STRING_FORMAT    then $1.constantize.find($2)
            when LOAD_AR_STRING_FORMAT then $1.constantize.find($2)
            else super(arg)
          end
        end
      end
    end
  end
end
