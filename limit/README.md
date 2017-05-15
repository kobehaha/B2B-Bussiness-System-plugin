nginx(openresty)+lua服务限流
===============


动态负载均衡
===============


    > 1 consul 分布式服务注册与发现
    
    
        
        a 服务注册
        
        b 服务发现
        
        c 故障检测
        
        d k/v存储
        
        e 多数据中心
        
        f raft 算法
        
        
        
      
       
概要
===============

本服务使用logstash ---> elasticsearch ----> kibana 

我想的使用方式是在业务高峰期对不重要的log进行选择性限流


--> 比如同时存在nginx和tomcat的access.log只保存nginx access.log
--> 
    
