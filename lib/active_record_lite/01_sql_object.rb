require_relative 'db_connection'
require 'active_support/inflector'
#NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
#    of this project. It was only a warm up.

class SQLObject
  def self.columns
    cols = DBConnection.execute2(<<-SQL)
      SELECT
        *
      FROM
      #{self.table_name}
    SQL
    cols[0].map(&:to_sym)
  end

  def self.finalize!
    self.columns.each do |col|
      define_method(col) do
        attributes[col]
      end

      define_method("#{col}=") do |val|
        attributes[col] = val
      end
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name || self.to_s.tableize
  end

  def self.all
    objs = DBConnection.execute(<<-SQL)
      SELECT
        *
      FROM
      #{self.table_name}
      SQL

      self.parse_all(objs)
  end

  def self.parse_all(results)
    results.map do |res|
      self.new(res)
    end
  end

  def self.find(id)
    sql = <<-SQL
      SELECT
        *
      FROM
        #{self.table_name}
      WHERE
        id = ?
      SQL
      results = DBConnection.execute(sql, id)
      self.parse_all(results).first
  end

  def attributes
    @attributes ||= {}
  end

  def insert
    col_names = self.class.columns.join(",")
    n = self.class.columns.count
    question_marks = (["?"] * n).join(",")
    sql = <<-SQL
    INSERT INTO
      #{self.class.table_name} (#{col_names})
    VALUES
      (#{question_marks})
    SQL

    DBConnection.execute(sql, *attribute_values)
    self.id = DBConnection.last_insert_row_id
  end

  def initialize(params = {})
    params.each do |attr_name, value|
      raise "unknown attribute '#{attr_name}'" if !self.class.columns.include?(attr_name.to_sym)
      self.send("#{attr_name}=", value)
    end
  end

  def save
    self.id.nil? ? self.insert : self.update
  end

  def update
    set_line = self.class.columns.map { |attr_name| "#{attr_name} = ?" }.join(",")
    sql = <<-SQL
      UPDATE
        #{self.class.table_name}
      SET
        #{set_line}
      WHERE
        id = ?
    SQL
    DBConnection.execute(sql, *attribute_values, self.id)
  end

  def attribute_values
    self.class.columns.map { |col| attributes[col] }
  end
end
