# docker-compose exec influxdb telegraf -sample-config -input-filter file -output-filter influxdb > file.conf
# curl -i -XPOST http://localhost:8086/query --data-urlencode "q=CREATE DATABASE mydb"
