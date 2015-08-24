###
入口模块定义
###
angular.module 'starter', [
  'ionic'
  'ngCordova'
  'starter.controllers'
  'starter.services'
  'starter.directives'
  'starter.filters'
  'angular-md5'
  'mobiscroll-datetime'
  'ngStorage'
]
# 接口baseUrl
# .constant 'BASE_URL', '/Business'
.constant 'BASE_URL', 'http://vmp.witgo.cn/Business'
#机构信息
.constant 'KEY_COMPANY', 'VMP_COMPANY'
#Token信息
.constant 'KEY_TOKEN', 'VMP_TOKEN'
#帐号信息
.constant 'KEY_ACCOUNT', 'VMP_ACCOUNT'
#用户名
.constant 'KEY_USERNAME', 'VMP_USERNAME'
#密码
.constant 'KEY_PASSWORD', 'VMP_PASSWORD'

#starter模块初始化函数
.run (
  $rootScope
  $ionicPlatform
  $ionicScrollDelegate
  $location
  $localStorage
  $interval
  $timeout
  $cordovaAppVersion
  $cordovaFileTransfer
  $cordovaFileOpener2
  $ionicPopup
  $ionicLoading
  KEY_COMPANY
  KEY_TOKEN
  Account
  Message
  ) ->

  ###
  js异常捕获
  ###
  window.onerror = (err) ->
    console.log err

  ###
  定时器
  ###
  $rootScope.fnOpenTimer = () ->
    $rootScope.timer = $interval () ->
      # 获取未读消息数量
      Message.count()
      .then (res) ->
        # 处理未读消息
        count = parseInt(res['1']) + parseInt(res['2']) + parseInt(res['3'])
        $rootScope.unreadMsg =  if count < 100 then count else '...'
        return
    , 30000
    return

  # 读取缓存
  oToken = $localStorage[KEY_TOKEN]
  companyCode = $localStorage[KEY_COMPANY]
  #判断是否设置企业号
  if !companyCode
    #进入企业设置页面
    $location.path('/company')
  # 是否已登录
  else if(!oToken || !oToken.access_token)
    #进入登录页面
    $location.path('/login')
  else
    #用户权限判断跳转页面
    if Account.permission 'vehicle_manager'
      $rootScope.fnOpenTimer()
      # if $localStorage['newHome']
      #   $location.path '/newHome'
      # else  
      #   $location.path '/allots'
      $location.path '/newHome'
    else if Account.permission 'driver'
      $rootScope.fnOpenTimer()
      $location.path '/mission'
    else
      $location.path '/userhome'
  # 获取GPS信息
  Account.getLocation()
  
  # ionic监听事件
  $ionicPlatform.ready () ->
    if window.cordova and
       window.cordova.plugins and
       window.cordova.plugins.Keyboard
      # keyboard配置
      cordova.plugins.Keyboard.hideKeyboardAccessoryBar(true)
      cordova.plugins.Keyboard.disableScroll(false)
    if (window.StatusBar)
      # statusBar配置
      StatusBar.styleLightContent()
    # fullScreen配置
    ionic.Platform.isFullScreen = true;

  # handle hardware backbutton
  document.addEventListener 'backbutton', (e)->
    if $location.path() is '/newHome' or
       $location.path() is '/login' or
       $location.path() is '/company' 
      e.preventDefault()
      navigator.app.exitApp()

  # 滚动功能切换
  $rootScope.$on '$stateChangeStart', (e, state) ->
    if state.name is 'car'
      $ionicScrollDelegate.freezeAllScrolls true
    else
      $ionicScrollDelegate.freezeAllScrolls false
    return

  $rootScope.$on 'message.open', ->
    console.log 'message.open'
    # 开启定时器
    $rootScope.fnOpenTimer()
    return
     
  $rootScope.$on 'message.close', ->
    console.log 'message.close'
    # 关闭定时器
    $interval.cancel $rootScope.timer

  ###
  安卓升级提示
  ###
  showUpdateConfirm = (app = {})->
    # 弹出提示框
    confirmPopup = $ionicPopup.confirm(
      title: '版本升级'
      template: app.content or "发现新版本(#{app.version})"
      cancelText: '取消',
      okText: '升级'
    )
    .then (res)->
      if res is true
        # 设置存放路径
        file = "file:///storage/sdcard0/Download/vmp-app_#{Date.now()}.apk"
        # 下载apk
        $cordovaFileTransfer.download app.downloadUrl, file, {}, true
        .then ()->
          # 打开下载完成的apk
          console.log 'download success'
          $cordovaFileOpener2.open file, 'application/vnd.android.package-archive'
          .then ->
            console.log 'open success'
          , ()->
            console.log 'open error'
          #关闭弹窗
          $ionicLoading.hide();
        , (err)->
          # 提示下载失败信息
          alert '下载失败' + JSON.stringify err
        , (progress)->
          $timeout ()->
            #显示下载进度
            downloadProgress = (progress.loaded / progress.total) * 100
            $ionicLoading.show
              template: "已经下载：" + Math.floor(downloadProgress) + "%"
            if (downloadProgress > 99)
              $ionicLoading.hide()

  ###
  检查更新
  ###
  checkUpdate = ()->
    Account.checkUpdate()
    .then (app) ->
      #获取当前APP版本
      $cordovaAppVersion.getAppVersion()
      .then (version)->
        # 比较版本
        if (version isnt app.version) 
          showUpdateConfirm app

  $timeout ()->  
    # 判断是否为Android系统  
    if ionic.Platform.isAndroid()
      checkUpdate()
  , 5000

  return
