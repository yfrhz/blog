---
title: "Drift使用说明"
date: 2023-07-19T23:40:15+08:00
draft: false
categories: ['flutter']
---
### 简介
作为Flutter的半orm框架，Drift确实达到了好用的程度。本文不去对比其他框架，仅就使用过程中的一些坑或者技巧做一点小小的记录。

### 相关文档
最权威的当然是各种官网的文档，建议优先参考，本文不赘述安装、导入过程。
 - [官方文档](https://drift.simonbinder.eu/)
 - [GitHub](https://github.com/simolus3/drift)
 - [Pub](https://pub.dev/packages/drift)

### 使用
参考文档，先这样，然后这样，再那样，就好啦～

```shell
# 注意：由于Dart不支持反射等操作，导致dao及相关类不能自动生成，需要手动执行以下指令进行生成。
$ dart run build_runner build
```

### 问题
1. Tables can't override primaryKey and use autoIncrement() \
   设置自增就默认为主键，不用再额外指定主键了，但是指定了也只是警告，问题不大。
2. 数据文件路径（安卓虚拟机）\
   /data/user/0/{包名}/app_flutter/db.sqlite


