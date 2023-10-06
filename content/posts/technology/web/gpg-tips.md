---
title: "gpg小纪"
date: 2023-10-06T10:24:36+08:00
draft: false
---

## 从公钥服务器接收失败
命令：
```shell
 apt-key adv --keyserver keyserver.ubuntu.com --recv xxxx
```
错误提示：\
gpg: keyserver receive failed: Server indicated a failure\
gpg: 从公钥服务器接收失败：Server indicated a failure\
解决方案
1. 由于```keyserver.ubuntu.com```开放80端口，需要手动指定，否则会使用默认端口11371 \
   添加协议名和端口后为：
   ```shell
     apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv xxxx
   ```
2. 如果方案1中继续报错，可能是由于域名解析失败导致，可以在```/etc/resolv.conf```中修改dns配置为
   ```shell
     nameserver 8.8.8.8 # Google DNS
   ```
   或
   ```shell
     nameserver 1.1.1.1 # Cloudflare
   ```
3. 如果不可修改DNS或者修改后依旧失败，则可以使用```ping```来获取```keyserver.ubuntu.com```的真实IP，再替换到域名
   ```shell
     ping keyserver.ubuntu.com #获取ip，我获取的是 185.125.188.27
     apt-key adv --keyserver hkp://185.125.188.27:80 --recv xxxx #使用IP替换域名
   ```