#路径拦截器
.factory 'pathInterceptor', (BASE_URL) ->
  interceptor =
    request: (config) ->
      # 正则表达式含义： 排除后缀为.html | 排除前缀为http: https:
      exp1 = !/.+(?=\.html$)/.test(config.url)
      exp2 = !/^(?=(http\:|https\:)).*/.test(config.url)
      if (exp1 && exp2)
        config.url = BASE_URL + config.url
        # 设置超时时间
        config.timeout = 15000
      return config
  return interceptor
# Token拦截器
.factory 'tokenInterceptor', ($q, $location, $localStorage, KEY_TOKEN) ->
  interceptor =
    request: (config) ->
      oToken = $localStorage[KEY_TOKEN]
      token_type = if oToken? then oToken.token_type else ''
      access_token = if oToken? then oToken.access_token else ''
      if oToken?
        # 添加Token
        config.headers['Authorization'] = token_type + access_token
      return config
    responseError: (rejection) ->
      switch rejection.status
        # Token失效拦截
        when 401
          delete $localStorage[KEY_TOKEN]
          $location.url '/login'
      return $q.reject rejection
  return interceptor

#日志拦截器
.factory 'logInterceptor', ($q, $log) ->
  interceptor =
    request: (config) ->
      #输出接口请求日志
      if !/.+(?=\.html$)/.test(config.url)
        $log.debug '开始请求接口.接口地址=' +
        config.url +
        '; 请求参数=' +
        angular.toJson config.data
      return config
    response: (response) ->
      #输出接口请求成功日志
      if !/.+(?=\.html$)/.test(response.config.url)
        $log.debug '接口请求成功.接口地址=' +
        response.config.url +
        '; 返回结果=' +
        angular.toJson response.data
      return response
    responseError: (rejection) ->
      #输出接口请求失败日志
      if !/.+(?=\.html$)/.test(rejection.config.url)
        $log.debug '接口请求失败.接口地址=' + rejection.config.url
      return $q.reject rejection
  return interceptor

