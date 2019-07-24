#!/opt/puppetlabs/bin/puppetserver ruby
STDOUT.sync = true
require 'rubygems'
require 'activerecord-jdbcmysql-adapter'
require 'optparse'
require 'yaml'

def quote (str)
  str.gsub(/\\|'/) { |c| "\\#{c}" }
end

hostname = ARGV[0]
DEFAULT_CREDENTIALS = YAML::load( File.open('/etc/puppetlabs/puppetserver/conf.d/registration_credentials.yaml'))

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
  @conn = ActiveRecord::Base.mysql_connection(
    { :adapter => 'mysql',
      :database => @mysql[:db],
      :host => @mysql[:host],
      :username => @mysql[:user],
      :password => @mysql[:passwd] }
   )
rescue ActiveRecord::JDBCError => e
  puts "Error SQLSTATE: #{e}"
end

time = Time.new()
timestamp = time.strftime('%Y-%m-%d %H:%M:%S')
puts 'Time of processing: ' + timestamp.to_s

registration_check = @conn.execute('INSERT INTO registrations (hostname,allowed,signed,request_time,sign_time,openstack) VALUES ("' + hostname + '",1,1,"' + timestamp + '","' + timestamp + '",1)')
returncode = 0

puts 'Registration attempt from ' + hostname

exit(returncode)
