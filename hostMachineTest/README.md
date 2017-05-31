宿主机性能测试 实践
=================

宿主机性能测试实践


目录
=================

* [概要](#宿主机性能测试 实践)
* [详情](#详情)
	* [cpu性能测试工具与方法](#cpu性能测试工具与方法)
	* [网络I/O测试工具与测试方法](#网络I/O测试工具与测试方法)
	* [故障切换介绍](#故障切换介绍)
		* [master停止服务](#master停止服务)
		* [slave停止服务](#master停止服务)
		* [keepalived停止服务](#keepalived停止服务)
	* [关键步骤](#关键步骤)
	* [配置文件与相关脚本](#配置文件与相关脚本)
	* [相关下载](#相关下载)
	* [思考](#思考)


cpu性能测试工具与方法
=================

* cpu测试工具与测试方法

	1 superIPa 和UnixBench
	
	1 UnixBench
	
	


	

网络I/O测试工具与测试方法
=================


* 网络瓶颈
* 网络稳定性


网络测试用例
	
	> tcp 吞吐量测试
	> tcp 连接数测试
	> tcp 单链接多交易测试
	> tcp 发包率测试
	> tcp 吞吐测试
	> UDP 单连接多交易测试
	> UDP 发包率测试
	> 业务模型网络模拟测试
	

 测试工具
 
 	Netperf是一款网络性能的测试工具,主要正对TCP和UDP的传输。Netperf 根据应用的不同，可以进行不同模式的网络测试性能,及批量数据传输模式和请求/应答模式。
 	Netperf可以反映一个系统能以多块的速度向拧一个系统发送数据和另一个系统能以多块的速度多收数据	

	
http://blog.itpub.net/22664653/viewspace-714569/




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


思考
=================

```
   1 个人认为mha+keepalived是一个分非常好的mysql 集群处理方案,keepalived不用考虑脑裂的问题,因为只涉及到读取数据库,当slave 切换为Master的时候也不用考虑，因为slave变为master会把他剔除代理列表
  读库的vip教给perl脚本来做可控性增强，我们可以自定义的处理


   2 mha 代码都是开源的非常时候在上面二次开发，完善或则做自动化运维相关的事情,不过最开始对perl的不熟悉也有很多坑

   3 建议如果在生产环境下使用先进行各种各样的压测,如果符合公司条件,可以考虑

   4 建议在mha或则keepalived 完善一些脚本，比如心跳时间，网络波动的检测，发送邮件

   5 该方案适当的解决了读写分离,不过如果涉及到分库分表,还是考虑用其他的方案，个人比较倾向当当网的sharding  其他也有mycat cobar atals 要么维护成本过高，要么坑很多，我这里不是特别建议  

```
相关下载
=================

>http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm

> https://storage.googleapis.com/google-code-archive-downloads/v2/code.google.com/mysql-master-ha/mha4mysql-node-0.53.tar.gz

 > https://storage.googleapis.com/google-code-archive-downloads/v2/code.google.com/mysql-master-ha/mha4mysql-manager-0.53.tar.gz

> http://www.keepalived.org/software/keepalived-1.2.24.tar.gz
