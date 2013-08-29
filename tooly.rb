# encoding: UTF-8
require 'rubygems'
require 'mechanize'
require 'cinch'
require 'json'
require 'twitter'
require 'uri'
require 'cgi'
$LOAD_PATH << '.'
#require 'mpdcontroller.rb'

bot = Cinch::Bot.new do
  configure do |c|
    c.server = "irc.netsoc.tcd.ie"
    c.nick     = "tooly"
    c.channels = ["#ducss","#wowfag","#tcd2014","#foodie","#sc2"]
#    c.channels = ["#lolol"]
#    c.plugins.plugins = [MPDController]
  end
  Twitter.configure do |conf|
    conf.consumer_key = "*MY_VALUE*"
    conf.consumer_secret = "*MY_VALUE*"
  end
  Twitter.connection_options[:proxy] = "http://ducss.ie:3128"

  twitter = Twitter::Client.new(
  :oauth_token => "*MY_VALUE*" )
  URI::DEFAULT_PARSER.regexp[:ABS_URI]
  url_regex = URI.regexp(['http','https'])

  mech = Mechanize.new
  mech.set_proxy("www-proxy.cs.tcd.ie", 8080)
  mech.max_history = 1
  ignorelist = if File.exists?('ignorelist')
                 File.open('ignorelist') do |file|
                   Marshal.load(file)
                 end
               else
                 []
               end

  helpers do
    def fetch_tweet(twitter, url)
      screen_name = url.match(/!|\.com\/(.+?)\/stat/)[1]
      id = url.match(/\/(\d+)/)[1]
      tweet = twitter.status(id)
      "@#{screen_name}: " +  CGI.unescapeHTML(tweet.text)
    end
  end

  on :message, url_regex do |m,text|
    text = URI.extract(m.message).map {|x| x if x.include? "http"}.compact.first
    ignorelist.each{|item| return if text.include? item}
    if text.include? "twitter.com" and text.include? "/status/"
      m.reply fetch_tweet(twitter, text)
      return
    end
    puts text
    title = mech.get(text).title
    title.gsub!(/[^[:graph:] ]/, '')
    title.gsub!(/ {2}/,'')
    GC.start
    if title.length > 90
      title = title[0..90] + '…'
    end
    m.reply "Title: " + title
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
