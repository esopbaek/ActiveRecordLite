require_relative '02_searchable'
require 'active_support/inflector'

# Phase IVa
class AssocOptions
  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key
  )

  def model_class
    class_name.constantize
  end

  def table_name
    model_class.table_name
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    @foreign_key = options[:foreign_key] ? options[:foreign_key] : "#{name}_id".to_sym
    @class_name = options[:class_name] ? options[:class_name] : "#{name}".camelcase
    @primary_key = options[:primary_key] ? options[:primary_key] : :id
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    @foreign_key = options[:foreign_key] ? options[:foreign_key] : "#{self_class_name}Id".underscore.to_sym
    @class_name = options[:class_name] ? options[:class_name] : "#{name}".camelcase.singularize
    @primary_key = options[:primary_key] ? options[:primary_key] : :id
  end
end

module Associatable
  # Phase IVb
  def belongs_to(name, options = {})
    self.assoc_options[name] = BelongsToOptions.new(name, options)
    
    define_method(name) do
      options = BelongsToOptions.new(name, options)
      key_val = self.send(options.foreign_key)
      options.model_class.where(options.primary_key => key_val).first
    end
  end

  def has_many(name, options = {})
    self.assoc_options[name] = HasManyOptions.new(name, self.name, options)
    
    define_method(name) do
      options = self.class.assoc_options[name]
      key_val = self.send(options.primary_key)
      options.model_class.where(options.foreign_key => key_val)
    end
  end
  
  def assoc_options
    @assoc_options ||= {}
  end
end

class SQLObject
  extend Associatable
end
