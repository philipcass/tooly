require 'mechanize'
require 'cinch'
require 'json'
$LOAD_PATH << '.'
require 'mpdcontroller.rb'

bot = Cinch::Bot.new do
  configure do |c|
    c.server = "irc.netsoc.tcd.ie"
    c.nick     = "tooly"
    c.channels = ["#tooly"]
    c.plugins.plugins = [MPDController]
  end
  mech = Mechanize.new
  mech.set_proxy("www-proxy.cs.tcd.ie", 8080)
  mech.max_history = 1
  ignorelist = if File.exists?('ignorelist')
			  File.open('ignorelist') do|file|
			    Marshal.load(file)
			  end
			else
			  []
			end

  helpers do
    def fetch_tweet(mech, url)
  	  id = url.match(/\/(\d+)/)[1]
  	  tweet_data = JSON.parse(mech.get("https://api.twitter.com/1/statuses/show.json?id=#{id}").content)
  	  "@#{tweet_data['user']['screen_name']}: " + tweet_data["text"]
    end
  end

  on :message, /^(?!\$).*((http|https):\/\/[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(([0-9]{1,5})?\/.*)?$)/ix do |m,text|
    ignorelist.each{|item| return if text.include? item}
  	if text.include? "twitter.com"
  	  m.reply fetch_tweet(mech, text)
  	  return
  	end
    title = mech.get(text).title
    title.gsub!(/[^[:graph:] ]/, '')
    title.gsub!(/ {2}/,'')
    GC.start
    m.reply "Title: "+ title[0..90] 
  end
  
  on :message, /\$ignore (.*)/ do |m,text|
    ignorelist << text
  	ignorelist.uniq!
  	File.open('ignorelist','w') do|file|
  	  Marshal.dump(ignorelist, file)
  	end

  	m.reply "Now ignoring: #{ignorelist}"
  end

  on :message, /\$unignore (.*)/ do |m,text|
    ignorelist.delete(text)
  	File.open('ignorelist','w') do|file|
  	  Marshal.dump(ignorelist, file)
  	end

	  m.reply "Now ignoring: #{ignorelist}"
  end
  
end

bot.start
