class CreateOpenmrs < ActiveRecord::Migration
  def change

    unless Rails.env.production?                                                    
      connection = ActiveRecord::Base.connection                                    
      # - IMPORTANT: SEED DATA ONLY                                                 
      # - DO NOT EXPORT TABLE STRUCTURES                                            
      # - DO NOT EXPORT DATA FROM `schema_migrations`                               
      sql = File.read('db/database_setup.sql')                                      
      statements = sql.split(/;$/)                                                  
      statements.pop  # the last empty statement                                    
                                                                                    
      ActiveRecord::Base.transaction do                                             
        statements.each do |statement|                                              
          connection.execute(statement)                                             
        end                                                                         
      end                                                                           
    end

  end

  def self.down
    unless Rails.env.production?                                                    
      connection = ActiveRecord::Base.connection                                    
      connection.execute("SET foreign_key_checks = 0")
      connection.tables.each do |table|                                             
        connection.execute("DROP #{table}") unless table == "schema_migrations" 
      end                                                                           
      connection.execute("SET foreign_key_checks = 1")
    end
  end

end
