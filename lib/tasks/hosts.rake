# TRANSLATORS: do not translate
desc <<-END_DESC
  Try to figure out the out of sync hosts real status

  try to search them by DNS lookups and ping, if a host is not in DNS it will allow you to delete it.

  legend: 
  "." - pingable
  "x" - no ping response

  Example:
    rake hosts:scan_out_of_sync RAILS_ENV="production"

END_DESC

namespace :hosts do
  task :scan_out_of_sync => :environment do
    require 'ping'
    require 'resolv'

    def printhosts(list, description)
      unless list.empty?
        puts
        puts "found #{list.size} #{description} hosts:"
        puts "Name".ljust(40)+"Environment".ljust(20)+"Last Report"
        puts "#{"*"*80}"
        list.each do |h|
          puts h.name.ljust(40) + h.environment.to_s.ljust(20) + h.last_report.to_s(:short)
        end
      end
    end

    pingable = []
    missingdns = []
    offline = []

    Host.out_of_sync(1.hour.ago).all(:order => 'environment_id asc').collect do |host|
      $stdout.flush 
      ip = Resolv::DNS.new.getaddress(host.name).to_s rescue nil
      if ip.empty?
        missingdns << host
      else
        puts "conflict IP address for #{host.name}" unless ip == host.ip
        if Ping.pingecho host.ip
          print "."
          pingable << host
        else
          print "x"
          offline << host
        end
      end
    end
    puts
    if missingdns.empty?
      puts "All out of sync hosts exists in DNS"
    else
      printhosts(missingdns, "hosts with no DNS entry")
      puts "ctrl-c to abort - any other key to remove these hosts"
      $stdin.gets

      missingdns.each {|h| h.destroy }
    end

    printhosts(offline, "offline hosts")
    printhosts(pingable, "online hosts which are not running puppet")
  end

    desc "Clone a machine.  See source for instructions"
  # Clone a to b and get an IP from Foreman proxy
  #sudo -u foreman RAILS_ENV=production rake hosts:clone HOSTA=a.example.net HOSTB=b.example.net MAC=08002732E78F
  # CLone a to b, specifying an IP
  #sudo -u foreman RAILS_ENV=production rake hosts:clone HOSTA=a.example.net HOSTB=b.example.net MAC=08002732E78F IP=192.168.8.55
  task :clone => :environment do
    a = ENV['HOSTA']
    b = ENV['HOSTB']
    mac = ENV['MAC']
    ip = ENV['IP'] || nil
    # find host a . . .
    host_a = Host.find_by_name(a)
    if host_a.nil?
      puts "Error cloning #{ENV['HOSTA']}: Can't find #{a}"
      exit 1
    end
    # Clone a to b . . .
    begin
      host_b = host_a.clone
      host_b['name'] = b
      host_b['mac'] = mac
      # Give host b an IP address (either from CLI or looked up)
      unless host_b['ip'] = ip
        s = Subnet.find_by_id(host_b[:subnet_id])
        host_b['ip'] = s.unused_ip
      end
      #puts host_a.to_yaml
      #puts host_b.to_yaml
      # Save the new host and set it as "buildable"
      host_b.save
      host_b.setBuild
    rescue => e
      puts "Error cloning #{a}: #{e.message}"
      exit 1
    else
      puts "#{b} created with IP #{host_b['ip']}"
    end
  end

end
