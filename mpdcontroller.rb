require 'librmpd'
require 'fileutils'
require 'cinch'

class MPDController
  include Cinch::Plugin
  prefix "$"

  match /madd (.*)/, method: :mpdAdd
  match /m (.*)/, method: :mpdCommand
  match /maa (.*)/, method: :adminAdd
  match /mvote/, method: :vote
  match /mconn/, method: :connect
  match /mskip/, method: :skip

  def initialize(*args)
    super
    @adminlist = if File.exists?('adminlist')
                            File.open('adminlist') do|file|
                              Marshal.load(file)
                            end
                          else
                            ["WEH"]
                          end
    @mpd = MPD.new 'localhost', 6600
    @mpd.connect(true)
    @vote = 0
  end

  def mpdAdd(m, text)
    if !@adminlist.include?(m.user.nick)
      return
    end
    s = %x!python ~/youtube-dl.py -t #{text}!
    s =~ /Destination: (.*?)\n/
    p $1
    FileUtils.mv('/home/weh/'+$1, '/tmp/yt/')
  
    begin
      @mpd.playing?
    rescue
      @mpd = MPD.new 'localhost', 6600
      @mpd.connect
    end
    
    p @mpd.update
    p @mpd.add($1)

    if !@mpd.playing?
      @mpd.playid(@mpd.playlist.last.id)
    end
    m.reply "Added: #{$1}"
  end

  def mpdCommand(m, text)
    if !@adminlist.include?(m.user.nick)
      return
    end
    case text
    when "play"
      @mpd.play
    when "pause"
      @mpd.pause
    when "stop"
      @mpd.pause
    when "stop"
      @mpd.pause
    when "current"
      text = @mpd.current_song
    when "playlist"
      text = @mpd.playlist.collect{|t| t.file}
    when "url"
      User(m.user.nick).send "http://ice.ducss.ie/mpd.ogg.m3u"
      return
    end

    User(m.user.nick).send "mpd #{text}"
  end

  def adminAdd(m, text)
    if !@adminlist.include?(m.user.nick)
      return
    end
    (text.split",").each{|a| @adminlist << a}

    #m.reply "Added: #{$1}"
  end

  def vote(m)
    @vote +=1
    if @vote >= 3
      track = @mpd.current_song.file
      @mpd.next
      path = File.absolute_path("/tmp/yt/"+track)
      if path.start_with?"/tmp/yt/"
        File.delete(path)
      end

      @mpd.update
      @vote=0
    end
  end

  def connect(m)
    @mpd = MPD.new 'localhost', 6600
    @mpd.connect
  end
  def skip(m)
    if !@adminlist.include?(m.user.nick)
      return
    end
    track = @mpd.current_song.file
    @mpd.next
    path = File.absolute_path("/tmp/yt/"+track)
    if path.start_with?"/tmp/yt/"
      File.delete(path)
    end

    @mpd.update

    User(m.user.nick).send "#{track} removed!"
  end

end

