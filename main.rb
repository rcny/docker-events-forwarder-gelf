require 'bundler'
Bundler.require

options = {}

options[:host] = ENV['HOST'] if ENV['HOST']
options[:port] = ENV['PORT'].to_i if ENV['PORT']
options[:proto] = ENV['PROTO'].upcase if ENV['PROTO']
options[:chunk_size] = ENV['CHUNK_SIZE'].upcase if ENV['CHUNK_SIZE']
options[:facility] = 'docker-events-forwarder-gelf'

case options[:proto]
when 'TCP'
  options[:proto] = GELF::Protocol::TCP
when 'UDP'
  options[:proto] = GELF::Protocol::UDP
else
raise ArgumentError, 'Unknown transport protocol'
end

raise ArgumentError, 'Unknown chunk size' unless options[:chunk_size] == 'WAN' || options[:chunk_size] == 'LAN'

options.freeze

def get_host
  return ENV['HOST_HOSTNAME'] if ENV['HOST_HOSTNAME']
  return File.read('/etc/host-hostname') if File.exist?('/etc/host-hostname')
  Socket.gethostname
end

begin
  gelf = GELF::Notifier.new(options[:host], options[:port], options[:chunk_size],
         { facility: options[:facility],
           host: get_host,
           level: GELF::INFO,
           protocol: options[:proto]
         })
  gelf.collect_file_and_line = false
rescue StandardError => e
  puts "Unable to instantiate GELF notifier - #{e.class}. Check forwarder's options"
  puts e
  puts e.backtrace
  exit 1
end

docker = Excon.new('unix:///', socket: '/var/run/docker.sock', persistent: true)
handler = proc { |response_part| gelf.notify(short_message: response_part) }

begin
  docker.get(path: '/events', read_timeout: 604800, response_block: handler)
rescue Excon::Error::Timeout
  puts 'Timeout was reached. Connecting to the events stream again'
  retry
rescue Excon::Error::Socket => e
  puts "Unable to connect to the Docker socket. #{e}"
  exit 1
rescue Interrupt
  puts 'Interrupted, exiting successfully'
  docker.reset
  exit 0
rescue SignalException => e
  puts "Received #{e}, exiting successfully"
  docker.reset
  exit 0
end
