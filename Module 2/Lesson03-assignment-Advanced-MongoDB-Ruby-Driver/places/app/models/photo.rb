class Photo
  attr_accessor :id, :location
  attr_writer :contents

  def initialize params = {}
    @id = !params[:_id].nil? ? params[:_id].to_s : nil
    @location = (params[:metadata] && params[:metadata][:location]) ? Point.new(params[:metadata][:location]) : nil
    @place = (params[:metadata] && params[:metadata][:place]) ? params[:metadata][:place] : nil
  end

  def self.mongo_client
    Mongoid::Clients.default
  end

end
