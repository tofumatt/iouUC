# iouUC
# A simple Sinatra app for keeping track of office coffee
# 
# by: Matthew Riley MacPherson (lonelyvegan.com)

require "rubygems"
require "sinatra"
require "haml"
require "sass"
require "json"
require "sequel"

configure do
  DB = Sequel.sqlite
  
  DB.create_table :people do
    primary_key :id
    String :name
    Date :date_created
  end
  
  DB.create_table :transactions do
    primary_key :id
    Float :amount
    Float :person_id # Linking relationship to a person
    Date :date_created
  end
  
  DB[:people].insert(:name => 'Matt', :date_created => Time.now)
end

# Homepage displays a list of all people and their current debt
get '/' do
  @title = "Home"
  
  haml :index
end

# List the transactions for a specific person in reverse chronological order
get %r{/people/(\d*)/?(\d*)?} do |id, page|
  @person = DB[:people].first(:id => id)
  puts @person[:name]
  unless @person.nil?
    @person[:transactions] = DB[:transactions].filter(:person_id => id).order(:date_created.desc).limit(30, page * 10)
  end
  
  haml :person
end

# Create/edit a person
post '/person' do
  if params[:id]
    # Edit a person with this id
    DB[:people].insert(:name => params[:name], :date_created => Time.now)
  else
    # Create a new person
    DB[:people].insert(:name => params[:name], :date_created => Time.now)
  end
  
  redirect '/'
end

# Create css files from the sass files in our stylesheets directory
get '/stylesheets/:file.css' do |file|
  content_type 'text/css', :charset => 'utf-8'
  sass :"stylesheets/#{file}"
end
