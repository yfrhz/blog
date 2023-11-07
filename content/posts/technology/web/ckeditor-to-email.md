---
title: "使用ckeditor发送邮件"
date: 2023-08-04T10:50:34+08:00
draft: false
---
## 背景
有个需求，要给客户批量发邮件。需要包含复杂表格，不能用excel，需要直接展示。\
最开始采用了WangEdit,简单快捷，但是表格功能不强，只能增减格子，于是又各种查，找到了ckeditor。
鉴于在实现过程中发现了很多坑，在此记录一下。\
多年老坑:\
[Possible to make editor.getData() returns content with inline styles?](https://github.com/ckeditor/ckeditor5/issues/1627)

## 环境
- 前端脚手架: umi
- node: V18

## 安装CkEditor

