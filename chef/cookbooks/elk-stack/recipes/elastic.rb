# Doc https://www.elastic.co/guide/en/elasticsearch/reference/current/deb.html

# Install Elasticsearch
%w(elasticsearch).each do |pkg|
  package pkg do
    action :install
    options '--force-yes'
  end
end

service 'elasticsearch' do
  supports status: true, start: true, restart: true, reload: true
  action [:enable, :start]
end

# Not taking chef attributes into scope in this work, but probably it makes
# sense to attributize config file as well for better management.
template '/etc/elasticsearch/elasticsearch.yml' do
  source 'elasticsearch.yml.erb'
  owner 'root'
  group 'elasticsearch'
  mode '0660'
  notifies :restart, 'service[elasticsearch]', :delayed
end
