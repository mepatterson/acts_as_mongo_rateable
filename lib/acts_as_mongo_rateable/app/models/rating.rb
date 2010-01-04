class Rating
  include MongoMapper::Document
  
  key :user_id,         ObjectId, :required => true
  key :rateable_id,     ObjectId, :required => true
  key :rateable_class,  String,   :required => true
  key :value,           Integer,  :required => true
  key :previous_value,  Integer,  :default => 0
  key :weight,          Integer,  :default => 1
  timestamps!

  ensure_index :user_id
  ensure_index :rateable_id
  ensure_index :rateable_class
  ensure_index :created_at
    
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

