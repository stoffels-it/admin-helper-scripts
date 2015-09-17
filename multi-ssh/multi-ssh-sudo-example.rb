require 'net/ssh'
require 'yaml'

# load config
config = YAML.load_file('config.yml')

def ssh_ops(s, pw)
    output = s.exec!("hostname")
    puts "successfully logged in to " + output

    # open a new channel and configure a minimal set of callbacks, then run
    # the event loop until the channel finishes (closes)
    s.open_channel do |channel|
        # open pty
        channel.request_pty do |pty, success| 
            raise "Error requesting pty" unless success 
            channel.exec "sudo apt-get update" do |ch, success|
                raise "could not execute command" unless success

                channel.send_data("#{pw}\n")

                # "on_data" is called when the process writes something to stdout
                channel.on_data do |ch, data|
                    puts "got stdout: #{data}"
                end

                # "on_extended_data" is called when the process writes something to stderr
                channel.on_extended_data do |ch, type, data|
                    puts "got sterr: #{data}"
                end

                channel.on_close do |ch|
                    puts "channel is closing"
                end
            end
        end
    end  
end

# loop through hosts and connect to each
config['hosts'].each do |host,details|

    # assign login data, get it from host subkeys or global config
    begin
        user = ((details['user'] if details) or config['global']['user'])
        pass = ((details['pw'] if details) or config['global']['pw'])
        encryption = ((details['encryption'] if details) or config['global']['encryption']),
        keys = ((details['keys'] if details) or config['global']['keys']),
        compression = ((details['compression'] if details) or config['global']['compression'])
    rescue
        puts "login data not available in config file."
        next
    end

    begin
        # start ssh session
        Net::SSH.start(
            host,
            user,
            :password => pass,
            :encryption => encryption,
            :keys => keys,
            :compression => compression 
        ) do |session|
            # perform server operations after login
            ssh_ops(session, pass)
        end
    rescue Timeout::Error
        puts "  Timed out"
    rescue Errno::EHOSTUNREACH
        puts "  Host unreachable"
    rescue Errno::ECONNREFUSED
        puts "  Connection refused"
    rescue Net::SSH::AuthenticationFailed
        puts "  Authentication failure"
    end
end