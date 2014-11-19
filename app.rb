require 'pry'
require 'awesome_print'
require 'nokogiri'
require 'open-uri'
require 'sinatra'
require 'redis'
require 'json'

# set :bind, '0.0.0.0'

def process_live_scores(division)
  round_scores = []
  cached = false
  if (ENV["REDISTOGO_URL"]) then
    uri = URI.parse(ENV["REDISTOGO_URL"])
    redis = Redis.new(:host => uri.host, :port => uri.port, :password => uri.password)
  else
    redis = Redis.new
  end
  # redis = Redis.new
  begin
    doc = Nokogiri::HTML(open("http://54.204.38.205/"))
    rows = doc.xpath("//tr")
    rows.collect do |row|
      team = row.at("td[1]").to_s.delete("<td>").delete("</td>")
      score_raw = row.at("td[3]").to_s.delete("<td>").delete("</td>")
      if (!team && !score_raw) then
        next
      end

      if (division == :open) then
        continue = false
        File.open('round_2_scores.txt', 'r').each_line do |line|
          if line.chomp.length != 0 then
            puts "Comparing #{line.split(' ')[0].to_s} to #{team.to_s}."
            if (line.split(' ')[0].to_s == team.to_s) then
              continue = true
            end
          end
        end

        if (!continue) then
          puts "Not continuing with this score."
          next
        else
          puts "Continuing with this score"
        end
      elsif (division == :allservice) then
        continue = false
        File.open('round_2_scores.txt', 'r').each_line do |line|
          if line.chomp.length != 0 then
            puts "Comparing #{line.split(' ')[0].to_s} to #{team.to_s}."
            if (line.split(' ')[0].to_s == team.to_s) then
              continue = true
            end
          end
        end

        if (continue) then
          puts "Not continuing with this score."
          next
        else
          puts "Continuing with this score"
        end
      end

      if (redis.get(team)) then
        redis.set(team, score_raw.to_i)
      else
        redis.set(team, score_raw.to_i)
        redis.set("time-" + team, Time.now.to_i)
      end
      round_scores.push(team)
    end
  rescue
    cached = true
  end

  redis_scores = []

  round_scores.each do |team_number|
    team_score = {}
    team_score[:team] = team_number
    team_score[:score] = redis.get(team_number)
    team_score[:epoch] = redis.get("time-" + team_number)
    redis_scores.push(team_score)
  end 

  sorted = redis_scores.sort_by { |k| k[:score].to_i}
  sorted = sorted.reverse
  our_score = 0

  sorted.each do |temp_score|
    if ((temp_score[:epoch].to_i + 21600) < Time.now.to_i) then
      temp_score[:finished] = true
    else
      temp_score[:finished] = false
    end
    if (temp_score[:team] == "CPOC") then
      sorted.delete(temp_score)
    end
    if (temp_score[:team] == "06-0264") then
      our_score = temp_score[:score]
    end
  end

  pos = 0
  sorted.each do |item|
    if (item[:score].to_i >= our_score.to_i) then
      pos += 1
    end
  end

  results = {:round_scores => redis_scores, :sorted_scores => sorted, :our_score => our_score, :our_pos => pos}
  results
end

def process_scores
  round_scores = []
  File.open('round_1_scores.txt', 'r').each_line do |line|
    if line.chomp.length != 0 then
      team_score = {}
      team_score[:team] = line.split(' ')[0]
      team_score[:round_1_score] = line.split(' ')[1]
      round_scores.push(team_score)
    end
  end
  
  File.open('round_2_scores.txt', 'r').each_line do |line|
    if line.chomp.length != 0 then
      round_scores.each do |temp_score|
        if (temp_score[:team] == line.split(' ')[0]) then
          temp_score[:round_2_score] = line.split(' ')[1]
        end
      end
    end
  end

  round_scores.each do |score|
    if score[:round_1_score] && !score[:round_2_score] then
      score[:total] = score[:round_1_score].to_i
    end

    if score[:round_2_score] && !score[:round_1_score] then
      score[:total] = score[:round_2_score].to_i
    end

    if score[:round_2_score] && score[:round_1_score] then
      score[:total] = score[:round_2_score].to_i + score[:round_1_score].to_i
    end
  end

  sorted = round_scores.sort_by { |k| k[:total]}
  sorted = sorted.reverse

  our_score = 0

  sorted.each do |ite|
    if (ite[:team] == "06-0264") then
      our_score = ite[:total]
    end
  end

  pos = 0
  sorted.each do |item|
    if (item[:total] >= our_score) then
      pos += 1
    end
  end

  results = { :round_scores => round_scores, :sorted_scores => sorted, :our_score => our_score, :our_pos => pos}
  results
end

