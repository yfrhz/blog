---
title: "{{ replace .TranslationBaseName "-" " " | title }}"
slug: ""  # 配合 config.toml 中的 permalinks 参数，自定义文章链接
description: ""  # 显示在文章标题下，与 summary 不同
summary: ""  # 文章摘要
date: {{ .Date }}
lastmod: {{ .Date }}
draft: false
showToc: true
weight: false  # 用来指定文章，weight: num
categories: [""]
tags: [""]
---

