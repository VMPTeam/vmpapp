# vmp设计文档

项目使用AngularJS框架开发,代码编写使用coffee代替js,使用less代替css.相关文档如下:

* [AngularJS](https://www.angularjs.org/)
* [coffee-script](http://coffeescript.org/)
* [less](http://lesscss.org/)

后面不再叙述三种工具的具体用法,请查看相关网站或手册.

## 目录结构

项目由ionic-cli构建,主要分为以下目录

* `hooks` - ionic挂载目录,可在不同阶段执行钩子函数
* `node_modules` - npm依赖库目录
* `platforms` - 移动端系统平台目录
* `plugins` - 插件包
* `resources` - 静态资源目录
* `scss` - scss文件存放目录
* `www` - Web目录  
  + `css` - 样式目录
    - `icon.css` - 图标样式
    - `style.css` - 主样式
  + `img` - 图片目录
  + `js` - 脚本目录
    - `app.js` - 主入口文件.
    - `controllers.js` - 控制器
    - `service.js` - 接口服务
    - `directives.js` - 指令
    - `filters.js` - 过滤器
  + `lib` - 第三方库目录
  + `templates` - 模板目录
  + `index.html` - 主入口文件

## app.js说明

app.js为主入口文件,在程序启动时载入.程序启动时,主要处理以下内容:

1. 定义Angular模块,常量,接口请求拦截器并加载主模块
2. 定义路由状态映射表.(路由系统使用[ui-router](https://github.com/angular-ui/ui-router))
3. 配置cordova相关属性

## controller.js 说明

程序所有的控制器定义都在controllers.js中,控制器与模板对应关系在路由映射表中可以查询.控制器定义规则:

1. 每个tab页都有单独的控制器
2. 复杂的页面生成一个单独控制器
3. 简单的页面与其他页面共用一个控制器

## services.js 说明

接口服务封装成对应的模块.主要有:

* Account 帐号相关接口
* Car 车辆相关接口
* Driver 驾驶员相关接口
* People 乘车人相关接口
* Order 订单相关接口
* Area 栅栏区域相关接口
* Message  消息相关接口
* Statistic 统计数据相关接口
* Map 百度地图相关接口

##directives.js 说明

定义了以下两个指令:

* <vmp-tabs\>
  该指令封装了底部tab栏实现

* <baidu-map\>
  该指令封装了驾驶员端选择地址的实现

##filters.js 说明

定义了一个过滤器:

* concatName
  用于拼接乘车人名称列表