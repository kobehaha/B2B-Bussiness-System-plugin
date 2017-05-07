Name_Mha+lvs+keepalived 实践
=================

mysql 高可用集群机构方案方案中的一种 


目录
=================

* [概要](#Mha+lvs+keepalived 实践)
* [详情](#详情)
	* [主机](#主机)
	* [架构图](#架构图)
	* [故障切换介绍](#故障切换介绍)
		* [master停止服务](#master停止服务)
		* [slave停止服务](#master停止服务)
		* [keepalived停止服务](#keepalived停止服务)
	* [关键步骤](#关键步骤)
	* [配置文件](#配置文件)
	* [相关下载](#相关下载)
	
概要介绍
=================

* 主机

	IP信息
	
	> 10.211.55.6 host2 lvs + keepalived 
	
	> 10.211.55.9 host5 lvs + keepalived + mha manager
	
	
	> vip 10.211.55.111 写[此vip 为Perl脚本自动绑定]
	
	> vip 10.211.55.112 读[此vip 为读vip为keepalived 设置]
	
	
	> 10.211.55.5 host1 mysql master 
	
	> 10.211.55.7 host3 mysql slave1
	
	> 10.211.55.8 host4 mysql slave2
	
架构图
=================
	![image](https://github.com/kobehaha/B2B-Bussiness-System-plugin/blob/master/image/normal.png)
    	
故障切换介绍
=================
	
	

关键步骤
=================

* mysql 授权
 
		grant replication slave, replication client on *.* to 'repl'@'%' identified by 'zzyhappy';
	
		flush privileges;
	

* mysql 同步状态

		show slave status\G;
 
* 重置 master --slave 状态


		master---- reset master
		
		
		slave{1,2} --
		
				  shell> stop slave 
		
				  shell> change master to master_host='10.211.55.5', master_user='repl', master_password='zzyhappy', master_port=3306, master_log_file='mysql-master-bin.000001' , master_log_pos=120, master_connect_retry=30;
				  
				  shell> start slave;
				  
				  shell> show slave status\G;

* mha 同步ssh 检测
 
 			masterha_check_ssh --conf=/usr/local/mha/app1.cnf
 			
* mha 同步检测
 
 			masterha_check_repl --conf=/usr/local/mha/app1.cnf
 	
 				  
* 启动mha manager 

 			
 
 * 观察lvs+keepalived代理状态
 
			watch -n1 "ipvsadm -Ln"

 * perl mysql主从同步脚本 脚本测试[与lvs+keepalived结合检测]
 
 			/etc/keepalived/check_slave.pl 10.211.55.6 3306
 			
 			echo $? 检测是否正确 0 同步成功 1 失败
 		
 			
 * mha ip failover检测脚本  

 			/usr/local/mha/master_ip_failover
 
 			更改脚本vip 需要配合网卡测试			



相关下载
=================

>http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
  
> https://storage.googleapis.com/google-code-archive-downloads/v2/code.google.com/mysql-master-ha/mha4mysql-node-0.53.tar.gz
  
 > https://storage.googleapis.com/google-code-archive-downloads/v2/code.google.com/mysql-master-ha/mha4mysql-manager-0.53.tar.gz
  

  
	

