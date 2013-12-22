require 'sinatra'
require 'json'
require 'patron'
require 'pp'

enable :sessions

configure do
  set :session_secret, 'asdf'
  
  set :port, '3000'
  set :domain, "http://localhost:#{settings.port}"
  
  set :redirect, settings.domain
  set :id, 'RNUOV5S2LW13D22K4WBXXVNXDF3TQ4NQZA5IOODCFI4XWYYZ'
  set :secret, 'SJTC0H15ZYCSDZU2HSWB1F3PBTEGC0YTGSK5ABBKITYXRY1B'
  
  set :fsq_base_url, 'https://foursquare.com'
    
  set :fsq_endpoint_checkins, 'users/self/checkins'
end

http = Patron::Session.new
http.timeout = 20
http.base_url = "http://api.foursquare.com/v2"
http.enable_debug 'patron.debug'

token = ''

get '/' do
  token ||= session['token']
  
  if not token.empty?
    return 'authed'
  end
  
  if params.has_key? 'code'
    session['token'] = get_access_token params['code']
  end
  
  return 'session: ' + session.inspect
  
  erb :index
end

get '/checkins' do
  return 'not authenticated' unless session['token']
  resp = http.get "/#{settings.fsq_endpoint_checkins}" +
    "?oauth_token=#{session['token']}&limit=250"
  resp = JSON.parse resp.body
  
  analyze_checkins resp['response']['checkins']['items']
  
  content_type :json
  resp.to_json
end

get '/auth' do
  redirect to "#{settings.fsq_base_url}/oauth2/authenticate" +
    "?client_id=#{settings.id}&response_type=code" +
    "&redirect_uri=#{settings.redirect}"
end

def get_access_token(code)
  session = Patron::Session.new
  session.base_url = "#{settings.fsq_base_url}/oauth2/access_token"
  
  query_params = "client_id=#{settings.id}&client_secret=#{settings.secret}" +
    "&grant_type=authorization_code&redirect_uri=#{settings.redirect}" +
    "&code=#{code}"
    
  resp = session.get "?#{query_params}"
  resp = JSON.parse resp.body
  return resp['access_token']
end

def analyze_checkins(checkins)
  pp "Got #{checkins.length} checkins."
  
  list_by_week = {}
  previous = nil
  
  checkins.each do |checkin|
    week_number = Time.at(checkin['createdAt']).strftime '%U'
    categories = checkin['venue']['categories']
    previous = checkin
    
    next if not categories.length
    
    venue_categories = []
    
    categories.each do |cat|
      venue_categories << cat['shortName']
    end
    
    if not list_by_week.has_key? week_number
      list_by_week[week_number] = []
    end
    
    list_by_week[week_number] << checkin['venue']['name']
    
    list_by_week.each_pair do |week, venues|
      puts "week #{week}: #{venues.inspect}"
    end
    
    # pp "#{checkin['venue']['name']} - week: #{week_number} - cats: #{venue_categories.join ', '}"
  end
end