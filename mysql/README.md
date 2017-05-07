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
	* [配置文件与相关脚本](#配置文件与相关脚本)
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


### 正常

![image](https://github.com/kobehaha/B2B-Bussiness-System-plugin/blob/master/image/normal.png)


    
故障切换介绍
=================

master停止服务

![image](https://github.com/kobehaha/B2B-Bussiness-System-plugin/blob/master/image/master_down.png)

```
    master 宕机 mha--> 
                    1 从alived 候选slave中选出最新数据的当做master
                    2 把old_master 的同步数据同步到新的master
                    3 把新master 数据同步到旧的slave 然后把旧的slave的master 切换为新master,开始同步
                    4 master_ip_failover脚本自动切换绑定的vip,old ip 解绑 新的绑定上去
                      
                       
```


slave停止服务
![image](https://github.com/kobehaha/B2B-Bussiness-System-plugin/blob/master/image/slave_down.png)

```

    slave 宕机 ---> 
                1 keepalived 检测脚本tcp 检测和自定义检测都会检测到不能服务
                2 从代理列表中移除
```
keepalived停止服务
![image](https://github.com/kobehaha/B2B-Bussiness-System-plugin/blob/master/image/keepalived_down.png)

```
    keepalived 宕机 -->
                1 切换到备keepalived 代理也切换
```
	

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
    
            masterha_manager --conf=/usr/local/mha/app1.cnf >> /usr/local/mha/logs/manager.log < /dev/null 2 &>1 &
 			

 * 观察lvs+keepalived代理状态
 
			watch -n1 "ipvsadm -Ln"

 * perl mysql主从同步脚本 脚本测试[与lvs+keepalived结合检测]
 
 			/etc/keepalived/check_slave.pl 10.211.55.6 3306
 			
 			 echo $? 检测是否正确 0 同步成功 1 失败
 		
 			
 * mha ip failover检测脚本  

 			/usr/local/mha/master_ip_failover
 			
 
 			 更改脚本vip 需要配合网卡测试			



配置文件与相关脚本
=================

```

    config 目录下
        
        keepalived_master    ---> keepalied master配置文件 
        keepalived_back      ---> keepalive back 配置文件
        master_ip_failover   ---> mha vip 切换脚本
        check_slave.pl       ---> keepalived 自定义检测脚本
        app1.cnf             ---> mha配置文件
        
    
```

相关下载
=================

>http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
  
> https://storage.googleapis.com/google-code-archive-downloads/v2/code.google.com/mysql-master-ha/mha4mysql-node-0.53.tar.gz
  
 > https://storage.googleapis.com/google-code-archive-downloads/v2/code.google.com/mysql-master-ha/mha4mysql-manager-0.53.tar.gz
  
> http://www.keepalived.org/software/keepalived-1.2.24.tar.gz

  
	

