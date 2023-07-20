---
title: "安装hugo"
date: 2023-07-12T16:12:34+08:00
draft: false
---


### 前言
一直想自己搭建个博客做记录，偶然间了解到静态站。

由于会Vue3，最开始打算使用vue-press的，但是调查发现，有三个主流的静态博客工具。也有现成的静态托管方案。

于是乎，在对比了jekyll、hugo、hexo后，果断的选择了hugo（反正都没用过，就选星星最多的）。

遂，域名，空间，博客一把梭。

记录下 Hogu 的安装过程

### 安装
当然是看 [官方安装文档](https://www.gohugo.org/doc/overview/installing/) 啊，不然真的看博客啊。

### 配置
配置就有得说了，官网的东西有点乱。

### 问题
部署后出现缺失样式，F12控制台出现如下提示
```
Failed to find a valid digest in the 'integrity' attribute for resource 'xx' with computed SHA-256 integrity 'xxx'. The resource has been blocked.
```
因为win和mac的结尾符号不同CRLF和LF，导致hash后css校验失败\
需要在项目中添加 .gitattributes 文件，添加内容：
```
text=auto eol=lf
```
然后将这个修改commit一下。\
使用如下命令转换项目中已经存在的CRLF：
```
git rm --cached -r .  # Remove every file from git's index.
git reset --hard      # Rewrite git's index to pick up all the new line endings.
```
这样就好啦~
