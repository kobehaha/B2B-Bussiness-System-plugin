简单CDN架构实践
==========


目录
=================

* [概要](#简单CDN架构实践)
* [详情](#详情)
	* [主机](#主机)
	* [简单架构图](#简单架构图)
	* [简单介绍](#简单介绍)	
	* [关键步骤](#关键步骤)
	* [配置文件与相关脚本](#配置文件与相关脚本)
	* [相关下载](#相关下载)
	* [思考](#思考)
	* [个人想法](#个人想法)


主机
==========

    host1 ---> squid1 squid2 
    host2 ---> nginx
               apache1 
               apache2  
    host3 ---> squid3 squid4
    host5 ---> bind 
    host4 ---> lvs 


简单架构图
==========

![image](https://github.com/kobehaha/B2B-Bussiness-System-plugin/blob/master/image/cdn2.png)

详情
==========



简单介绍
==========

![image](https://github.com/kobehaha/B2B-Bussiness-System-plugin/blob/master/image/cdn_show.png)


关键步骤
==========


* squid1 + squid2[arp抑制]

> 绑定vip [绑定本地还回地址]
	
	ifconfig lo:0 10.211.55.113  netmask 255.255.255.255 broadcast 10.211.55.113 up
	
	route add -host 10.211.55.113 dev lo:0
	
> arp抑制
	
	net.ipv4.ip_forward = 0
	net.ipv4.conf.lo.arp_ignore = 1
	net.ipv4.conf.lo.arp_announce = 2
	net.ipv4.conf.all.arp_ignore = 1
	net.ipv4.conf.all.arp_announce = 2

* squid3 + squid4[正常配置]



* lvs vip配置和dr代理配置

> 绑定vip [网卡上]
	
	ifconfig eth2:0 10.211.55.113 netmask 255.255.255.255 broadcast 10.211.55.113
	
	route add -host 10.211.55.113 dev eth2:0
	
> lvs 增加路由

	ipvsadm -A -t 10.211.55.113:80 -s rr
	
	ipvsadm -a -t 10.211.55.113:80 -r 10.211.55.14 -g
	
	ipvsadm -a -t 10.211.55.113:80 -r 10.211.55.7 -g

> 系统转发配置
 
    vim /etc/sysctl  添加
	
	net.ipv4.ip_forward = 0
	net.ipv4.conf.all.send_redirects = 1
	net.ipv4.conf.default.send_redirects = 1
	net.ipv4.conf.eth2.send_redirects = 1
	
	sysctl -p 配置生效
	
> 查看系统代理情况[多刷新几次可以看到页面具体情况]
	
	    ipvadm -Ln 
	
	
* 代理查询[请求均匀分布]

      squid 1 tail -400f /usr/local/squid/var/logs/access.log
	
	    squid 2 tail -400f /usr/local/squid/var/logs/access.log
	
	
* bind DNS服务器搭建


> 安全校验文件
	
		cd /usr/local/bind/etc 
		
		/usr/local/bind/sbin/rndc-confgen > rndc.conf
		
		cat rndc.conf > rndc.key
		
		chmod 777 /usr/local/bind/var
		
		tail -n10 rndc.conf | head -n9 | se -e s /#\ //g > name.conf
		
		
		
> 校验配置
		
		/usr/local/bind/sbin/named-checkzone cdn.com /usr/local/bind/var/cdn.com.zone

> 更改dns 
	
	vi /etc/resolv.conf
	
	nameserver ---> 10.211.55.9
	
	
	--> nslookup www.cdn.com
	
		Server:		10.211.55.9
		Address:	10.211.55.9#53

		Name:	www.cdn.com
		Address: 10.211.55.6

	
	
配置文件与相关脚本
==========
    
   > 配置文件都在config文件夹下简单可以区分出差别
    
        ├── apache1.conf_host2
        ├── apache2.conf_host2
        ├── bind_cdn.com.zone_host5
        ├── bind_name.conf_host5
        ├── lvs_host4
        ├── nginx.conf_main_host2
        ├── nginx.conf_www.cdn.com_host2
        ├── squid1.conf_host1
        ├── squid2.conf_host1
        ├── squid3.conf_host3
        └── squid4.conf_host3

    
   > 没有针对每个服务都做脚本启动
   
        apache1 --->  /usr/local/apache/bin/apachectl -c 
        /usr/local/apache/conf/httpd.conf
        
        apache2 ---> /usr/local/apache2/bin/apachectl -c 
        /usr/local/apache2/conf/httpd.conf
        
        squid1 ---->  /usr/local/squid/sbin/squid -f 
        /usr/local/squid/etc/squid.conf
        
        squid2 ----> /usr/local/squid2/sbin/squid -f
         /usr/local/squid2/etc/squid.conf
        
        squid3 ----> /usr/local/squid/sbin/squid -f 
        /usr/local/squid/etc/squid.conf
        
        squid4 ----> /usr/local/squid2/sbin/squid -f 
        /usr/local/squid4/etc/squid.conf
        
        bind   ----> /usr/local/bind/sbin/named
        
        nginx -----> /etc/init.d/nginx
        
        lvs   -----> 参考上面
        
        


思考
==========

> gslb 全局负载均衡需要更多合理的设置

		服务器方向 比如每台cache的负载，每台机器的速度,网络
		用户来源方向 用户的属于的isp,用户的访问历史记录

> 智能dns 
		
		我这只用了bind 做的dns 也存在单点问题 最少做个主备,或则用其他的方式更全一点的
		
> 多级缓存
			
		现在的lvs只是做了一层代理负载均衡其实应该在代理上有一个全局的中心存储, 比如用户在这个缓存服务器获取数据失败不应该立马就去源数据获取,而是cdn公司每个地域搭建一个自己的数据中心,如果没有获取数据从自己的数据中心先去拿..
		
> 缓存系统的优化

		现在用的squid 其实现在有很多比较好的开源实现,比如vanish , nginx  各有各自的有点,比如vanish是基于内存的,非常适合于超热点数据的cache,如果说公司有能力最好自己根据自己的业务实现比如squid服务器上使用SSD+SAS+SATA混合存储根据数据热点来做，
		CDN缓存服务其实是一种IO密集型的任务，因此用一些低功耗的服务器，可以在保证性能的同时提升整体性能


> 系统高可用问题
		
		从我这个系统来说不是很完善,系统不是高可用的,对于一个提供cdn的服务来说，服务必须高可用，用开源的keepalived， hearbeat 或则用其他的方式做一个vip应该是可行的

> 负载均衡

		我选用lvs nginx 做的四层和七层负载均衡 具体情况具体来用吧，可以四层后加一个七层的，增加负载能力lvs dr的性能就是为这种情景而生的,如果用haproxy 或则土豪级别的硬件F5也是可以的，看公司的情况吧

> 刷新缓存
		
		目前的刷新缓存只能用squid提供的客户端去手动刷新,可以做一个页面 集成salt或则ansible类似的来自动的刷新
		
		
	
个人想法	
==========

个人不是做CDN系统的,不过系统CDN系统越做越好，越来越智能
