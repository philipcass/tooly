require 'rubygems'
require 'mechanize'
require 'cinch'
require 'json'
require 'twitter'
$LOAD_PATH << '.'
require 'mpdcontroller.rb'

bot = Cinch::Bot.new do
  configure do |c|
    c.server = "irc.netsoc.tcd.ie"
    c.nick     = "tooly"
    c.channels = ["#tooly"]
    c.plugins.plugins = [MPDController]
  end
  Twitter::Client.configure do |conf|
    conf.proxy_host = 'www-proxy.cs.tcd.ie'
    conf.proxy_port = 8080
  end

  twitter = Twitter::Client.new(:oauth_access => {
  :key => "MYPUBLIC", :secret => "MYSECRET" })


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
    def fetch_tweet(twitter, url)
      screen_name = url.match(/!|\.com\/(.+?)\/stat/)[1]
  	  id = url.match(/\/(\d+)/)[1]
      tweet = twitter.status(:get, id)
  	  "@#{screen_name}: " + tweet.text
    end
  end

  on :message, /^(?!\$).*((http|https):\/\/[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(([0-9]{1,5})?\/.*)?$)/ix do |m,text|
    ignorelist.each{|item| return if text.include? item}
  	if text.include? "twitter.com"
  	  m.reply fetch_tweet(twitter, text)
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
