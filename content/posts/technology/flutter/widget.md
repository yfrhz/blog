---
title: "Widget记录"
date: 2023-07-23T22:20:15+08:00
draft: false
---

### 简介

用于记录一些乱七八糟的Widget（速查表）

### 布局

#### Expanded

可以设置元素的占用空间比例大小。

```dart
const Expanded({
    Key key,
    int flex = 1,
    @required Widget child,
})
```
- flex 占比大小，默认是100%
  - 多个Expanded并列时，单个Expanded占用空间为flex/sum(flex)
- child 即需要分配的Widget

例子:[参考博客](https://juejin.cn/post/7245106927512322109)
    
