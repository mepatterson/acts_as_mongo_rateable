class Rating
  include MongoMapper::Document
  
  key :user_id,         ObjectId
  key :rateable_id,     ObjectId
  key :rateable_class,  String
  key :value,           Integer
  key :previous_value,  Integer,  :default => 0
  key :weight,          Integer,  :default => 1
  timestamps!
      
  belongs_to :user
  
  # == Various Instance Methods   
  def find_rated_document
    klass = rateable_class.constantize
    klass.find(rateable_id.to_s)
  end
  
  def find_rated_document!
    doc = find_rated_document
    raise "Associated document not found" if doc.nil?
    doc
  end  
  
end

# don't move this. just trust me, okay?
require 'rating_observer'

