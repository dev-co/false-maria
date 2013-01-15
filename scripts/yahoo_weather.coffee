# Description:
#   Yahoo's Weather.
#
# Dependencies:
#   "jsdom": ""
#   "jquery": ""
#
# Configuration:
#   HUBOT_WEATHER_CELSIUS - Display in celsius.
#
# Commands:
#   hubot weather for <location> - Get location's weather.
#
# Author:
#   nebiros

# TODO: remove jsdom and jquery dependencies.
jsdom = require("jsdom").jsdom
window = jsdom().createWindow()
$ = require("jquery").create(window)

placeFinder = (msg, location) ->
  q = "SELECT * FROM geo.placefinder WHERE text='" + location + "'"
  q += " LIMIT 1"

  url = "http://query.yahooapis.com/v1/public/yql?q=" + encodeURIComponent(q) + "&format=json&env=" + encodeURIComponent("store://datatables.org/alltableswithkeys") + "&callback=?"

  $.getJSON url, (data, textStatus, jqXHR) ->
      if not data.query?
        msg.send "Something goes wrong."
        return

      if data.query.count <= 0
        msg.send "Location '#{location}' not found."
        return

      if not data.query.results?
        msg.send "Location '#{location}' not found."
        return

      if not data.query.results.Result?
        msg.send "Location '#{location}' not found."
        return

      weather(msg, data.query.results.Result)

weather = (msg, place) ->
  woeid = parseInt(place.woeid, 10)

  q = "SELECT * FROM weather.forecast WHERE woeid=" + woeid + ""
  q += " AND u='c'" if process.env.HUBOT_WEATHER_CELSIUS
  q += " LIMIT 1"

  url = "http://query.yahooapis.com/v1/public/yql?q=" + encodeURIComponent(q) + "&format=json&env=" + encodeURIComponent("store://datatables.org/alltableswithkeys") + "&callback=?"
  
  $.getJSON url, (data, textStatus, jqXHR) ->
    if not data.query?
      msg.send "Something goes wrong."
      return
    
    if data.query.count <= 0
      msg.send "Weather for '#{place.city}, #{place.countrycode}' was not found."
      return

    if not data.query.results.channel.item.condition?
      msg.send "Weather for '#{place.city}, #{place.countrycode}' was not found."
      return

    temp = data.query.results.channel.item.condition.temp
    if not temp?
      msg.send "Weather for '#{place.city}, #{place.countrycode}' was not found."
      return

    text = data.query.results.channel.item.condition.text
    unit = "fahrenheit"
    unit = "celsius" if process.env.HUBOT_WEATHER_CELSIUS

    out = "#{place.city}, #{place.countrycode}, #{temp} #{unit} degrees, " + text.toLowerCase()
    msg.send out

module.exports = (robot) ->
  robot.respond /weather for (.+)$/i, (msg) ->
    placeFinder msg, msg.match[1]
