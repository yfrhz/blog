---
title: "博弈论-第一篇"
date: 2024-05-17T13:12:15+08:00
draft: false
---

### 问题

1. 如何找到多方中的最优解（最大化利益）
2. 如何促成一次合作
3. 如何在合作中约束各方不作弊

### 囚徒困境与纳什均衡

我们先来看一个小故事

```text
警察抓住了两名惯盗，张三和李四。 
但狡猾的惯盗并没有留下过多证据，如果两人都辩称没有参与其他盗窃案，则由于证据不住而只能定义为普通盗窃，各判处三年有期徒刑。
在陷入困难之际，检察官想到了一个办法。
检察官先来到张三的羁押房，表示如果李四认罪，而他不认罪，在并案数罚的情况下李四自首能获得减刑，只判五年，而他由于拒不招供，则会判处十年徒刑。
这样一来，如果他相信李四会认罪，最好他自己也认罪，判五年总比判十年来得好。
检查官又表示，如果他能认罪，并作为污点证人指控李四，由于是大案，那么会将他的刑期减为一年。
这样似乎对张三最好的做法就是认罪。
可是回头，检察官又对李四说了同样的话。
最终，他们都被判了四年。
```

这便是囚徒困境。两人都认为选择了能使自己更受益策略而获得双败结果。
让我们来用图表展示这个关系

|       | 李四认罪 | 李四不认罪 |
|-------|------|-------|
| 张三认罪  | 5,5  | 1,10  | 
| 张三不认罪 | 10,1 | 3,3   | 

从图中可以看出，不论对方是否认罪，自己选择认罪的收益更高。
而双方都认罪的选择，称为达到了博弈的**纳什均衡**

在博弈论中，纳什均衡是这么定义的

```
在各方面都选择了同一种策略的情况下，没有一方能通过独自改变策略而获益。此时的策略搭配和后续的结果，就被成为纳什均衡。
```

### 合作与竞争

上面的小故事只是简单的介绍了囚徒困境与纳什均衡，通常只要双方好好沟通，互相妥协，就能好好收场。\
但不幸的是，往往达成协议后会有一方反悔，究其原因是，如果合作达成的方案并非纳什均衡，当其中一方改变想法时，的确就能获得对其自身更好的结果。\

一般而言，达成合作有两大挑战

1. 找到方式达成协议
2. 找到方式让每个参与放都不改变主意

能解决这两个挑战的主要方式有三种

1. 群体性共识
   如果大家都认为合作中作弊是不道德的，并且这个思想像饿了要吃饭一样基础，就能避免许多社会困境。
2. 权威公平第三方
   由外部的专业第三方来促成合作并约束各方守护公平。
3. 自运行的机制
   各方依赖详尽的策略规约，自动将合作状态调整为纳什均衡。

下面会一一审视这三种方法

#### 群体性共识

依稀记得，福建省有个案件，张三欠李四的钱不还，欠条被损毁了，法庭见调解无效，让张三对妈祖发誓没有欠钱。结果张三当庭承认了欠款，并在妈祖的见证下并重新约定了还款时间。\
可能这也算是**权威公平第三方吧**\
群体性共识的前提，就是共识群体性，当合作方并不在共识范围内，那么并不能不能保证共识还能生效，西方的神就管不了东方的天。

#### 权威公平第三方

旅游旺季的时候看到新闻，某酒店因为节假日房价上涨，于是要求在节前在第三方平台上预购的游客，要么这退房，要么补差价。\
而游客没有办法只能向平台投诉。而平台处理结果也不尽人意。最终由于高峰期一房难求，导致游客补了差价。\
所以对于**权威公平第三方**而言，需要其本身有强大权威，公平与约束力，否则并不能有效约束参与方进行策略切换，而损害其他参与方的利益。

#### 自运行的机制

将纳什均衡作为一种能够自动运行的机制，让合作期间没有作弊的动机。由于处于纳什均衡下，任意一方改变策略并没有任何好处。合作方放就没有必要进行任何改动。\
但是如果需要合作的情景不属于纳什均衡，任意一方都可能想小小的改变一下，打破协议，获取更多的好处。


文章主要是详解第三种方法（当然是第三种了，文章名都叫博弈论了，不会指望在这里能看到社会学和法学的东西吧）

### 公平分配

#### 大中取小
先衡量局势，考虑各种不同的选择造成的最大损失或最坏结果是什么，再决定如何让损失最小。追求最佳的可行性，而不是最佳的可能性。

#### 我切你选
一个简单的公平策略就是 **我切你选** 举个简单的例子
```text
兄弟两人要分一块蛋糕，他们猜拳后决定由哥哥先切，弟弟来选。
哥哥为了让自己获得更多的蛋糕，而会尽可能和将蛋糕分成两份自己都可以接受的大小，这样弟弟无论选择哪一份，哥哥获得另一份都是可以接受的。
而弟弟则会在哥哥切好的两份中选择一份更好的。将自己认为不好的给哥哥。
这样双方都觉得公平，而不需要依赖不吃蛋糕的父母来进行分配。
```
不过在这个例子中有个忽略的细节，假设哥哥更喜欢吃奶油，弟弟更喜欢吃面包，那又需要如何分配才能保证哥哥和弟弟的利益最大化呢？