get '/semis/rhs' do
  scores = process_scores
  out = ""
  out += "Using score data from released score PDF files.<br />"
  out += "Team 06-0264 has #{scores[:our_pos]} teams above or at their score (#{scores[:our_score]}). Teams should have no greater than 50 teams at or above to go to semifinals.<br /><br />Teams without a score in Round 2 are not displayed. Maximum points = 500 (Round 1 (200) + Round 2 (300)).<br />"
  scores[:sorted_scores].each do |item2|
    if (item2[:round_2_score]) then
      out+= "<br>#{item2[:team]}: #{item2[:total]} total pts (R1: #{item2[:round_1_score].to_i.to_s}, R2: #{item2[:round_2_score].to_i.to_s})."
    end
  end
  out
end

get '/semis' do
  scores = process_scores
  out = ""
  out += "Using score data from released score PDF files.<br />"
  out += "Teams should have no greater than 50 teams at or above to go to semifinals.<br /><br />Teams without a score in Round 2 are not displayed. Maximum points = 500 (Round 1 (200) + Round 2 (300)).<br />"
  scores[:sorted_scores].each do |item2|
    if (item2[:round_2_score]) then
      out+= "<br>#{item2[:team]}: #{item2[:total]} total pts (R1: #{item2[:round_1_score].to_i.to_s}, R2: #{item2[:round_2_score].to_i.to_s})."
    end
  end
  out
end

get '/' do
  "Thanks for visiting. While we have the capability to keep projections online throughout the week, we have chosen to discontinue service indefinitely. Thanks for participating in CyberPatriot Six with us."
end

get '/rhs' do
  "Thanks for visiting. While we have the capability to keep projections online throughout the week, we have chosen to discontinue service indefinitely. Thanks for participating in CyberPatriot Six with us."
end

get '/allservice' do
  "Thanks for visiting. While we have the capability to keep projections online throughout the week, we have chosen to discontinue service indefinitely. Thanks for participating in CyberPatriot Six with us."
end

# get '/' do
#   scores = process_live_scores :open
#   out = ""
#   out += "Using score data from live competition system.<br /><br />"
#   out += "Teams must be in the top 12 to go to the national finals competition. Teams that have been listed for 6 hours (the space of a competition window) are indicated by a lock icon.<br />"
#   out += "This page is displaying data from the open division. See <a href='/allservice'>here</a> for the all service division.<br /> This page is unofficial and not supported by the CyberPatriot program office.<br />"
#   number = 0
#   scores[:sorted_scores].each do |item2|
#     if ((defined? item2[:team]) && (defined? item2[:score])) then
#       if (item2[:team] == "") then
#         next
#       end
#       if (number == 0) then
#         number = 1
#       else
#         number = number + 1
#       end

#       out+= "<br>#{number}. #{if item2[:finished] then "<img src='https://dl.dropboxusercontent.com/u/1253613/closed.png'>" else "<img src='https://dl.dropboxusercontent.com/u/1253613/opened.png'>" end} #{item2[:team]}: #{item2[:score]} points."
#     end
#   end
#   out
# end

# get '/allservice' do
#   scores = process_live_scores :allservice
#   out = ""
#   out += "Using score data from live competition system.<br /><br />"
#   out += "Teams must be in the top 12 to go to the national finals competition. Teams that have been listed for 6 hours (the space of a competition window) are indicated by a lock icon.<br />"
#   out += "This page is displaying data from the all service division. See <a href='/'>here</a> for the open division.<br /> This page is unofficial and not supported by the CyberPatriot program office.<br />"
#   number = 0
#   scores[:sorted_scores].each do |item2|
#     if ((defined? item2[:team]) && (defined? item2[:score])) then
#       if (item2[:team] == "") then
#         next
#       end
#       if (number == 0) then
#         number = 1
#       else
#         number = number + 1
#       end

#       out+= "<br>#{number}. #{if item2[:finished] then "<img src='https://dl.dropboxusercontent.com/u/1253613/closed.png'>" else "<img src='https://dl.dropboxusercontent.com/u/1253613/opened.png'>" end} #{item2[:team]}: #{item2[:score]} points."
#     end
#   end
#   out
# end

# get '/rhs' do
#   scores = process_live_scores :open
#   out = ""
#   out += "Using score data from live competition system.<br /><br />"
#   out += "Teams must be in the top 12 to go to the national finals competition. Teams that have been listed for 6 hours (the space of a competition window) are indicated by a lock icon.<br />"
#   out += "This page is displaying data from the open division. See <a href='/allservice'>here</a> for the all service division.<br />"
#   number = 0
#   scores[:sorted_scores].each do |item2|
#     if ((defined? item2[:team]) && (defined? item2[:score])) then
#       if (item2[:team] == "") then
#         next
#       end
      
#       if (number == 0) then
#         number = 1
#       else
#         number = number + 1
#       end

#       star = false
#       if (item2[:team] == "06-0264") then
#         star = true
#       end

#       out+= "<br>#{number}. #{if star then "<img src='https://dl.dropboxusercontent.com/u/1253613/namechan.png'>" end} #{if item2[:finished] then "<img src='https://dl.dropboxusercontent.com/u/1253613/closed.png'>" else "<img src='https://dl.dropboxusercontent.com/u/1253613/opened.png'>" end} #{item2[:team]}: #{item2[:score]} points."
#     end
#   end
#   out
# end
