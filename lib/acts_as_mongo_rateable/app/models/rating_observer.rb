class RatingObserver < MongoMapper::Observer
  observe :rating
    
  def after_create(rating)
    doc = rating.find_rated_document!
    stale = doc.rating_stats
    count = (doc.rating_stats[:count] += 1)
    total = (doc.rating_stats[:total] += ( rating.value * rating.weight ))
    sow = (doc.rating_stats[:sum_of_weights] += rating.weight)
    doc.rating_stats[:average] = total.to_f / sow
    doc.save!
  end
  
  def before_update(rating)
    rating_from_db = Rating.find_by_id(rating.id)
    rating.previous_value = (rating_from_db.value * rating.weight) if rating_from_db
  end
  
  def after_update(rating)
    doc = rating.find_rated_document!
    value_delta = (rating.value * rating.weight) - (rating.previous_value * rating.weight)
    total = (doc.rating_stats[:total] += value_delta)
    count = doc.rating_stats[:count]
    doc.rating_stats[:average] = total.to_f / count
    doc.save
  end
 
  def after_destroy(rating)
    doc = rating.find_rated_document
    return if doc.nil?
    count = (doc.rating_stats[:count] -= 1)
    doc.rating_stats[:total] -= (rating.value * rating.weight)
    doc.rating_stats[:sum_of_weights] -= rating.weight
    doc.rating_stats[:average] = nil if count == 0
    doc.save
  end
  
end

# fire it up!
RatingObserver.instance