#!/opt/puppetlabs/bin/puppetserver ruby
STDOUT.sync = true
require 'rubygems'
require 'mysql'
require 'optparse'
require 'yaml'

def quote (str)
  str.gsub(/\\|'/) { |c| "\\#{c}" }
end

hostname = ARGV[0]
DEFAULT_CREDENTIALS = YAML::load( File.open('/usr/local/scripts/registration_credentials.yaml'))

@mysql = {
  :host   => DEFAULT_CREDENTIALS['mysql_host'],
  :user   => DEFAULT_CREDENTIALS['mysql_user'],
  :passwd => DEFAULT_CREDENTIALS['mysql_passwd'],
  :db     => DEFAULT_CREDENTIALS['mysql_db'],
  :port   => DEFAULT_CREDENTIALS['mysql_port'],
  :flag   => DEFAULT_CREDENTIALS['mysql_flag'],
}

puts "Initialising MySQL connection"
begin
  @connection = Mysql.real_connect(@mysql[:host],@mysql[:user],@mysql[:passwd],@mysql[:db])
rescue Mysql::Error => e
  puts "Error SQLSTATE: #{e.sqlstate}" if e.respond_to?("sqlstate")
end

time = Time.new()
timestamp = time.strftime('%Y-%m-%d %H:%M:%S')
puts 'Time of processing: ' + timestamp.to_s

registration_check = @connection.query('INSERT INTO registrations (hostname,allowed,signed,request_time,sign_time,openstack) VALUES ("' + hostname + '",1,1,"' + timestamp + '","' + timestamp + '",1)')
returncode = 0

puts 'Registration attempt from ' + hostname
@connection.close

exit(returncode)
