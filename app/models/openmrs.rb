class Openmrs < ActiveRecord::Base
  # attr_accessible :title, :body
  set_table_name :person 

  def randomDate(params={})
    years_back = params[:year_range] || 5
    latest_year  = params [:year_latest] || 0
    year = (rand * (years_back)).ceil + (Time.now.year - latest_year - years_back)
    month = (rand * 12).ceil
    day = (rand * 31).ceil
    series = [date = Time.local(year, month, day)]
    if params[:series]
      params[:series].each do |some_time_after|
        series << series.last + (rand * some_time_after).ceil
      end
      return series
    end
    date
  end

  def self.faker
    people = self.get_people
    connection = ActiveRecord::Base.connection                                
    connection.execute("SET foreign_key_checks = 0;")

    (people || []).each_with_index do |person_hash , i|
      person_id = person_hash['person_id']
      self.fake(person_id)
      puts "................ #{people.length - i} to go"
    end
  end

  private

  def self.next_person_id
    connection = ActiveRecord::Base.connection                                
    max_id = connection.select_all("SELECT MAX(person_id) person_id FROM #{target_db_name}.person;")
    if (max_id[0]['person_id']).blank?
      return 1
    else
      return max_id[0]['person_id'] + 1
    end
  end

  def self.fake(person_id)
    self.transaction do
      new_person_id = self.next_person_id
      connection = ActiveRecord::Base.connection                                

      connection.execute("UPDATE #{target_db_name}.person 
      SET person_id = #{new_person_id} WHERE person_id = #{person_id};")

      connection.execute("UPDATE #{target_db_name}.person_name 
      SET person_id = #{new_person_id} WHERE person_id = #{person_id};")

      connection.execute("UPDATE #{target_db_name}.person_attribute 
      SET person_id = #{new_person_id} WHERE person_id = #{person_id};")

      connection.execute("UPDATE #{target_db_name}.person_address 
      SET person_id = #{new_person_id} WHERE person_id = #{person_id};")



      connection.execute("UPDATE #{target_db_name}.patient 
      SET patient_id = #{new_person_id} WHERE patient_id = #{person_id};")

      connection.execute("UPDATE #{target_db_name}.patient_identifier 
      SET patient_id = #{new_person_id} WHERE patient_id = #{person_id};")

      connection.execute("UPDATE #{target_db_name}.patient_program 
      SET patient_id = #{new_person_id} WHERE patient_id = #{person_id};")

      connection.execute("UPDATE #{target_db_name}.encounter 
      SET patient_id = #{new_person_id} WHERE patient_id = #{person_id};")

      connection.execute("UPDATE #{target_db_name}.obs 
      SET person_id = #{new_person_id} WHERE person_id = #{person_id};")


      self.fake_address(new_person_id)
      self.fake_name(new_person_id)
      self.fake_person_attribute(new_person_id)
      self.fake_patient_identifier(new_person_id)
    end
  end

  def self.fake_address(new_person_id)
    (PersonAddress.where(:person_id => new_person_id) || []).each do |address|
      PersonAddress.transaction do
        unless address.address1.blank?
          address.address1 = Faker::Address.street_address
        end

        unless address.address2.blank?
          address.address2 = Faker::Company.name
        end

        unless address.city_village.blank?
          address.city_village = Faker::Address.city
        end

        unless address.state_province.blank?
          address.state_province = Faker::Address.state
        end
        address.save
      end
    end
  end

  def self.fake_name(new_person_id)
    (PersonName.where(:person_id => new_person_id) || []).each do |name|
      PersonName.transaction do
        unless name.given_name.blank?
          name.given_name = Faker::Name.first_name
        end

        unless name.family_name.blank?
          name.family_name = Faker::Name.last_name
        end

        unless name.middle_name.blank?
          name.middle_name = Faker::Name.first_name
        end
        name.save
      end
    end
  end
  
  def self.fake_person_attribute(new_person_id)
  end
  
  def self.fake_patient_identifier(new_person_id)
  end

  def self.target_db_name
    YAML.load(File.open(File.join(Rails.root, 
      "config/database.yml"), "r"))[Rails.env]['database']
  end

  def self.get_people
    connection = ActiveRecord::Base.connection                                
    connection.select_all("SELECT * FROM #{target_db_name}.person;")
  end

  def self.get_users
    connection = ActiveRecord::Base.connection                                
    connection.select_all("SELECT * FROM #{target_db_name}.users;")
  end

end
