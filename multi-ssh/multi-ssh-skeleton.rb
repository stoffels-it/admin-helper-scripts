require 'net/ssh'
require 'yaml'

# load config
config = YAML.load_file('config.yml')

def ssh_ops(s)
    output = s.exec!("hostname")
    puts "successfully logged in to " + output
end

# loop through hosts and connect to each
config['hosts'].each do |host,details|

    # assign login data, get it from host subkeys or global config
    begin
        user = ((details['user'] if details) or config['global']['user'])
        pw = ((details['pw'] if details) or config['global']['pw'])
        encryption = ((details['encryption'] if details) or config['global']['encryption']),
        keys = ((details['keys'] if details) or config['global']['keys']),
        compression = ((details['compression'] if details) or config['global']['compression'])
    rescue
        puts "login data not available in config file."
    end

    begin
        # start ssh session
        Net::SSH.start(
            host,
            user,
            :password => pw,
            :encryption => encryption,
            :keys => keys,
            :compression => compression 
        ) do |session|
            # perform server operations after login
            ssh_ops(session)
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