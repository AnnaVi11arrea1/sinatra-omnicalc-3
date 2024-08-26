require "sinatra"
require "sinatra/reloader"
require "http"

get("/") do

  erb(:home, {:layout => :layout})
end

get("/umbrella") do
  erb(:umbrella_form)
end

get("/process_umbrella") do
  @user_location = params.fetch("user_loc")

  url_encoded_string = @user_location.gsub(" ","+")

  key = ENV.fetch("GOOGLE_MAPS_KEY")

  gmaps_url = "https://maps.googleapis.com/maps/api/geocode/json?address=#{url_encoded_string}&key=#{key}"

  @raw_response = HTTP.get(gmaps_url).to_s

  @parsed_response = JSON.parse(@raw_response)

  @loc_hash = @parsed_response.dig("results", 0, "geometry", "location")

  @latitude = @loc_hash.fetch("lat")
  @longitude = @loc_hash.fetch("lng")
  latitude = @loc_hash.fetch("lat")
  longitude = @loc_hash.fetch("lng")

  # Here we are grabbing the key that we made in github settings:
  pirate_weather_key = ENV.fetch("PIRATE_WEATHER_KEY")

  # then we need the URL

  pirate_weather_url = "https://api.pirateweather.net/forecast/#{pirate_weather_key}/#{latitude},#{longitude}"
  raw_weather_data = HTTP.get(pirate_weather_url)
  parsed_weather_data = JSON.parse(raw_weather_data)

  hourly_hash = parsed_weather_data.fetch("hourly")
  hourly_data_array = hourly_hash.fetch("data")

  twelve_hour_prediction = hourly_data_array[1..12]
    precip_prob_threshold = 0.10
    any_precipitation = false

  twelve_hour_prediction.each do |hour_hash|
    precip_prob = hour_hash.fetch("precipProbability")
  
    if precip_prob > precip_prob_threshold
      any_precipitation = true
  
      precip_time = Time.at(hour_hash.fetch("time"))
  
      seconds_from_now seconds_from_now / 60 / 60
      
    end

    if any_precipitation == true
      @umbrella =  "You might want to take an umbrella!"
    else
      @umbrella = "You probably wont need an umbrella."
    end
  
  currently = parsed_weather_data.fetch("currently")  
  @summary = currently.fetch("summary")
  end

  erb(:umbrella_results)


end
