json.array!(@beers) do |beer|
  json.extract! beer, :id, :brewery, :location, :name, :style, :year, :quantity, :notes, :untappd
  json.url beer_url(beer, format: :json)
end
