#!/usr/bin/ruby
#
# RTXの情報を取得する

require 'rubygems'
require 'net/ssh'

OK = 0
NG = 2

#$mode = "debug"
$mode = ""
$message = ""
$result = OK
$host = ""
$user = ""
$password = ""

def debug(str)
  if defined?($mode) && $mode=="debug"
    puts str
  end
end

if ARGV.size != 3
  puts "usage: $0 host user password"
  exit(NG)
end

$host = ARGV[0]
$user = ARGV[1]
$password = ARGV[2]

# RTXから"show nat descriptor address all | grep use"の結果を取得する
Net::SSH.start($host, $user, :password => $password) do |ssh|
  ssh.open_channel do |channel|
    channel.send_channel_request "shell" do |ch, success|
      debug("channel.send_channel_request")
      if success
        debug("channel.send_channel_request success")
        ch.send_data("show nat descriptor address all | grep use\n")
        ch.send_data("show nat descriptor address all | grep session\n")
        debug("channel.send_channel_request send")
        ch.send_data("exit\n")
        ch.process
        ch.wait
        ch.eof!
        debug("channel.send_channel_request eof")
      else
        p "channel request error"
        $result = NG
      end
    end

    channel.on_data do |ch, data|
      debug("on_data")
      $message += data
    end
  end
  ssh.loop
end

# NATテーブルの数を取得する
debug($message)
/[0-9]+? (used|session)/ =~ $message
/[0-9]+? / =~ $&
$nat = $&.to_i

puts "nat_table:#{$nat}"
exit($result)