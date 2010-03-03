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
  environment = :production
  
  DB = Sequel.sqlite("iouUC.sqlite")
  
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
  end
end

# Homepage displays a list of all people and their current debt
get '/' do
  index
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
  process_person
  
  index
end

# Add a transaction
post '/transactions' do
  process_transactions
  
  index
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

def index
  @title = "Main Screen Turn On"
  @people = DB[:people].order(:name.asc)
  @transactions = DB[:transactions].order(:date_created.desc).limit(5)
  
  haml :index
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

# Validate/process person data
def process_person
  if DB[:people].filter(:name => params[:person][:name]).count > 0
    if @errors.nil?
      @errors = []
    end
    @errors << "Someone with that name already exists."
  elsif params[:person][:name].length < 1
    if @errors.nil?
      @errors = []
    end
    @errors << "You need to name the person you want to create."
  end
  
  if @errors.nil?
    # Create a new person
    DB[:people].insert(params[:person].merge(:date_created => Time.now))
    
    redirect '/'
  end
end

# Validate/process transaction data
def process_transactions
  amount = params[:transaction][:amount].to_s.split('.', 2)
  unless amount[1].nil? or amount[1].length <= 2
    params[:transaction][:amount] = (amount[0] + '.' + amount[1][0..1]).to_f
  end
  
  if params[:transaction][:amount].to_f < 0.01
    if @errors.nil?
      @errors = []
    end
    @errors << "You have to owe at least a penny."
  elsif params[:transaction][:person_for] == params[:transaction][:person_owed]
    if @errors.nil?
      @errors = []
    end
    @errors << "You can't owe yourself money!"
  end
  
  if params[:operator] == "-"
    params[:transaction][:amount] = -params[:transaction][:amount].to_f
  end
  
  if @errors.nil?
    DB[:transactions].insert(params[:transaction].merge(:date_created => Time.now))
    redirect '/'
  end
end
