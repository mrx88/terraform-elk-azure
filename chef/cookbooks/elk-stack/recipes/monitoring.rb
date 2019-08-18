# Set up telegraf to send data to Influxdb and visualize in Grafana
# doc https://portal.influxdata.com/downloads
bash 'Install telegraf' do
  user 'root'
  cwd '/tmp'
  code <<-EOH
  wget https://dl.influxdata.com/telegraf/releases/telegraf_1.6.1-1_amd64.deb
  sudo dpkg -i telegraf_1.6.1-1_amd64.deb
  EOH
  not_if 'dpkg -l | grep telegraf'
end

service 'telegraf' do
  supports status: true, start: true, restart: true, reload: true
  action [:enable, :start]
end

# Using telegraf dashboard & conf from https://grafana.com/dashboards/928
template '/etc/telegraf/telegraf.conf' do
  source 'telegraf.conf.erb'
  owner 'root'
  group 'root'
  mode '0644'
  notifies :restart, 'service[telegraf]', :delayed
end
