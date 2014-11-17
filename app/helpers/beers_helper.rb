require 'rest-client'
require 'json'
require 'cgi'

module BeersHelper
  def lookup( q )
    options = Array.new
    client = ENV['UNTAPPD_CLIENT_ID']
    secret = ENV['UNTAPPD_CLIENT_SECRET']
    url = "http://api.untappd.com/v4/search/beer?client_id=#{client}&client_secret=#{secret}&q=#{CGI.escape(q)}"
    json_txt = RestClient.get(url)
    json_obj = JSON.parse(json_txt)
    beers = json_obj["response"]["beers"]["items"]
    beers.each do |beer|
      brewery = beer['brewery']
      location = brewery['location']
      loc = brewery['country_name']
      loc += "--#{location['brewery_state']}" if loc == 'United States'
      loc += "--#{location['brewery_city']}"
      option = { id: beer["beer"]["bid"], name: beer["beer"]["beer_name"],
                 brewery: brewery['brewery_name'], location: loc,
                 style: beer["beer"]["beer_style"] }
      options << option
    end
    options
  end
end
