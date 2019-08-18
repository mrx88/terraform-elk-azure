# Based on https://www.elastic.co/guide/en/logstash/current/installing-logstash.html

# Elastic repo set up
bash 'Set up elastic repos' do
  user 'root'
  cwd '/tmp'
  code <<-EOH
  wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | apt-key add -
  apt-get install apt-transport-https
  echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | tee -a /etc/apt/sources.list.d/elastic-7.x.list
  apt-get update
  EOH
  not_if { ::File.exist?('/etc/apt/sources.list.d/elastic-7.x.list') }
end
