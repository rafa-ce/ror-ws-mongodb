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
    places_return = []
    places.each { |p|
      places_return << Place.new(p)
    }

    places_return
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
end
