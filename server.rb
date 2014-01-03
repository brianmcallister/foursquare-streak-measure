require 'sinatra'
require 'json'
require 'patron'
require 'pp'
require_relative 'streak'
require_relative 'user'

enable :sessions

configure do
  set :session_secret, 'asdf'
  
  set :port, '3000'
  set :domain, "http://localhost:#{settings.port}"
  
  set :redirect, "#{settings.domain}/auth"
  set :id, 'RNUOV5S2LW13D22K4WBXXVNXDF3TQ4NQZA5IOODCFI4XWYYZ'
  set :secret, 'SJTC0H15ZYCSDZU2HSWB1F3PBTEGC0YTGSK5ABBKITYXRY1B'
  
  set :fsq_base_url, 'https://foursquare.com'
    
  set :fsq_endpoint_checkins, 'users/self/checkins'
end

user = User.new

http = Patron::Session.new
http.timeout = 10
http.base_url = "http://api.foursquare.com/v2"
http.enable_debug 'patron.debug'

get '/' do
  'session: ' + session.inspect
end

get '/checkins' do
  return 'not authenticated' unless session[:token]
  resp = http.get "/#{settings.fsq_endpoint_checkins}" +
    "?oauth_token=#{session[:token]}&limit=250"
  resp = JSON.parse resp.body
  
  checkins = resp['response']['checkins']['items']
  category = params['category']
  
  streak = Streak.new checkins, category

  content_type :json
  streak.results.to_json
end

get '/auth' do
  code = params['code']
  
  if code.nil?
    redirect to "#{settings.fsq_base_url}/oauth2/authenticate" +
      "?client_id=#{settings.id}&response_type=code" +
      "&redirect_uri=#{settings.redirect}"
  end
  
  # Get the access token.
  session = Patron::Session.new
  session.timeout = 10
  
  url = "#{settings.fsq_base_url}/oauth2/access_token"
  query_params = "client_id=#{settings.id}&client_secret=#{settings.secret}" +
    "&grant_type=authorization_code&redirect_uri=#{settings.redirect}" +
    "&code=#{@code}"
  
  resp = session.get "#{url}?#{query_params}"
  resp = JSON.parse resp.body
  session[:token] = resp['access_token']
  redirect to '/'
end

get '/logout' do
  session[:token] = nil
  redirect to '/'
end