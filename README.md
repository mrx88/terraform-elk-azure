# Introduction

Personal project to set up Elasticsearch 7, Logstash, Kibana (ELK) stack using Terraform and Chef (solo) combo on Microsoft Azure platform for non-immutable environment.
In addition, monitoring (Grafana+Influx+Telegraf stack) is set up.
This is just a POC solution with many limitations,  main goal was playing around with Terraform. 

# Prerequisites
 * Fill in variables accordingly in vars.tf

# Deployment
```
# Initialize Azure ARM provider, plugins
terraform init

# Review and validate the planned execution
terraform plan

# Apply changes
terraform apply
```

# Virtual machines

1x Jumpbox VM for uploading chef solo files for terraform provisioning and for VMs management

3x ElasticSearch VMs for elasticsearch cluster

1x Logstash VM for data processing and sending to Elasticsearch

1x Kibana VM for visualizing data in dashboard

1x Grafana and Influxdb VM for visualizing system metrics

```
martin@asdx ~/other/terraform/elk-stack az vm list -g elk-stack
[18/05/9|22:03:26]
Name ResourceGroup Location
----------------- --------------- ----------
weu-elk-elastic0 elk-stack westeurope
weu-elk-elastic1 elk-stack westeurope
weu-elk-elastic2 elk-stack westeurope
weu-elk-grafana1 elk-stack westeurope
weu-elk-jumpbox1 elk-stack westeurope
weu-elk-kibana1 elk-stack westeurope
weu-elk-logstash1 elk-stack westeurope
```

# Cluster of 3 Elasticsearch nodes


Verify that Elastic cluster with 3 nodes has been set up:

```
root@weu-elk-elastic0:~# curl -XGET 'http://weu-elk-elastic0:9200/_cluster/state?pretty'
{
"cluster_name" : "martin-development",
"compressed_size_in_bytes" : 2524,
"version" : 20,
"state_uuid" : "ReiAt2xZTqKhNOgoXFYv8A",
"master_node" : "RiF071nzQECvs2Z6feZWrg",
"blocks" : { },
"nodes" : {
"RiF071nzQECvs2Z6feZWrg" : {
"name" : "weu-elk-elastic0",
"ephemeral_id" : "fq8kcQRKRWuJNYYUQoG2Ow",


"transport_address" : "10.0.2.7:9300",
"attributes" : { }
},
"wp90yfH_S-2hbi67cE566A" : {
"name" : "weu-elk-elastic1",
"ephemeral_id" : "Uj2SFKUBTeKdWHo6oO9ZIQ",
"transport_address" : "10.0.2.6:9300",
"attributes" : { }
},
"UOW-B9T9SGWZ3KA79iV_xA" : {
"name" : "weu-elk-elastic2",
"ephemeral_id" : "D7ut_qo1Sr2_ajRYX0exoA",
"transport_address" : "10.0.2.8:9300",
"attributes" : { }
}
},
```

# Logstash Node


Http plugin is used:
https://www.elastic.co/blog/introducing-logstash-input-http-plugin


Verify that logstash listens on 5042:

```
root@weu-elk-logstash1:/etc/logstash/conf.d# netstat -lnp | grep 5042
tcp6 0 0 10.0.2.6:5042 :::* LISTEN
35022/java


# Test Logstash http plugin by sending some data:

root@weu-elk-logstash1:/etc/logstash/conf.d# curl -H "content-type:application/json" -XPUT 'http://weu-elk-logstash1:5042/twitter/tweet/1' -d '{
> "user" : "martin",
> "post_date" : "2018- 05 - 08T10:06:12",
> "message" : "testing Elasticsearch cluster again"
> }'

# Check Elastic master node:

root@weu-elk-elastic0:~# tail -5 /var/log/elasticsearch/martin-development.log
[2018- 05 - 09T06:14:22,751][INFO ][o.e.c.m.MetaDataMappingService] [weu-elk-elastic0]
[%{[@metadata][http]}-%{[@metadata][version]}-2018.05.09/P8CAgIzVQTWnGDNO0eYlxA]
create_mapping [%{[@metadata][type]}]
[2018- 05 - 09T06:14:23,446][INFO ][o.e.c.r.a.AllocationService] [weu-elk-elastic0]
Cluster health status changed from [YELLOW] to [GREEN] (reason: [shards started
[[%{[@metadata][http]}-%{[@metadata][version]}-2018.05.09][4]] ...]).
[2018- 05 - 09T06:14:42,722][INFO ][o.e.c.m.MetaDataCreateIndexService] [weu-elk-
elastic0] [.kibana] creating index, cause [auto(bulk api)], templates
[kibana_index_template:.kibana], shards [1]/[1], mappings [doc]
[2018- 05 - 09T06:14:44,268][INFO ][o.e.c.r.a.AllocationService] [weu-elk-elastic0]
Cluster health status changed from [YELLOW] to [GREEN] (reason: [shards started
[[.kibana][0]] ...]).
[2018- 05 - 09T06:14:45,214][INFO ][o.e.c.m.MetaDataMappingService] [weu-elk-elastic0]
[.kibana/8XZMNDs7Q6aGCljI9CfDlw] update_mapping [doc]

root@weu-elk-elastic0:~# curl -XGET 'http://weu-elk-elastic0:9200/_cluster/state?pretty'
..
"%{[@metadata][http]}-%{[@metadata][version]}-2018.05.09" : {
"state" : "open",
"settings" : {
"index" : {


"creation_date" : "1525846460867",
"number_of_shards" : "5",
"number_of_replicas" : "1",
"uuid" : "P8CAgIzVQTWnGDNO0eYlxA",
"version" : {
"created" : "6020499"
},
"provided_name" : "%{[@metadata][http]}-%{[@metadata][version]}-
2018.05.09"
}
},
```

# Kibana node

Verify that port is up:
```
root@weu-elk-kibana1:~# netstat -lnp | grep 5601
 tcp        0      0 0.0.0.0:5601            0.0.0.0:*               LISTEN      4230/node 
```
Verify from Kibana dashboard that Kibana can read from Elasticsearch.

![Kibana](/imgs/kibana.png "Kibana")


# Monitoring

After Grafana and Influxdb installation, I’ve manually added new Influxdb data source “martin-dev” using Grafana WebUI. For POC, I’m using default “_internal” database on localhost. As there are several Grafana dashboards (json files) available in the Internet, I’ve just googled for one that supports Telegraf and imported it to Grafana. 
https://grafana.com/dashboards/928   (“telegraf-system-dashboard_rev3.json”). 
I’m using exactly the same Telegraf configuration as well. 

![Grafana](/imgs/grafana.png "Grafana")