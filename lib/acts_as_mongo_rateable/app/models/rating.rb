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
  
  after_create  :set_rating_stats
  after_update  :update_rating_stats
  before_update :set_previous_value
  after_destroy :reduce_rating_stats

  def set_rating_stats
    doc = find_rated_document!
    count = (doc.rating_stats[:count] += 1)
    total = (doc.rating_stats[:total] += ( value * weight ))
    sow = (doc.rating_stats[:sum_of_weights] += weight)
    doc.rating_stats[:average] = total.to_f / sow
    doc.save!
  end
  
  def set_previous_value
    rating_from_db = Rating.find_by_id(id)
    previous_value = (rating_from_db.value * weight) if rating_from_db
  end
  
  def update_rating_stats
    doc = find_rated_document!
    value_delta = (value * weight) - (previous_value * weight)
    total = (doc.rating_stats[:total] += value_delta)
    count = doc.rating_stats[:count]
    doc.rating_stats[:average] = total.to_f / count
    doc.save
  end
 
  def reduce_rating_stats
    doc = find_rated_document
    return if doc.nil?
    count = (doc.rating_stats[:count] -= 1)
    doc.rating_stats[:total] -= (value * weight)
    doc.rating_stats[:sum_of_weights] -= weight
    doc.rating_stats[:average] = nil if count == 0
    doc.save
  end

  
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


