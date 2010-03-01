# iouUC
# A simple Sinatra app for keeping track of office coffee
# 
# by: Matthew Riley MacPherson (lonelyvegan.com)

require "rubygems"
require "sinatra"
require "json"
require "sequel"

configure do
  DB = Sequel.sqlite
  
  DB.create_table :people do
    primary_key :id
    String :name
    String :username
    String :password
    Date :date_created
  end
  
  DB.create_table :transactions do
    primary_key :id
    Integer :amount
    Integer :person_id # Linking relationship to a person
    Date :date_created
  end
end

# Homepage displays a list of all people and their current debt
get '/' do
  @title = "Home"
  haml :index
end

# List the transactions for a specific person in reverse chronological order
get %r{/people/[^/]*/?(\d+)?} do
  @person = DB[:people].first(:name => name)
  @person[:transactions] = DB[:transactions].filter(:person_id => person[:id]).order(:date_created.desc).limit(30, page * 10)
  haml :person
end
