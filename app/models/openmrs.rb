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

	def self.max_person_id
    connection = ActiveRecord::Base.connection
    connection.select_all("SELECT MAX(person_id) person_id FROM #{target_db_name}.person;")[0]['person_id']
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
      new_person_id = self.encode(person_id)
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

	#Euclid's algorithm: calculate greatest common divisor (gcd) of numbers a and b
	#return greatest common divisor of a and b
	def self.greastest_common_divisor(a,b)
		  r = 1

		  while r>0 do
		      r = a % b;
		      a = b;
		      b = r;
		  end
		  return a
	end

	#Extended Euclid's algorithm : solves the equation xm + yn = c
	#where m and n are given numbers. C is equal to gcd of m and n
	def self.extended_greastest_common_divisor(m,n)
		v = []
		if m == 0
			v = [n,0,1]
		else

			r = n%m
			v = self.extended_greastest_common_divisor(r, m)
			s = v[2]-n/m*v[1]
			v[2]=v[1];
			v[1]=s;
		end
		return v
	end

	#calculate m = x^y%n more efficiently
	def self.fast_exponentiation(x,y,n)
		r = 1
		m = 1

		while y !=0 do
			r = y%2
			y = y/2

			if r==1 then
				m = (m*x)%n
			end
			x=(x**2)%n
		end
		return m
	end

	#generate public key given t = (prime_a-1)*(prime_b-1) and n=prime_a*prime_b
	def self.generate_public_key(t,n)

		while true do
			r =  (rand()*1000000).to_i
			e = r%(n-2) + 2

			if self.greastest_common_divisor(e,t) == 1 && e > 100000
				return e
			end
		end
	end

	#returns a 3 element hash of public,private key and mod: [public,private,mod]
	def self.generate_keys(prime_a, prime_b)
		p = prime_a
		q = prime_b

		n = p*q

		t = (p-1)*(q-1)
		e = generate_public_key(t,n)
		puk = e
		c,d,k = self.extended_greastest_common_divisor(e,t)

		while d<0 do
			d = d+t
		end
		prk = d

		return {"public"=>puk, "private"=>prk, "mod"=>n}
	end

	def self.public_key
			YAML.load(File.open(File.join(Rails.root,
      "config/kubisa.yml"), "r"))[Rails.env]['public_key']
	end

	def self.private_key
			YAML.load(File.open(File.join(Rails.root,
      "config/kubisa.yml"), "r"))[Rails.env]['private_key']
	end

	def self.modulo
			YAML.load(File.open(File.join(Rails.root,
      "config/kubisa.yml"), "r"))[Rails.env]['modulo']
	end

	def self.encode(data)
		self.fast_exponentiation(data,self.public_key,self.modulo)+Openmrs.max_person_id
	end

	def self.decode(data)
		self.fast_exponentiation(data-Openmrs.max_person_id,self.private_key,self.modulo)
	end

end
