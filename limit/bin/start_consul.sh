#!/bin/bash

ps -fe | grep consul | grep -v grep
if [ $? -ne 0 ] 
then 
	echo "consul has startted"

else
    sudo /usr/local/Cellar/consul/0.8.1/bin/consul agent  -server -ui -bootstrap-expect 1  -data-dir /usr/local/Cellar/consul/0.8.1/data  -bind 127.0.0.1 -client 127.0.0.1 -ui &
fi


