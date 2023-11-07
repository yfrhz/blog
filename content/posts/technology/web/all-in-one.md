---
title: "整合前端（umi）到后端（spring-boot）中"
date: 2023-08-04T10:50:34+08:00
draft: false
---

## 背景
toB业务，最终交付的是一个客户端，需要提供前端控制页面，需要将前端也进行编译打包到同一个zip中，并且需要兼容jenkins，一步打包到位。

## 原理
由于使用umi开发前端，所以正式使用之前先得进行编译。需要使用maven触发编译，打包为zip需要使用assembly插件\
再将js文件打包进行项目目录，由于是直接使用，没有nginx的容器， 需要spring-web充当容器，对前端资源进行转发。同时，spring-web也提供后端接口。

## 实现
原理可行，开始实现

### 目录结构
项目目录结构基于Maven项目，前端文件放哪都行，只要后面路径配置得一直就没啥问题。\
主要目录结构如下：
- bin
  - ...启动脚本
- config
  - ...配置
- assembly
  - assembly.xml
- react(前端代码)
- src
  - main
    - ...其他文件
  - resources
    - public
    - ...其他文件
- target
- pom.xml

### 配置
#### 1. 修改umi配置输出目录 
修改配置文件```.umirc.ts```，
添加配置项 ```outputPath: '../src/main/resources/public/'```
```ts
// .umirc.ts
export default defineConfig({
    // 其他配置
    outputPath: '../src/main/resources/public/',
});
```
#### 2. 修改maven配置文件
- 添加react编译插件，用于编译umi项目
```xml
<plugin>
    <groupId>com.github.eirslett</groupId>
    <artifactId>frontend-maven-plugin</artifactId>
    <version>1.14.0</version>
    <configuration>
        <nodeDownloadRoot>https://npm.taobao.org/mirrors/node/</nodeDownloadRoot>
        <npmDownloadRoot>https://registry.npm.taobao.org/npm/-/</npmDownloadRoot>
        <installDirectory>react</installDirectory>
        <workingDirectory>react</workingDirectory>
        <nodeVersion>v16.19.0</nodeVersion>
        <yarnVersion>v1.22.10</yarnVersion>
    </configuration>
    <executions>
        <!-- 构建时自动安装 node 和 yarn -->
        <execution>
            <id>install node and yarn</id>
            <goals>
                <goal>install-node-and-yarn</goal>
            </goals>
        </execution>
        <!-- 构建时执行 yarn install -->
        <execution>
            <id>yarn install</id>
            <goals>
                <goal>yarn</goal>
            </goals>
            <phase>generate-resources</phase>
            <configuration>
                <arguments>install</arguments>
            </configuration>
        </execution>
        <!-- 构建时执行 yarn build -->
        <execution>
            <id>yarn build</id>
            <goals>
                <goal>yarn</goal>
            </goals>
            <configuration>
                <arguments>build</arguments>
            </configuration>
        </execution>
    </executions>
</plugin>
```
- 添加assembly打包插件,并且指明assembly脚本路径
```xml
<plugin>
    <groupId>org.apache.maven.plugins</groupId>
    <artifactId>maven-assembly-plugin</artifactId>
    <executions>
        <execution>
            <id>make-assembly</id>
            <phase>package</phase>
            <goals>
                <goal>single</goal>
            </goals>
            <configuration>
                <skipAssembly>${skipAssembly}</skipAssembly>
                <descriptors>
                    <descriptor>assembly/assembly.xml</descriptor>
                </descriptors>
            </configuration>
        </execution>
    </executions>
    <configuration>
        <appendAssemblyId>false</appendAssemblyId>
    </configuration>
</plugin>
```

#### 3. 编写assembly脚本
```xml
<assembly
	xmlns="http://maven.apache.org/ASSEMBLY/2.1.0"
	xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
	xsi:schemaLocation="http://maven.apache.org/ASSEMBLY/2.1.0
	http://maven.apache.org/xsd/assembly-2.1.0.xsd">
    
	<id>assembly</id>
	<!-- 最终打包成一个用于发布的zip文件 -->
	<formats>
		<format>zip</format>
	</formats>
    
	<!-- 添加maven的lib依赖 -->
	<dependencySets>
		<dependencySet>
			<outputDirectory>lib</outputDirectory>
			<scope>runtime</scope>
		</dependencySet>
	</dependencySets>
    
	<fileSets>
		<!-- 把项目的本地lib依赖 ，打包进zip文件的lib -->
		<fileSet>
			<directory>${project.basedir}/lib</directory>
			<outputDirectory>lib</outputDirectory>
			<includes>
				<include>*</include>
			</includes>
		</fileSet>

		<!-- 把项目的脚本文件目录配置 ，打包进zip文件的conf -->
		<fileSet>
			<directory>${project.basedir}/config</directory>
			<outputDirectory>config</outputDirectory>
			<includes>
				<include>*.*</include>
			</includes>
		</fileSet>

		<!--添加前端-->
		<fileSet>
			<directory>${basedir}/src/main/resources/public</directory>
			<outputDirectory>public</outputDirectory>
			<includes>
				<include>**/*</include>
			</includes>
		</fileSet>

		<!-- 把项目的脚本文件目录中的启动脚本文件，打包进zip文件的跟目录 -->
		<fileSet>
			<directory>${project.basedir}/bin</directory>
			<outputDirectory>bin</outputDirectory>
			<includes>
				<include>*.bat</include>
			</includes>
		</fileSet>

		<fileSet>
			<directory>${project.basedir}/bin</directory>
			<outputDirectory>bin</outputDirectory>
			<directoryMode>0777</directoryMode>
			<fileMode>0777</fileMode>
			<lineEnding>unix</lineEnding>
			<includes>
				<include>*.sh</include>
			</includes>
		</fileSet>
	</fileSets>
</assembly> 
```

### 打包
执行```mvn clean package -Dmaven.test.skip=true```进行打包
![](/img/fontend/package.png)

然后等待片刻，打包完成\
打包后的压缩包
![](/img/fontend/package.png)
编译后的前端
![](/img/fontend/package.png)

