---
title: "Hugo页面样式加载失败"
date: 2023-07-20T16:12:34+08:00
draft: false
---

### 现象
在本地运行测试好好的，发布到托管环境格式就乱了。

### 检查
打开控制台后，发现console下有一条报错：
![](/img/hugo/integrity_error.png)

说css的校验失效，导致资源被锁定。所以格式全部都乱了。

### 原因
由于Linux使用的是LF作为换行符，Windows使用CRLF作为换行符号。所以在跨环境时，换行符会发生变化。\
而由于hugo是每次都会重新生成css，导致跨环境之后的校验失效。

### 解决方案
1. 不跨环境（这不是废话）
2. 找到校验的代码，我的是在这里，themes/PaperMod/layouts/partials/head.html\
当然，不同的主题可能位置不一样，但是结构应该和下面类似：
![](/img/hugo/head_config.png)
找到后有两个方法：
   1. 可以直接将74行的代码复制到第72行（也就是去掉了integrity校验）
   2. 也可以基于70行的判断，在项目配置文件中添加 <b> params.assets.disableFingerprinting: true </b> 来跳过校验


