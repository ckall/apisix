# 九州 API Gateway


这里主要记录一些注意事项

    如果开启jiuzhou-rbac，需要配置jiuzhou-rbac的地址，需要在header里面加这两个来使用
        X-JiuZhou-Service
        X-Jiuzhou-Authorization:
    有些服务想找日志, 目前日志存放在阿里云的sls里面, 但是我们还支持了其他的日志功能匹配日志http,kafka,rocketmq等...传输日志
    具体的格式可以参考 jiuzhou-log[https://apisix.apache.org/docs/apisix/apisix-variable/] 和nginx的 https://nginx.org/en/docs/varindex.html
    我们都是支持的, 但是有些特殊的值比如token解析是$auth_data这里模糊记录下
    , 后期打算开发一个新的日志服务, 再把权限里面的api路径结合起来让业务自己查
