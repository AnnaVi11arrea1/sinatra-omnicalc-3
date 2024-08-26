require "sinatra"
require "sinatra/reloader"
require "http"
require "sinatra/cookies"
require "openai"

get("/") do
  erb(:home, {:layout => :layout})
end

get("/umbrella") do
  erb(:umbrella_form)
end

post("/process_umbrella") do
  # values retreived from the form "name"
  @user_location = params.fetch("user_loc")
  url_encoded_string = @user_location.gsub(" ","+")

  key = ENV.fetch("GOOGLE_MAPS_KEY")
  gmaps_url = "https://maps.googleapis.com/maps/api/geocode/json?address=#{url_encoded_string}&key=#{key}"
  # convert to string to be parsed
  @raw_response = HTTP.get(gmaps_url).to_s

  @parsed_response = JSON.parse(@raw_response)

  @loc_hash = @parsed_response.dig("results", 0, "geometry", "location")

  @latitude = @loc_hash.fetch("lat")
  @longitude = @loc_hash.fetch("lng")
  latitude = @loc_hash.fetch("lat")
  longitude = @loc_hash.fetch("lng")

  # Pirate Weather:
  pirate_weather_key = ENV.fetch("PIRATE_WEATHER_KEY")
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
    end

    if any_precipitation == true
      @umbrella =  "You might want to take an umbrella!"
    else
      @umbrella = "You probably wont need an umbrella."
    end
  
  currently = parsed_weather_data.fetch("currently")  
  @summary = currently.fetch("summary")
  end

  cookies["last_location"] = @user_location
  cookies["last_lat"] = @latitude
  cookies["last_lng"] = @longitude
  erb(:umbrella_results)
end

get("/message") do
  erb(:ai_message, {:layout => :layout })
end

post("/send_message") do
  client = OpenAI::Client.new(access_token: ENV.fetch("OPENAI_API_KEY"))
  message_list = [
      {
        "role" => "system",
        "content" => "You are a helpful assistant who helps answer weather related questions."
      },
      {
        "role" => "user",
        "content" => "I have questions about the weather."
      }
    ]

  # Call the API to get the next message from GPT
  api_response = client.chat(
    parameters: {
      model: "gpt-3.5-turbo",
      messages: message_list
    }
  )


  @user_message = params.fetch("message")
  @response = message_list(0, "content")
  erb(:ai_reply)
end


get("/chat") do
  erb(:chat, {:layout => :layout })
end
