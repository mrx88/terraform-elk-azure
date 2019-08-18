# Doc https://www.elastic.co/guide/en/logstash/current/installing-logstash.html

# Install openjdk java and logstash

%w(openjdk-8-jre logstash).each do |pkg|
  package pkg do
    action :install
  end
end

# Define logstash service resource, needed for automatically restarting service
# after conf change.
service 'logstash' do
  supports status: true, start: true, restart: true, reload: true
  action [:enable, :start]
end

# Not taking chef attributes into scope in this work, but probably it makes
# sense to attributize config file as well for better management.
template '/etc/logstash/logstash.yml' do
  source 'logstash.yml.erb'
  owner 'root'
  group 'root'
  mode '0644'
  notifies :restart, 'service[logstash]', :delayed
end

template '/etc/logstash/conf.d/elastic.conf' do
  source 'elastic.conf.erb'
  owner 'root'
  group 'root'
  mode '0644'
  notifies :restart, 'service[logstash]', :delayed
end
