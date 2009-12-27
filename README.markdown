ActsAsMongoRateable (with weights!)
===================================

Inspired by the old Rails+AR standby "acts_as_rateable," this rating plugin works with MongoDB+MongoMapper
and has weighted ratings, as well as bayesian and straight averages, and some friendly class-level helpers.

Intends to be super-performant by taking advantage of the benefits of document-driven db denormalization.

Requirements
------------

- MongoDB
- MongoMapper gem
- Expects you to have a User model that includes MongoMapper::Document

Installation
------------

Install the plugin:
        
        ./script/plugin install git://github.com/mepatterson/acts_as_mongo_rateable.git

Add the following 2 lines to the Model class that you want to make rateable:

        include ActsAsMongoRateable
        RATING_RANGE = (1..5)

Obviously, change the rating range if you want rate on a 10-star system or a 14-star or whatever.

Usage
-----

        class User
          include MongoMapper::Document
        end

        class Widget
          include ActsAsMongoRateable
          RATING_RANGE = (1..5)
          include MongoMapper::Document
        end

        widget = Widget.first

To rate it:

        widget.rate(score, user, weight)

- score must be an Integer within your RATING_RANGE
- user is the User who is rating this widget
- weight is optional; defaults to 1)

Now try all these fun methods:

        widget.average_rating

        widget.bayesian_rating

        widget.rating_stats

And some useful class methods:

        Widget.highest_rated(how_many)

        Widget.most_rated(how_many)

        Widget.most_rated_by_authorities(how_many)

        Widget.highest_bayesian_rated(how_many)

('how_many' is a limit and is optional.  i.e. Do you want a highest_rated list of 5, 10, 15 widgets?  
Defaults to just 1 if you don't pass any argument.)


Thanks To...
------------
- John Nunemaker and the rest of the folks on the MongoMapper Google Group
- The MongoDB peoples and the MongoDB Google Group
- juixe for the original acts_as_rateable plugin for ActiveRecord
- sunlightlabs 'datacatalog-api', from which I borrowed the ratings_stats hash methodology

Copyright (c) 2009 [M. E. Patterson], released under the MIT license
