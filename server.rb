require 'sinatra'
require 'json'
require 'patron'
require 'pp'

configure do
  set :port, '3000'
  set :domain, "http://localhost:#{settings.port}"
  
  set :redirect, settings.domain
  set :id, 'RNUOV5S2LW13D22K4WBXXVNXDF3TQ4NQZA5IOODCFI4XWYYZ'
  set :secret, 'SJTC0H15ZYCSDZU2HSWB1F3PBTEGC0YTGSK5ABBKITYXRY1B'
  
  set :fsq_base_url, 'https://foursquare.com'
    
  set :fsq_endpoint_checkins, 'users/self/checkins'
end

http = Patron::Session.new
http.base_url = "http://api.foursquare.com/v2"
http.enable_debug 'patron.debug'

code = ''
token = ''

get '/' do
  if params.has_key? 'code'
    code = params['code']
    token = get_access_token code
  end
  
  if not token.empty?
    return 'token: ' + token
  end
  
  erb :index
end

get '/checkins' do
  return 'not authenticated' if token.empty?
  resp = http.get "/#{settings.fsq_endpoint_checkins}?oauth_token=#{token}"
  resp = JSON.parse resp.body
  
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
  json = JSON.parse resp.body
  json['access_token']
end