# elasix
Zabbix Agent - Elasticsearch

# Dependencies
## Packages
* ksh
* jq
* curl

__**Debian/Ubuntu**__

```
#~ sudo apt install ksh jq curl
#~
```
__**Red Hat**__
```
#~ sudo yum install ksh jq curl
#~
```
# Deploy
Default variables:

NAME|VALUE
----|-----
ELASTIC_URL|http://localhost:9022
ELASTIC_USER|monitor
ELASTIC_PASS|xxxxxxx
CACHE_DIR|<empty>
CACHE_TTL|<empty>

*Note: this variables has to be saved in the config file (elasix.conf) in the same directory than the script.*

## Zabbix
Then you can run the deploy_zabbix script
```
#~ git clone https://github.com/sergiotocalini/elasix.git
#~ sudo ./elasix/deploy_zabbix.sh "<SPLUNK_URL>" "<SPLUNK_USER>" "<SPLUNK_PASS>" "<CACHE_DIR>" "<CACHE_TTL>"
#~ sudo systemctl restart zabbix-agent
``` 
*Note: the installation has to be executed on the zabbix agent host and you have to import the template on the zabbix web. The default installation directory is /etc/zabbix/scripts/agentd/elasix*
