require 'rubygems'
require 'rest-client'
require 'json'

def vipr_session(viprurl, username, password)
  vipr_session_link = RestClient::Resource.new(viprurl + '/login', username, password )
  vipr_session_response = vipr_session_link.get
  myvar = 'x_sds_auth_token'
  @mysession = vipr_session_response.headers[myvar.to_sym]
end

@username = 'root'
@password = 'mysecretpw'
@viprurl = 'https://192.168.50.141:4443'

print " Logging into ViPR..."
  vipr_session(@viprurl, @username, @password)
print "Success! \n\n\n"

puts " Gathering vCenter & Host Information..."
  vcenters = JSON.parse(RestClient.get(@viprurl + '/compute/vcenters/bulk', :x_sds_auth_token => @mysession, :content_type => :json, :accept => :json))
    vcenters['id'].each do |vcenter|
      parsed = JSON.parse(RestClient.get(@viprurl + '/compute/vcenters/' + vcenter, :x_sds_auth_token => @mysession, :content_type => :json, :accept => :json))
      puts "vCenter name is " + parsed["name"] + "."
      puts parsed["name"] + " version is " + parsed["os_version"] + "."
      puts parsed["name"] + " is " + parsed["registration_status"] + "."
      puts parsed["name"] + " GUID is " + parsed["native_guid"]
      
      hostsparsed = JSON.parse(RestClient.get(@viprurl + '/compute/vcenters/' + vcenter + '/hosts', :x_sds_auth_token => @mysession, :content_type => :json, :accept => :json))
      hostarray = []
      hostsparsed['host'].each do |host|
        hostarray << [host['name'], host['id']]
      end
      puts parsed["name"] + " has " + hostarray.length.to_s + " hosts: "
        hostarray.each {|x| print x[0] + " "}.to_s
      puts "\n\n"
      
      hostarray.each do |hosturl|
        hostinfo = JSON.parse(RestClient.get(@viprurl + '/compute/hosts/' + hosturl[1] + '/ip-interfaces' , :x_sds_auth_token => @mysession, :content_type => :json, :accept => :json))
        puts hosturl[0].to_s + " has the following configured interfaces: "
         hostinfo["ip_interface"].each {|interface| print interface["name"] + " "}
        puts ""
      end
  end

puts "\n Gathering ViPR Service Statistics..."
  stats = JSON.parse(RestClient.get(@viprurl + '/monitor/stats', :x_sds_auth_token => @mysession, :content_type => :json, :accept => :json))
    stats['node_stats_list']['node_stats']['service_stats_list']['service_stats'].each do |stat|
      puts "Service: " + stat["name"]
      puts "Descriptor ID: " + stat["file_descriptors_ctr"]
      if stat["status"]["total_uptime_seconds"].to_i > 0 
        puts "Status: ACTIVE"
        puts "Uptime: " + Time.at(stat["status"]["total_uptime_seconds"].to_i).utc.strftime("%H:%M:%S")
        puts "Active Threads: " + stat["status"]["active_threads_ctr"]
        puts "Process ID: " + stat["status"]["pid"] + "\n\n"
      else
        puts "Status: DOWN \n\n"
      end

  end