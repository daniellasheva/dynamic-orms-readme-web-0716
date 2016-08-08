require_relative "../config/environment.rb"
require 'active_support/inflector'

class Song

  def self.table_name  #we get the table name by downcasing and pluralizing the class name (self)
    self.to_s.downcase.pluralize
  end

  def self.column_names
    DB[:conn].results_as_hash = true

    sql = "PRAGMA table_info('#{table_name}')"
    #returns an array of hashes describing the table (because we set results_as_hash)

    table_info = DB[:conn].execute(sql)
    column_names = []
    table_info.each do |row|
      column_names << row["name"]
    end
    column_names.compact #removes nil values
  end

  #Song.column_names returns ["id", "name", "album"]

  self.column_names.each do |col_name|
    attr_accessor col_name.to_sym
    #for each column name, add an attr_accessor
    #we want them to be symbols
  end

  def initialize(options={})
    options.each do |property, value|
      self.send("#{property}=", value)
      #options takes in the arguments we set, that we expect to be a hash
      #each 'property' becomes a method (like the attr_accessor getter method) that we set = to the value
      #it's like saying def property @property=value end
    end
  end

  def save
    sql = "INSERT INTO #{table_name_for_insert} (#{col_names_for_insert}) VALUES (#{values_for_insert})"
    DB[:conn].execute(sql)
    @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert}")[0][0]
  end

  def table_name_for_insert
    self.class.table_name
    #in order to access a class method from an instance method, do 
    #self.class...
  end

  def values_for_insert
    values = []
    self.class.column_names.each do |col_name|
      values << "'#{send(col_name)}'" unless send(col_name).nil?
      #look at how we did "properties" above
      #if we call a method on the col_name, we are asking it to return its value
      # def breed(breed)
      #   breed=breed  => what we want to capture
      # end
    end
    values.join(", ")
  end

  def col_names_for_insert
    self.class.column_names.delete_if {|col| col == "id"}.join(", ")
    #note that we don't even need the NAME column
    #that entire column is generated for us
  end

  def self.find_by_name(name)
    sql = "SELECT * FROM #{self.table_name} WHERE name = '#{name}'"
    DB[:conn].execute(sql)
  end

end



