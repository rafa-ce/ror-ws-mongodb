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
end