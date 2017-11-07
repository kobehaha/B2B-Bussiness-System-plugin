#!/bin/bash

ps -fe | grep nginx | grep -v grep 
if [ $? -ne 0 ] 
then 
	sudo /usr/local/openresty/nginx/sbin/nginx -t -c /usr/local/config/nginx.conf
	
	sudo /usr/local/openresty/nginx/sbin/nginx -c /usr/local/openresty/config/nginx.conf

else 
    sudo /usr/local/openresty/nginx/sbin/nginx -t
    sudo /usr/local/openresty/nginx/sbin/nginx -s reload
fi


