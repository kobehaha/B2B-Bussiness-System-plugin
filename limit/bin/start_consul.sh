#!/bin/bash

ps -fe | grep consul | grep -v grep
if [ $? -ne 0 ] 
then 
	echo "consul has startted"

else
    sudo /usr/local/Consul/consul agent  -server -ui -bootstrap-expect 1  -data-dir /usr/local/Consul/data  -bind 10.211.55.14 -client 10.211.55.14 -ui &
fi


