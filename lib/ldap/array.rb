require 'dm-core'
module Ldap
  class Array < ::Array

    def initialize(resource, property,  *args)
      setup(resource, property)
      super(args)
    end

    def setup(resource, property)
      @resource = resource
      @property = property
      self
    end

    alias :push! :push

    def []=(k, v)
      ar = [self].flatten
      ar[k] = v
      @resource.send("#{@property.name}=".to_sym, ar)
      super
    end

    def <<(element)
      push(element)
    end

    def push(element)
      ar = [self].flatten
      ar.push(element)
      @resource.send("#{@property.name}=".to_sym, ar)
      super
    end

   alias :delete! :delete

    def delete(element)
      ar = [self].flatten
      ar.delete(element)
      @resource.send(:"#{@property.name}=", ar)
      super
    end
  end

  class LdapArray < ::DataMapper::Property::Text 
    
    default Proc.new { |r,p| Ldap::Array.new(r,p) }

    def custom?
      true
    end

    def primitive?(value)
      super || value.kind_of?(::Array)
    end

    def load(value)
      result = case value
               when ::String then value.gsub(/^.|.$/,'').split('","').to_a.freeze
               when ::Array then value.freeze
               else
                 []
               end
    end

    def dump(value)
      result = case value
               when LdapArray then '"' + value.join('","') + '"'
               when ::Array then '"' + value.join('","') + '"'
               when ::String then '"' + value.to_s + '"'
               else
                 nil
               end
    end

    def initialize(*args)
      super
      model.class_eval <<-RUBY, __FILE__, __LINE__ + 1
        def #{name.to_s}=(v)
          case v
          when Ldap::Array
            v.setup(self, properties[:#{name}])
          else
            vv = Ldap::Array.new(self, properties[:#{name}])
            vv.replace(v || [])
            v = vv
          end
          attribute_set(:#{name}, v)
        end

        def #{name.to_s}
          v = attribute_get(:#{name})
          case v
          when Ldap::Array
            v.setup(self, properties[:#{name}])
          else
            vv = Ldap::Array.new(self, properties[:#{name}])
            vv.replace(v || [])
          end
        end
      RUBY
    end
  end
end
