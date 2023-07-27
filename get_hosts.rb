require 'rubygems'
require 'net/http'
require 'uri'
require 'json'
require 'optparse'
require 'yaml'
require 'pp'
require 'fileutils'
require 'rest-client'
require 'colorize'
require 'highline/import'
##############################################################################################
//Erstellen von Arrays, Laden der Config und Einlesen des Passwortes
warninglinux = []
failedlinux = []
warningwindows = []
failedwindows = []
choice = []
choice2 = []
choice3 = []

configuration = YAML.load_file('config.yml')
##############################################################################################
options = {}
OptionParser.new do |opts|
  opts.banner = "out_of_sync.rb [-c][-o/e][-x][-y]"

  opts.on('-c', '--customer CUSTOMER') { |v| options[:customer] = v }
  opts.on('-o', '--os OS') { |v| options[:os] = v }
  opts.on('-e', '--exclude EXCLUDE OS') { |v| options[:exclude] = v }
  opts.on('-s', '--exclude EXCLUDE SERVER') { |v| options[:excludehost] = v }
  opts.on('-x', '--customeroutofsync OUT OF SYNC') { |x| options[:customeroutofsync] = x }
  opts.on('-y', '--customererror ERROR') { |y| options[:customererror] = y}

  opts.on_tail('-h', '--help', 'Show this Message') do
    puts opts
    exit
  end
end.parse!
##############################################################################################

customer = options[:customer]
exclude = options[:exclude]
excludehost = options[:excludehost]
os = options[:os]
customeroutofsync = options[:customeroutofsync]
customererror = options[:customererror]
password = ask("Enter password: ") { |q| q.echo = false }

