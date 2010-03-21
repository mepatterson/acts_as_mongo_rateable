module ActsAsMongoRateable
  
  module ClassMethods
    def highest_rated(limit=1)
      all({:order => "rating_stats.average DESC", :limit => limit})
    end

    def most_rated(limit=1)
      all({:order => "rating_stats.count DESC", :limit => limit})
    end

    def most_rated_by_authorities(limit=1)
      all({:order => "rating_stats.sum_of_weights DESC", :limit => limit})
    end
    
    # TO DO this is awful, awful, awful!  make it faster using map/reduce
    def highest_bayesian_rated(limit=1)
      stats = all({:select => 'id, rating_stats'})
      all.sort_by do |doc| 
        rating = doc.bayesian_rating(stats)
        doc.rating_stats['bayesian_rating'] = rating
        rating
      end.reverse[0,limit]
    end
    
  end
  
  module InstanceMethods
        
    def delete_all_ratings
      ratings.delete_all
    end
    
    def average_rating
      rating_stats['average']
    end
    
    def bayesian_rating(stats=nil)
      return 0 if rating_stats['count'] == 0
      stats ||= self.class.all({:select => 'id, rating_stats'})
      system_counts = stats.map{ |p| [ p.id.to_s, p.rating_stats['count'] ] }
      avg_rating = stats.map{|p| p.rating_stats['average'] || 0 }.sum / stats.size.to_f
      avg_num_votes = system_counts.inject(0){|sum, r| sum += r.to_a.flatten[1] } / system_counts.size.to_f
      my_rating = rating_stats['average'] || 0
      my_count = rating_stats['count']
      ( (avg_num_votes * avg_rating) + (my_count * my_rating) ) / (avg_num_votes + my_count)
    end
        
    def delete_ratings_by_user(user)
      return false unless user
      return 0 if ratings.blank?
      ratings.delete_all(:user_id => user.id.to_s)
      self.reload
    end
    
    def rate(value, user = nil, weight = 1)
      delete_ratings_by_user(user)
      validate_rating!(value)
      r = Rating.new({
        :value => value, 
        :user_id => user.id, 
        :rateable_id => self.id,
        :rateable_class => self.class.to_s,
        :weight => weight
        })
      self.ratings << r
      self.reload
      r
    end
    
    # returns the Rating object found if user has rated this project, else returns nil
    def rated_by_user?(user)
      return false unless user
      ratings.detect{ |r| r.user_id == user.id}
    end
    
    protected
    
    def validate_rating!(value)
      if (range = self.class::RATING_RANGE) and !range.include?(value.to_i)
        raise ArgumentError, "Rating not in range #{range}. Rating provided was #{value}."
      end
    end
    
  end
  
  def self.included(receiver)
    receiver.class_eval do
      many :ratings, :foreign_key => 'rateable_id', :dependent => :destroy
      key :rating_stats, Hash, :default => {
        :total   => 0,
        :count   => 0,
        :sum_of_weights => 0,
        :average => nil
      }
    end
    receiver.extend         ClassMethods
    receiver.send :include, InstanceMethods
  end
  

end

%w{ models observers }.each do |dir|
  path = File.join(File.dirname(__FILE__), 'app', dir)
  $LOAD_PATH << path
  ActiveSupport::Dependencies.load_paths << path
  ActiveSupport::Dependencies.load_once_paths.delete(path)
end
