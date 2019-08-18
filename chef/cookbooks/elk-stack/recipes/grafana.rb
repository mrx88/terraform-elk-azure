# Set up Grafana + Influxdb

# Doc http://docs.grafana.org/installation/debian/
# Using bash resource for now
bash 'Set up elastic repos' do
  user 'root'
  cwd '/tmp'
  code <<-EOH
  apt-get install -y software-properties-common
  sudo add-apt-repository "deb https://packages.grafana.com/oss/deb stable main"
  wget -q -O - https://packages.grafana.com/gpg.key | sudo apt-key add -
  apt-get install apt-transport-https
  apt-get update
  apt-get install grafana --force-yes -y
  systemctl start grafana-server
  systemctl enable grafana-server
  EOH
end

# Install influxdb, use ubuntu 18.04 stock influxdb

package 'influxdb' do
  action :install
end
