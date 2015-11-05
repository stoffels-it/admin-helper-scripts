# encoding: utf-8

require 'net/ping'

checksite = 'www.google.com'
p1 = Net::Ping::TCP.new(checksite, 'http')

loop do
  puts p1.ping?.to_s + ': ' + Time.new.inspect
  file = File.open('log.txt', 'a')
  file.puts(p1.ping?.to_s + ': ' + Time.new.inspect)
  if !p1.warning.nil?
    puts p1.warning
    file.puts(p1.warning.to_s)
  end
  if !p1.exception.nil?
    puts p1.exception
    file.puts(p1.exception.to_s)
  end
  file.close unless file.nil?
  sleep(5)
end
