---
title: "gpg小记"
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
## 签名失败
### 提示信息
```shell
gpg: 签名时失败： Inappropriate ioctl for device
gpg: signing failed: Inappropriate ioctl for device
```
### 原因：
gpg在签名时需要使用终端，但是当前终端没有输入输出，所以会报错。
### 解决方案：
```shell
# 临时
export GPG_TTY=$(tty) 
# 永久
echo "export GPG_TTY=$(tty)" >> ~/.bashrc
source ~/.bashrc
```

## 修改密钥过期时间
```shell

# 1. 获取密钥ID
gpg --list-secret-keys --keyid-format=long
# 2.  修改密钥
gpg --edit-key [密钥ID]
# 3. 修改密钥过期时间
expire
#  4. 保存
save 

```

## 其他命令
```shell
# 生成 gpg 密钥
gpg --gen-key

# 生成吊销证书
gpg --gen-revoke [密钥ID]

# 列出所有 gpg 公钥
gpg --list-keys

# 列出所有 gpg 私钥
gpg --list-secret-keys

# 删除 gpg 公钥
gpg --delete-keys [密钥ID]

# 删除 gpg 私钥
gpg --delete-secret-keys [密钥ID]

# 输出 gpg 公钥 ascii
gpg --armor --output public.key --export [密钥ID]

# 输出 gpg 私钥 ascii
gpg --armor --output private.key --export-secret-keys [密钥ID]

# 上传 gpg 公钥
gpg --send-keys [密钥ID] --keyserver 

# 查看 gpg 公钥指纹
gpg --fingerprint [密钥ID]

# 导入 gpg 密钥(导入私钥时会自动导入公钥)
gpg --import private.key

# 加密文件
gpg --recipient [密钥ID] --output encrypt.file --encrypt origin.file

# 解密文件
gpg --output origin.file --decrypt encrypt.file

# 文件签名，生成二进制的 gpg 文件
gpg --sign file.txt

# 文件签名，生成文本末尾追加 ASCII 签名的 asc 文件
gpg --clearsign file.txt

# 文件签名，生成二进制的 sig 文件
gpg --detach-sign file.txt

# 文件签名，生成 ASCII 格式的 asc 文件
gpg --detach-sign file.txt

# 签名并加密
gpg --local-user [密钥ID] --recipient [密钥ID] --armor --sign --encrypt file.txt

# 验证签名
gpg --verify file.txt.asc file.txt

```

