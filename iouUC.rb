# iouUC
# A simple Sinatra app for keeping track of office coffee
# 
# by: Matthew Riley MacPherson (lonelyvegan.com)

require "rubygems"
require "sinatra"
require "lib/render_partial"
require "haml"
require "sass"
require "json"
require "sequel"

# Set Sinatra's variables
set :app_file, __FILE__
set :root, File.dirname(__FILE__)
set :views, 'views'
set :public, 'public'

# Setup the app
configure do
  environment = :development
  
  DB = Sequel.sqlite#('iouUC.sqlite')
  
  # Database version 1
  unless DB.table_exists? :schema
    DB.create_table :schema do
      primary_key :version
      Time :date_created
    end
    
    DB.create_table :people do
      primary_key :id
      String :name
      Time :date_created
    end
  
    DB.create_table :products do
      primary_key :id
      String :name
      Float :cost
      Time :date_created
    end
  
    DB.create_table :transactions do
      primary_key :id
      Float :amount
      Float :person_for # Linking relationship to a person's id
      Float :person_owed # Linking relationship to a person's id
      Time :date_created
    end
  
    if environment == :development
      DB[:people].insert(:name => 'Matt', :date_created => Time.now)
      DB[:people].insert(:name => 'Dave', :date_created => Time.now)
    
      DB[:products].insert(:name => 'Cookie', :cost => 2, :date_created => Time.now)
    
      for i in 1..2
        DB[:transactions].insert(:amount => 2, :person_for => 2, :person_owed => 1, :date_created => Time.now)
      end
      DB[:transactions].insert(:amount => 2.50, :person_for => 2, :person_owed => 1, :date_created => Time.now)
    end
  end
end

# Homepage displays a list of all people and their current debt
get '/' do
  @title = "Home"
  @people = DB[:people].order(:name.asc)
  @transactions = DB[:transactions].order(:date_created.desc).limit(5)
  
  haml :index
end

# List the transactions for a specific person in reverse chronological order
get %r{/people/(\d*)/?(\d*)?} do |id, page|
  @person = DB[:people].first(:id => id)
  unless @person.nil?
    @person[:transactions] = DB[:transactions].filter(:person_id => id).order(:date_created.desc).limit(30, page * 10)
  end
  
  haml :person
end

# Create/edit a person
post '/people' do
  if params[:people] and params[:people][:id]
    # Edit a person with this id
    DB[:people].update(params[:person].merge(:date_created => Time.now)).filter(:id => params[:person][:id])
  else
    # Create a new person
    DB[:people].insert(params[:person].merge(:date_created => Time.now))
  end
  
  redirect '/'
end

# Add a transaction
post '/transactions' do
  DB[:transactions].insert(params[:transaction].merge(:date_created => Time.now))
  
  redirect '/'
end

# Create css files from the sass files in our stylesheets directory
get '/stylesheets/:file.css' do |file|
  content_type 'text/css', :charset => 'utf-8'
  sass :"stylesheets/#{file}"
end

# Format a Time object into a pretty date string
def date_format(time)
  time.strftime "%B %d (%A)"
end

# Get a total debt number for a person
def debt(person_for, person_owed)
  DB[:transactions].filter(:person_owed => person_owed[:id], :person_for => person_for[:id]).sum(:amount) || 0
end

# Format a number into a pretty dollar string
def money_format(amount)
  amount = amount.to_s
  split = amount.split('.', 2)
  
  if split[1].nil?
    "$#{split[0]}.00"
  elsif split[1].length == 1
    "$#{split[0]}.#{split[1]}0"
  else
    "$#{split[0]}.#{split[1]}"
  end
end
