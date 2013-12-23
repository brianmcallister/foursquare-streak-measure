require 'patron'
require 'json'
require 'pp'

class Streak
  # Public: Return the results hash.
  attr_reader :results
  
  # Public: Initialize a new streak with a list of checkins.
  #
  # checkins - Array of checkins.
  # category - Category to measure a streak for.
  def initialize checkins, category
    @checkins = checkins
    @category = category
    @by_week = {}
    @results = {}
    @results[category] = 0
    
    # Measure the streak.
    group_checkins_by_week()
    measure_streak()
  end
  
  private
  # Private: Group the checkins array by week number. Sets the `by_week` 
  # instance variable to a new hash, keys being the week number, values being
  # an array of categories.
  #
  # Returns nothing.
  def group_checkins_by_week
    previous = nil
    by_week = {}
    
    @checkins.each do |checkin|
      week_number = Time.at(checkin['createdAt']).strftime '%U'
      categories = checkin['venue']['categories']
      previous = checkin
      
      next if not categories.length
    
      venue_categories = []
      
      # Only gather up category names.
      categories.each do |cat|
        venue_categories << cat['shortName']
      end
    
      # Create a new array for week numbers that don't exist.
      if not by_week.has_key? week_number
        by_week[week_number] = []
      end
      
      by_week[week_number].push(venue_categories).flatten!
    end
    
    # Sort by week number.
    by_week.sort_by { |week| week }
    
    @by_week = by_week
  end
  
  # Private: Measure a streak by looping over the checkins sorted by week. Sets
  # the `streak` instance variable.
  def measure_streak
    streak = 0
    streak_ended = false
    
    @by_week.each_pair do |week, categories|
      result = false
    
      # Check if the passed in category is in the list of checkin categories.
      categories.each do |cat|
        if cat.downcase.include? @category.downcase
          result = true
        end
      end

      # If an existing streak is broken, stop here.
      # TODO: Try to continue and gather up historical streaks.
      if streak_ended and streak > 0
        break
      end
    
      # If this week doesn't have a result, contine to next week.
      if not result
        streak_ended = true
        next
      end
    
      # Increment the streak.
      streak_ended = false
      streak = streak + 1
    end
  
    @results[@category] = streak
  end
end