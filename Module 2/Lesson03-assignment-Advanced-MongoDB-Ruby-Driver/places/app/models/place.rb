class Place
  include Mongoid::Document

  attr_accessor :id, :formatted_address, :location, :address_components

  def initialize params
    @id = params[:_id].to_s
    @formatted_address = params[:formatted_address]
    @location = Point.new(params[:geometry][:geolocation])

    @address_components = []
    if !params[:address_components].nil?
      params[:address_components].each {
        |a| @address_components << AddressComponent.new(a)
      }
    end
  end

  def self.mongo_client
    Mongoid::Clients.default
  end

  def self.collection
    self.mongo_client['places']
  end

  def self.load_all file_path
    file=File.read(file_path)
    hash = JSON.parse(file)
    self.collection.insert_many(hash)
  end

  def self.find_by_short_name short_name
    self.collection.find('address_components.short_name': short_name)
  end

  def self.to_places places
    places.map { |doc|
      Place.new(doc)
    }
  end

  def self.find string_id
    id = BSON::ObjectId.from_string(string_id)
    self.to_places(collection.find(:_id => id)).first
  end

  def self.all offset = 0, limit = nil
    unless limit.nil?
      places = self.collection.find.skip(offset).limit(limit)
    else
      places = self.collection.find.skip(offset)
    end

    places.map { |doc|
      Place.new(doc)
    }
  end

  def destroy
    id = BSON::ObjectId.from_string(@id)
    self.collection.delete_one(:_id=>id)
  end

  def self.get_address_components sort=nil, offset=0, limit=nil
    if sort.nil?
      sort = {:_id=>1 }
    end

    unless limit.nil?
      self.collection.aggregate([
        {:$project=>{:formatted_address=>1 , :address_components=>1, "geometry.geolocation":1}},
        {:$unwind=>"$address_components"},
        {:$sort=>sort},
        {:$skip =>offset},
        {:$limit => limit }
      ])
    else
      self.collection.aggregate([
        {:$project=>{:formatted_address=>1 , :address_components=>1, "geometry.geolocation":1}},
        {:$unwind=>"$address_components"},
        {:$sort=>sort},
        {:$skip =>offset}
      ])
    end
  end

  def self.get_country_names
    places = self.collection.aggregate([
      {:$unwind => '$address_components'},
			{:$project => {:_id=>0, "address_components.long_name"=>1, "address_components.types"=>1}},
      {:$match => {"address_components.types"=>'country'}},
      {:$group => {:_id=>"$address_components.long_name"}}
    ])

    places.to_a.map {|place| place[:_id]}
  end
end
