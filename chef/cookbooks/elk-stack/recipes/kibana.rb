# Doc https://www.elastic.co/guide/en/kibana/current/deb.html

# Install Kibana
package 'kibana' do
  action :install
end

service 'kibana' do
  supports status: true, start: true, restart: true, reload: true
  action [:enable, :start]
end

template '/etc/kibana/kibana.yml' do
  source 'kibana.yml.erb'
  owner 'root'
  group 'root'
  mode '0644'
  notifies :restart, 'service[kibana]', :delayed
end
