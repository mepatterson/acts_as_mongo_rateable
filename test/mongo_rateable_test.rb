require File.dirname(__FILE__) + '/test_helper.rb'

class MongoRateableTest < ActiveSupport::TestCase

  def create_user(name)
    u = User.create({:name => name})
    puts u.errors unless u.valid?
    u
  end
  
  def load_multiple_raters
    @m_rater_1 = create_user "m_rater_1"
    @m_rater_2 = create_user "m_rater_2"
    @m_rater_3 = create_user "m_rater_3"
    [@m_rater_1, @m_rater_2, @m_rater_3]
  end
  
  def load_multiple_widgets
    @widget = @owner.widgets.create({:name => "Test Widget"})
    @widget_2 = @owner.widgets.create({:name => "Test Widget 2"})
    @widget_3 = @owner.widgets.create({:name => "Test Widget 3"})
    [@widget, @widget_2, @widget_3]
  end
  
  def load_multiple_dongles
    @dongle = @owner.dongles.create({:name => "Test dongle"})
    @dongle_2 = @owner.dongles.create({:name => "Test dongle 2"})
    @dongle_3 = @owner.dongles.create({:name => "Test dongle 3"})
    [@dongle, @dongle_2, @dongle_3]
  end
  
  def rate_this_many_times(obj, count, authority=1)
    x = 0
    count.times do
      x += 1
      rater = create_user "fake_rater_#{x}"
      obj.rate(4, rater, authority)
    end
  end
  
  def load_and_randomly_rate_multiple_widgets
    raters = load_multiple_raters
    widgets = load_multiple_widgets
    widgets.each do |w|
      raters.each {|r| w.rate(rand(5)+1, r, rand(3)+1) }
    end
  end
  
  def load_and_randomly_rate_multiple_dongles
    raters = load_multiple_raters
    dongles = load_multiple_dongles
    dongles.each do |d|
      raters.each {|r| d.rate(rand(5)+1, r, rand(3)+1) }
    end
  end
  
  def multi_rate(obj)
    load_multiple_raters
    obj.rate(4, @m_rater_1, 1)
    obj.rate(2, @m_rater_2, 3)
    obj.rate(5, @m_rater_3, 5)
  end  
  
  def multi_rate_many_widgets
    load_multiple_widgets
    raters = load_multiple_raters
    raters.each do |r|
      @widget.rate(5, r, 2)
      @widget_2.rate(1, r, 2)
      @widget_3.rate(3, r, 2)
    end
  end
    
  def setup
    @owner = create_user 'owner'
    @rater = create_user 'rater'
    @widget = @owner.widgets.create({:name => "Test Widget"})
  end

  test "single rating on a widget produces the correct rating stats" do
    @widget.rate(3, @rater, 2)
    expected_stats = {"total" => 6, "count" => 1, "average" => 3.to_f, "sum_of_weights" => 2}
    %w( total count average sum_of_weights).each do |method|
      assert_equal expected_stats[method], @widget.rating_stats[method]
    end
  end

  test "multiple ratings on a widget produce the correct rating stats" do
    multi_rate(@widget)
    expected_stats = {"total" => 35, "count" => 3, "average" => 3.88888888888889, "sum_of_weights" => 9}
    %w( total count sum_of_weights).each do |method|
      assert_equal expected_stats[method], @widget.rating_stats[method]
    end
    # doing average seperately, since we don't need to test the whole long float
    assert_equal sprintf('%.2f',expected_stats['average']), sprintf('%.2f',@widget.rating_stats['average'])
  end
  
  test "deleting all ratings for a specific widget works" do
    load_and_randomly_rate_multiple_widgets
    assert_equal 3, @widget.ratings.count
    assert_equal 9, Rating.count
    @widget.delete_all_ratings
    assert_equal 0, @widget.ratings.count
    assert_equal 6, Rating.count
  end
  
  test "deleting all ratings for a particular object doesn't delete ratings for other object" do
    load_and_randomly_rate_multiple_widgets
    load_and_randomly_rate_multiple_dongles
    assert_equal 18, Rating.count
    @widget.delete_all_ratings
    assert_equal 0, @widget.ratings.count
    assert_equal 3, @dongle.ratings.count
  end
  
  test "rated_by_user? works" do
    multi_rate(@widget)
    assert @widget.rated_by_user?(@m_rater_1)
  end
  
  test "delete by user only deletes ratings by that user for that object" do
    @dongle = @owner.dongles.create({:name => "Test dongle"})
    multi_rate(@widget)
    widget_rater = @m_rater_1
    multi_rate(@dongle)
    assert_equal 6, Rating.count
    assert_equal 3, @widget.ratings.count
    assert @widget.rated_by_user?(widget_rater)
    @widget.delete_ratings_by_user(widget_rater)
    assert ! @widget.rated_by_user?(widget_rater)
    assert_equal 2, @widget.ratings.count
    assert_equal 5, Rating.count
  end
  
  test "bayesian_rating returns correct number" do
    multi_rate_many_widgets
    assert_equal sprintf('%.2f',3.82), sprintf('%.2f',@widget.bayesian_rating)
    assert_equal sprintf('%.2f',1.54), sprintf('%.2f',@widget_2.bayesian_rating)
    assert_equal sprintf('%.2f',2.68), sprintf('%.2f',@widget_3.bayesian_rating)
  end
  
  test "bayesian_rating for one class of objects not corrupted by other ratings for other classes" do
    multi_rate_many_widgets
    load_and_randomly_rate_multiple_dongles
    assert_equal sprintf('%.2f',3.82), sprintf('%.2f',@widget.bayesian_rating)
    assert_equal sprintf('%.2f',1.54), sprintf('%.2f',@widget_2.bayesian_rating)
    assert_equal sprintf('%.2f',2.68), sprintf('%.2f',@widget_3.bayesian_rating)
  end
  
  test "highest_rated returns correct widgets in order" do
    multi_rate_many_widgets
    assert_equal [@widget, @widget_3, @widget_2], Widget.highest_rated(3) 
  end
  
  test "most_rated returns correct widgets in order" do
    load_multiple_widgets
    rate_this_many_times(@widget, 6)
    rate_this_many_times(@widget_2, 1)
    rate_this_many_times(@widget_3, 3)
    assert_equal [@widget, @widget_3, @widget_2], Widget.most_rated(3)
  end
  
  test "most_rated_by_authorities returns correct widgets in order" do
    load_multiple_widgets
    rate_this_many_times(@widget, 6, 2)
    rate_this_many_times(@widget_2, 1, 5)
    rate_this_many_times(@widget_3, 3, 1)
    assert_equal [@widget, @widget_2, @widget_3], Widget.most_rated_by_authorities(3)
  end
  
end