# starter模块配置 
.config (
$stateProvider
$urlRouterProvider
$ionicConfigProvider
$httpProvider
) ->
  ###
  ionic通用配置
  ###
  # $ionicConfigProvider.views.maxCache(20)
  #设置过场动画
  $ionicConfigProvider.views.transition('none')

  # $ionicConfigProvider.views.forwardCache(true)
  #设置tab位置
  $ionicConfigProvider.tabs.position('bottom')
  #设置文本位置
  $ionicConfigProvider.navBar.alignTitle('center')
  #设置滑动返回
  $ionicConfigProvider.views.swipeBackEnabled(false);
  
  if ionic.Platform.isAndroid()
    #设置滚动效果
    $ionicConfigProvider.scrolling.jsScrolling false

  $stateProvider
  # 首页
  .state 'newHome',
    url: '/newHome'
    templateUrl: 'templates/newHome.html'
    controller: 'NewHomeCtrl'
    onEnter: ->
      # 路由进入事件
      document.addEventListener 'deviceready', ->
        if window.StatusBar
          window.StatusBar.overlaysWebView(false)
      , false
    onExit: ->
      # 路由离开事件
      document.addEventListener 'deviceready', ->
        if window.StatusBar
          window.StatusBar.overlaysWebView(true)
      , false

  # 管理员待分配列表tab
  .state 'allot',
    url: '/allots'
    templateUrl: 'templates/allot.html'
    controller: 'AllotCtrl'

  # 车辆管理tab
  .state 'car',
    url: '/car?{type}'
    templateUrl: 'templates/tab-car.html'
    controller: 'CarCtrl'

  # 统计分析报表tab
  .state 'report',
    url: '/reports'
    templateUrl: 'templates/tab-report.html'
    controller: 'ReportCtrl'

  # 统计分析报表详情
  .state 'reportDtail',
    url: '/report?type'
    templateUrl: 'templates/report-detail.html'
    controller: 'ReportCtrl'


  # 驾驶员管理
  .state 'driver',
    url: '/driverlist'
    templateUrl: 'templates/tab-driver.html'
    controller: 'DriverCtrl'

  # 驾驶员详情
  .state 'driverDetail',
    url: '/driverdetail/:id'
    templateUrl: 'templates/driver-detail.html'
    controller: 'DriverCtrl'

  # 帐号设置
  .state 'account',
    url: '/account'
    templateUrl: 'templates/account.html'
    controller: 'AccountCtrl'

  # 修改密码
  .state 'password',
    url: '/password'
    templateUrl: 'templates/setting-password.html'
    controller: 'AccountCtrl'

  # 提醒设置
  .state 'msg-list',
    url: '/setting/msgs'
    templateUrl: 'templates/setting-message.html'
    controller: 'AccountCtrl'

  # 消息中心
  .state 'messages',
    url: '/messages?type&messageUid'
    templateUrl: 'templates/msg-list.html'
    controller: 'AccountCtrl'

  # 消息详情
  .state 'messageDetail',
    url: '/message/:messageUid'
    templateUrl: 'templates/msg-detail.html'
    controller: 'AccountCtrl'

  # 登录页面
  .state 'login',
    url: '/login'
    templateUrl: 'templates/login.html'
    controller: 'AccountCtrl'

  # 机构设置
  .state 'company',
    url: '/company'
    templateUrl: 'templates/setting-company.html'
    controller: 'AccountCtrl'

  # 分配车辆订单详情
  .state 'allotDetail',
    url: '/allot/:id'
    templateUrl: 'templates/allot-detail.html'
    controller: 'AllotDetailCtrl'

  # 分配车辆
  .state 'cars',
    url: 'cars/:oid?startTime&endTime'
    templateUrl: 'templates/car-list.html'
    controller: 'AllotDetailCtrl'

  # 分配驾驶员
  .state 'drivers',
    url: 'drivers/:oid?startTime&endTime'
    templateUrl: 'templates/driver-list.html'
    controller: 'AllotDetailCtrl'

  # 车辆跟踪
  .state 'carInfo',
    url: '/carinfo/:id?type'
    templateUrl: 'templates/car-info.html'
    controller: 'CarInfoCtrl'

  # 电子栅栏列表
  .state 'areaList',
    url: '/areas'
    templateUrl: 'templates/area-list.html'
    controller: 'AreaCtrl'

  # 添加栅栏
  .state 'area',
    url: '/area'
    templateUrl: 'templates/area-form.html'
    controller: 'AreaCtrl'

  .state 'areaDetail',
    url: '/areadetail/:id'
    templateUrl: 'templates/area-form.html'
    controller: 'AreaCtrl'

  # 修改栅栏
  .state 'areaEdit',
    url: '/area/:id'
    templateUrl: 'templates/area-form.html'
    controller: 'AreaCtrl'

  # 栅栏地图
  .state 'areaMap',
    url: '/areamap?id&read'
    templateUrl: 'templates/area-map.html'
    controller: 'AreaCtrl'

  # 栅栏选车
  .state 'areaCar',
    url: '/areacar'
    templateUrl: 'templates/area-carlist.html'
    controller: 'AreaCtrl'

  # ----------------
  # 驾驶员
  # ----------------
  # 任务
  .state 'mission',
    url: '/mission'
    templateUrl: 'templates/mission.html'
    controller: 'MissionCtrl'

  # 我的任务-税费管理
  .state 'tax',
    url: '/tax/:taxId'
    templateUrl: 'templates/tax-list.html'
    controller: 'MissionCtrl'

  # 我的任务-税费管理
  .state 'addTax',
    url: '/tax/:taxId/add'
    templateUrl: 'templates/tax.html'
    controller: 'MissionCtrl'

  .state 'editTax',
    url: '/tax/:taxId/edit/:costId'
    templateUrl: 'templates/tax.html'
    controller: 'MissionCtrl'

  # 我的任务-事故报警
  .state 'alarm',
    url: '/alarm'
    templateUrl: 'templates/alarm.html'
    controller: 'MissionCtrl'


  # 订单列表
  .state 'driverOrders',
    url: '/driverorders'
    templateUrl: 'templates/driver-orders.html'
    controller: 'Driver.OrderCtrl'

  # 订单详情
  .state 'driverOrderDetail',
    url: '/driverorder/:id'
    templateUrl: 'templates/driver-order-detail.html'
    controller: 'Driver.OrderCtrl'

  # 用户首页
  .state 'userHome',
    url: '/userhome?from&lat&lng&address',
    templateUrl: 'templates/user-home.html',
    controller: 'User.HomeCtrl'

  # 选点地图
  .state 'map',
    url: '/map?from',
    templateUrl: 'templates/baidu-map.html',
    controller: 'User.HomeCtrl'

  # 选车页面
  .state 'userCars',
    url: '/usercars',
    templateUrl: 'templates/user-car-list.html',
    controller: 'User.CarCtrl'

  # 选人页面
  .state 'userPeoples',
    url: '/userPeoples',
    templateUrl: 'templates/people-list.html',
    controller: 'User.PeopleCtrl'

  # 用户订单列表
  .state 'userOrders',
    url: '/userorders',
    templateUrl: 'templates/user-orders.html',
    controller: 'User.OrderCtrl'

  # 用户订单详情
  .state 'userOrderDetail',
    url: '/userorder/:id',
    templateUrl: 'templates/user-order-detail.html',
    controller: 'User.OrderDetailCtrl'

  # 企业信息
  .state 'organization-info',
    url: '/organization/info',
    templateUrl: 'templates/organization-info.html',
    controller: 'AccountCtrl'

  # 默认路由
  $urlRouterProvider.otherwise '/'
  # 添加拦截器
  $httpProvider.interceptors.push 'pathInterceptor'
  $httpProvider.interceptors.push 'tokenInterceptor'
  $httpProvider.interceptors.push 'logInterceptor'
  # 参数转换
  fnTransParam = (data, headersGetter) ->
    ct = headersGetter()['Content-Type']
    if (ct and ct.match('application/x-www-form-urlencoded'))
      if angular.isObject(data) && String(data) isnt '[object File]'
        return $.param data
      else
        return data
    else
      return angular.toJson data
  # 采用表单提交方式
  # http请求Content-type = application/json 改为 application/x-www-form-urlencoded
  #  $httpProvider.defaults.headers.post =
  #    'Content-Type': 'application/x-www-form-urlencoded'
  #  $httpProvider.defaults.transformRequest.unshift(fnTransParam)
  return