//Die Url wird zussamengefügt
url = URI.parse(configuration['path_common'] + '/api/v2/hosts?per_page=1000')
puts "[#{"...".yellow}] Trying to establish a connection..."
sleep 1
begin
//Verbindungsaufbau zu Foreman und Login
  Net::HTTP.start(url.host, url.port, :read_timeout => 500,  :use_ssl => url.scheme == 'https', :verify_mode => OpenSSL::SSL::VERIFY_NONE) do |http|
  begin
    request = Net::HTTP::Get.new url.to_s
    request.basic_auth configuration['user'], password
    response = http.request request
    case response
    //Überprüfung, ob Login erfolgreich ist
    when Net::HTTPSuccess
      puts "[#{"OK".green}] Password correct"
      puts "[#{"OK".green}] Connection established"
      puts "\n"
      print "[#{"...".yellow}] Collecting data..."
      puts "\n"
      //Speichern der Daten in Variable
      response = http.request request
      puts "[#{"OK".green}] Data collected"
      decoded_response['results'].each do |host|
        warninglinux << host['name'] if (host['global_status_label'] == "Warning" and host['enabled'] == true unless host['operatingsystem_name'].include? 'windows' unless host['name'].include? "win")
      end
      decoded_response['results'].each do |host|
        failedlinux << host['name'] if (host['global_status_label'] == "Error" and host['enabled'] == true unless host['operatingsystem_name'].include? 'windows' unless host['name'].include? "win")
      end
      decoded_response['results'].each do |host|
         warningwindows << host['name'] if (host['global_status_label'] == "Warning" and host['enabled'] == true and host['operatingsystem_name'].include? 'windows')
       end
       decoded_response['results'].each do |host|
          failedwindows << host['name'] if (host['global_status_label'] == "Error" and host['enabled'] == true and host['operatingsystem_name'].include? 'windows')
       end
       
       unless customer.nil?
         unless os.nil?
           decoded_response['results'].each do |host|
              choice << host['name'] if (host['name'].include? "#{customer}" and host['operatingsystem_name'].include? "#{os}" unless host['name'].include? excludehost)
           end
         else
           unless exclude.nil?
             decoded_response['results'].each do |host|
               choice << host['name'] if (host['name'].include? "#{customer}")
             end
           else
             unless excludehost.nil?
               decoded_response['results'].each do |host|
                 choice << host['name'] if (host['name'].include? "#{customer}" unless host['name'].include? excludehost)
               end
             else
               decoded_response['results'].each do |host|
                 choice << host['name'] if (host['name'].include? "#{customer}")
               end
             end
           end
         end
       end
      
       unless customeroutofsync.nil?
          decoded_response['results'].each do |host|
            choice2 <<  host['name'] if (host['global_status_label'] == "Warning" and host['name'].include? "#{customeroutofsync}" and host['enabled'] == true unless host['operatingsystem_name'].include? 'windows' unless host['name'].include? "win")
          end
       end

       unless customererror.nil?
          decoded_response['results'].each do |host|
            choice3 << host['name'] if (host['global_status_label'] == "Error" and host['name'].include? "#{customererror}" and host['enabled'] == true unless host['operatingsystem_name'].include? 'windows' unless host['name'].include? "win")
          end
       end
      
      //Abspeichern der Ergebnisse in temporären Files
        File.open('/var/log/foreman/logs/warning_linux.log', 'a+') do |file|
          file.puts "###################################"
          file.puts time.inspect
          file.puts warninglinux
        end

        File.open('/var/log/foreman/logs/failed_linux.log', 'a+') do |file|
          file.puts "###################################"
          file.puts time.inspect
          file.puts failedlinux
        end
        
        File.open('/var/log/foreman/logs/warning_windows.log', 'a+') do |file|
          file.puts "###################################"
          file.puts time.inspect
          file.puts warningwindows
        end

        File.open('/var/log/foreman/logs/logs/failed_windows.log', 'a+') do |file|
          file.puts "###################################"
          file.puts time.inspect
          file.puts failedwindows
        end

        unless customer.nil?
          File.open('/var/log/foreman/logs/customer.log', 'a+') do |file|
          file.puts "###################################"
          file.puts time.inspect
          file.puts choice
          end
        end
      
        unless customeroutofsync.nil?
          File.open('/Users/mgebert/Documents/ruby/foreman/logs/customer-sync.log', 'a+') do |file|
          file.puts "###################################"
          file.puts time.inspect
          file.puts choice
          end
        end

        unless customererror.nil?
          File.open('/Users/mgebert/Documents/ruby/foreman/logs/customer-error.log', 'a+') do |file|
          file.puts "###################################"
          file.puts time.inspect
          file.puts choice
          end
        end
      
      //Aneinanderreihung der Hostnamen (durch Leerzeichen getrennt) und anschließende Ausgabe
          result1 = warninglinux.join(" ")
          result2 = failedlinux.join(" ")
          result3 = choice.join(" ")
          result4 = warningwindows.join(" ")
          result5 = failedwindows.join(" ")
          result6 = choice2.join(" ")
          result7 = choice3.join(" ")
          puts "[#{"OK".green}] Finished succesfully"
          puts "\n"
          puts "[#{"RESULTS".green}]"
          puts "[#{"OK".green}] Finished succesfully"
          puts "\n"
          puts "[#{"RESULTS".green}]"
          puts "[#{"LINUX Out of Sync".yellow}]"
          puts "csshX --login root " << result1
          puts "\n"
          puts "[#{"LINUX Errorhosts".yellow}]"
          puts "csshX --login root " << result2
          puts "\n"
          puts "[#{"WINDOWS Out of Sync".yellow}]"
          puts  result4
          puts "\n"
          puts "[#{"WINDOWS Errorhosts".yellow}]"
          puts result5
          puts "\n"
          unless customer.nil?
            puts "[#{"Hosts of your choice".yellow}]"
            puts "csshX --login root " << result3
            puts "\n"
          else
            puts "[#{"Hosts of your choice".yellow}]"
            puts "[#{"[NOTHING]".yellow}]"
            puts "\n"
          end
          unless customeroutofsync.nil?
            puts "[#{"Hosts out of sync of your choice".yellow}]"
            puts "csshX --login root " << result6
            puts "\n"
          else
            puts "[#{"Hosts out of sync of your choice".yellow}]"
            puts "[#{"[NOTHING]".yellow}]"
            puts "\n"
          end
          unless customererror.nil?
            puts "[#{"Hosts in error state of your choice".yellow}]"
            puts "csshX --login root " << result7
            puts "\n"
          else
            puts "[#{"Hosts in error state of your choice".yellow}]"
            puts "[#{"[NOTHING]".yellow}]"
            puts "\n"
          end
      puts "[#{"OK".green}] Finished succesfully"
      //Unauthorisierter Zugriff
    when Net::HTTPUnauthorized
      puts "[#{"FAILED".red}] Wrong Password!"
    end
    //Rescue Execption 1
    rescue Exception => error
      puts "[#{"FAILED".red}] Password incorrect or actions failed!"
      sleep 1
      puts 'ERROR: ' + error.message
      sleep 1
      puts "Skipping run..."
    end
  end
    //Rescue Execption 2
rescue Exception => error
  puts "[#{"FAILED".red}] Failed to establish a connection!"
  sleep 1
  puts 'ERROR: ' + error.message
  sleep 1
  puts "Skipping run..."
end
