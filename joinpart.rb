require 'cinch'

class JoinPart
  include Cinch::Plugin

  set :prefix, //

  match(/^join (.+)/, options={:method => :join, :react_on => :private})
  match(/^part (.+)/, options={:method => :part, :react_on => :private})
  match(/^allow (.+)/, options={:method => :allow, :react_on => :private})
  match(/^disallow (.+)/, options={:method => :disallow, :react_on => :private})
  match(/^list$/, options={:method => :list, :react_on => :private})

  def initialize(*args)
    super
    @allowed = if File.exists?('adminlist')
                            File.open('adminlist') do|file|
                              Marshal.load(file)
                            end
                          else
                            ["WEH", "nsno"]
                          end
  end

  def join(m, channel)
    if @allowed.include? m.user.nick
      bot.join(channel)
      m.reply "Joining #{channel}"
    else
      m.reply "You are not allowed send me commands!"
    end
  end

  def part(m, channel)
    if @allowed.include? m.user.nick
      bot.part(channel)
      m.reply "Parting from #{channel}"
    else
      m.reply "You are not allowed send me commands!"
    end
  end

  def allow(m, user)
    if @allowed.include? m.user.nick
      @allowed << user
      m.reply "Now accepting commands from #{user}"
    else
      m.reply "You are not allowed send me commands!"
    end
  end

  def disallow(m, user)
    if @allowed.include? m.user.nick
      @allowed.delete user unless user == "WEH"
      m.reply "Not accepting commands from #{user}"
    end
  end

  def list(m)
    m.reply @allowed
  end

end
