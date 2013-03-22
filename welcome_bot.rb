#!/usr/local/bin/ruby

require 'socket'
require 'yaml'

# The irc class, which talks to the server and holds the main event loop
class WelcomeBot
  RECORD_FILE = File.expand_path '~/.ruboto_irc'

  def initialize(server, port, nick, channel)
    @server = server
    @port = port
    @nick = nick
    @channel = channel
    @store = File.exists?(RECORD_FILE) ? YAML.load(File.read(RECORD_FILE)) :
        {:record => 0, :people => {}}
  end

  def send(s)
    # Send a message to the irc server and print it to the screen
    puts "--> #{s}"
    @irc.send "#{s}\n", 0
    sleep 1
  end

  def connect
    # Connect to the IRC server
    @irc = TCPSocket.open(@server, @port)
    send 'USER RubotoWelcomeBot 8 * :Ruboto Welcome Bot'
    send "NICK #{@nick}"
    send "JOIN #{@channel}"
  end

  def handle_server_input(s)
    puts s
    case s.strip
    when /^PING :(.+)$/i
      puts '[ Server ping ]'
      send "PONG :#{$1}"
    when /^:(.+?)!(.+?)@(.+?)\sPRIVMSG\s.+\s:[\001]PING (.+)[\001]$/i
      puts "[ CTCP PING from #{$1}!#{$2}@#{$3} ]"
      send "NOTICE #{$1} :\001PING #{$4}\001"
    when /^:(.+?)!(.+?)@(.+?)\sPRIVMSG\s.+\s:[\001]VERSION[\001]$/i
      puts "[ CTCP VERSION from #{$1}!#{$2}@#{$3} ]"
      send "NOTICE #{$1} :\001VERSION Ruby-irc v0.042\001"
    when /^:(.+?) (\d+) #{@nick} = #{@channel} :(.*)$/
      attendees = $3.split(' ').map { |a| a.gsub '@', '' }
      attendees -= [@nick, 'irclogger_com']
      attendees.delete_if{|a| a =~ /GitHub\d+/}
      puts "People: #{attendees.join(' ')}"
      record = @store[:record]
      crowd = attendees.size
      attendees.each do |a|
        welcome(a) unless @store[:people][a]
      end
      if crowd > record
        update_record(crowd)
      end
      save_store
    when /^:(.+?)!(.*?)@(.*?) JOIN #{@channel}$/
      new_user = $1
      if new_user == @nick || new_user =~ /GitHub\d+/
        puts '[ IGNORED ]'
      else
        if @store[:people].include?(new_user)
          puts "Old member rejoined: #new_user.  Last seen #{(@store[:people][new_user][:joined] || @store[:people][new_user][:quit]).strftime '%Y-%m-%d %H:%M'}"
          @store[:people][new_user][:joined] = Time.now
        else
          welcome(new_user)
        end
        join_count = @store[:people].select { |n, d| d[:quit].nil? || d[:joined] > d[:quit] }.size
        puts "People: #{join_count}"
        if join_count > @store[:record]
          update_record(join_count)
        end
        save_store
      end
    when /^:(.+?)!(.+?)@(.+?) QUIT :(.*)$/
      @store[:people][$1][:quit] = Time.now
      save_store
    else
      puts '[ IGNORED ]'
    end
  end

  def update_record(join_count)
    send "PRIVMSG #{@channel} :Wow!  #{join_count} people on this channel!  That's a new record!"
    @store[:record] = join_count
  end

  def welcome(nick)
    send "PRIVMSG #{@channel} :#{nick}:  Hi!  Welcome to the #{@channel} channel!"
    send "PRIVMSG #{@channel} :#{nick}:  Ping any op or member if you have a question.  donV is on European time."
    send "PRIVMSG #{@channel} :#{nick}:  Please be patient and hang around if you don't get a response immediately."
    @store[:people][nick] = {:joined => Time.now}
    send "PRIVMSG donV :#{nick} is number #{@store[:people].size} who joined the #{@channel} channel."
    sleep 30
  end

  def save_store
    File.open(RECORD_FILE, 'w') { |f| f << YAML.dump(@store) }
  end

  def main_loop
    # Just keep on truckin' until we disconnect
    while true
      ready = select([@irc, $stdin], nil, nil, nil)
      next if !ready
      ready[0].each { |s|
        if s == $stdin
          return if $stdin.eof
          s = $stdin.gets
          send s
        elsif s == @irc then
          return if @irc.eof
          s = @irc.gets
          handle_server_input(s)
        end
      }
    end
  end
end

# The main program
# If we get an exception, then print it out and keep going (we do NOT want
# to disconnect unexpectedly!)
irc = IRC.new('irc.freenode.net', 6667, 'welcome_bot', '#ruboto')
irc.connect()
begin
  irc.main_loop()
rescue Interrupt
  # ignored
rescue Exception => detail
  puts detail.message()
  print detail.backtrace.join("\n")
  retry
end
