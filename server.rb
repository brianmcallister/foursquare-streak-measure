require 'sinatra'
require 'json'
require 'patron'

configure do
  set :port, '3000'
  set :domain, "http://localhost:#{settings.port}"
  
  set :redirect, settings.domain
  set :id, 'RNUOV5S2LW13D22K4WBXXVNXDF3TQ4NQZA5IOODCFI4XWYYZ'
  set :secret, 'SJTC0H15ZYCSDZU2HSWB1F3PBTEGC0YTGSK5ABBKITYXRY1B'
  
  set :fsq_base_url, 'https://foursquare.com'
  set :fsq_auth_url, 'oauth2/authenticate'
  set :fsq_auth_params, "client_id=#{settings.id}" +
    "&response_type=code&redirect_uri=#{settings.redirect}"
end

# http = Patron::Session.new
# http.base_url = 

code = ''

get '/' do
  if params.has_key? 'code'
    code = params['code']
  end
  
  erb :index
end

get '/user' do
  content_type :json
  {'test' => 'hats', 'code' => code}.to_json
end

get '/auth' do
  redirect to "#{settings.fsq_base_url}/#{settings.fsq_auth_url}" +
    "?#{settings.fsq_auth_params}"
end