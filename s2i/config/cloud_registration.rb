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
config = '/etc/puppetlabs/puppetserver/conf.d/registration_credentials.yaml'
if File.exists?(config)
    DEFAULT_CREDENTIALS = YAML::load( File.open(config))
    @mysql = {
      :host   => DEFAULT_CREDENTIALS['MYSQL_HOST'],
      :user   => DEFAULT_CREDENTIALS['MYSQL_USER'],
      :passwd => DEFAULT_CREDENTIALS['MYSQL_PASSWORD'],
      :db     => DEFAULT_CREDENTIALS['MYSQL_DATABASE'],
      :port   => DEFAULT_CREDENTIALS['MYSQL_PORT'],
      :flag   => DEFAULT_CREDENTIALS['MYSQL_FLAG']
    }
else
    @mysql = {
      :host   => ENV['AUTOSIGNING_MYSQL_HOST'],
      :user   => ENV['AUTOSIGNING_MYSQL_USER'],
      :passwd => ENV['AUTOSIGNING_MYSQL_PASSWORD'],
      :db     => ENV['AUTOSIGNING_MYSQL_DATABASE'],
      :port   => ENV['AUTOSIGNING_MYSQL_PORT'],
      :flag   => ENV['AUTOSIGNING_MYSQL_FLAG']
    }
end

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
