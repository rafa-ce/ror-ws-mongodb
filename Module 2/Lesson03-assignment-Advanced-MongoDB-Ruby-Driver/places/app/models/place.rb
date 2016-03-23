class Place
  include Mongoid::Document

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
