# tengine-rpm

生成 tengine 的安装包, spec 文件从 nginx rpm 源文件获取并修改

Use:
```
$ cd /tmp
$ git clone https://github.com/wojiushixiaobai/tengine-rpm.git
$ cd tngine-rpm
# 自行编辑 build_tengine.sh 和 tengine.spec
$ sh build_tengine.sh
```

Install:
```
yum localinstall tengine-2.3.2-1.el7.ngx.x86_64.rpm
```

Uninstall
```
yum remove tengine
```

Start
```
systemctl start nginx
```

Stop
```
systemctl stop nginx
```

Restart
```
systemctl restart nginx
```

项目参考了 [Axizdkr](https://github.com/Axizdkr/tengine/blob/master/Dockerfile) configure

spec 为直接修改 [Nginx](http://nginx.org/) 源 rpm 包
