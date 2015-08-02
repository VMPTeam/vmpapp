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

# .constant 'BASE_URL', '/Business'
.constant 'BASE_URL', 'http://220.178.67.250:8080/Business'
.constant 'CLIENT_TYPE', 'vehicle_manager'
.constant 'KEY_COMPANY', 'VMP_COMPANY'
.constant 'KEY_TOKEN', 'VMP_TOKEN'
.constant 'KEY_ACCOUNT', 'VMP_ACCOUNT'
.constant 'KEY_USERNAME', 'VMP_USERNAME'
.constant 'KEY_PASSWORD', 'VMP_PASSWORD'

.run (
  $rootScope
  $ionicPlatform
  $ionicScrollDelegate
  $location
  $localStorage
  $interval
  $timeout
  KEY_COMPANY
  KEY_TOKEN
  Account
  Message
  ) ->

  $rootScope.fnOpenTimer = () ->
    $rootScope.timer = $interval () ->
      Message.count()
      .then (res) ->
        count = parseInt(res['1']) + parseInt(res['2']) + parseInt(res['3'])
        $rootScope.unreadMsg =  if count < 100 then count else '...'
        return
    , 30000
    return

  oToken = $localStorage[KEY_TOKEN]
  companyCode = $localStorage[KEY_COMPANY]
  if !companyCode
    $location.path('/company')
  else if(!oToken || !oToken.access_token)
    $location.path('/login')
  else
    if Account.permission 'vehicle_manager'
      $rootScope.fnOpenTimer()
      if $localStorage['newHome']
        $location.path '/newHome'
      else  
        $location.path '/allots'
    else if Account.permission 'driver'
      $rootScope.fnOpenTimer()
      $location.path '/mission'
    else
      $location.path '/userhome'
  # location   
  Account.getLocation()
  
  $ionicPlatform.ready () ->
    if window.cordova and
       window.cordova.plugins and
       window.cordova.plugins.Keyboard
      cordova.plugins.Keyboard.hideKeyboardAccessoryBar(true)
    if (window.StatusBar)
      StatusBar.styleLightContent()

  # 滚动功能切换
  $rootScope.$on '$stateChangeStart', (e, state) ->
    if state.name is 'car'
      $ionicScrollDelegate.freezeAllScrolls true
    else
      $ionicScrollDelegate.freezeAllScrolls false
    return
  return


  $rootScope.$on 'message.open', ->
    console.log 'message.open'
    $rootScope.fnOpenTimer()
    return
     
  $rootScope.$on 'message.close', ->
    console.log 'message.close'
    $interval.cancel $rootScope.timer


.factory 'pathInterceptor', (BASE_URL) ->
  interceptor =
    request: (config) ->
      # 正则表达式含义： 排除后缀为.html | 排除前缀为http: https:
      exp1 = !/.+(?=\.html$)/.test(config.url)
      exp2 = !/^(?=(http\:|https\:)).*/.test(config.url)
      if (exp1 && exp2)
        config.url = BASE_URL + config.url
        # 设置超时时间
        config.timeout = 10000
      return config
  return interceptor

.factory 'tokenInterceptor', ($q, $location, $localStorage, KEY_TOKEN) ->
  interceptor =
    request: (config) ->
      oToken = $localStorage[KEY_TOKEN]
      token_type = if oToken? then oToken.token_type else ''
      access_token = if oToken? then oToken.access_token else ''
      if oToken?
        config.headers['Authorization'] = token_type + access_token
      return config
    responseError: (rejection) ->
      switch rejection.status
        when 401
          delete $localStorage[KEY_TOKEN]
          $location.url '/login'
      return $q.reject rejection
  return interceptor

.factory 'logInterceptor', ($q, $log) ->
  interceptor =
    request: (config) ->
      if !/.+(?=\.html$)/.test(config.url)
        $log.debug '开始请求接口.接口地址=' +
        config.url +
        '; 请求参数=' +
        angular.toJson config.data
      return config
    response: (response) ->
      if !/.+(?=\.html$)/.test(response.config.url)
        $log.debug '接口请求成功.接口地址=' +
        response.config.url +
        '; 返回结果=' +
        angular.toJson response.data
      return response
    responseError: (rejection) ->
      if !/.+(?=\.html$)/.test(rejection.config.url)
        $log.debug '接口请求失败.接口地址=' + rejection.config.url
      return $q.reject rejection
  return interceptor

.config (
$stateProvider
$urlRouterProvider
$ionicConfigProvider
$httpProvider
) ->
  $ionicConfigProvider.views.maxCache(20)

  $ionicConfigProvider.views.transition('none')

  $ionicConfigProvider.views.forwardCache(true)

  $ionicConfigProvider.tabs.position('bottom')

  $ionicConfigProvider.navBar.alignTitle('center')

  $ionicConfigProvider.views.swipeBackEnabled(false);

  $stateProvider

  .state 'newHome',
    url: '/newHome'
    templateUrl: 'templates/newHome.html'

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



  $urlRouterProvider.otherwise '/'

  $httpProvider.interceptors.push 'pathInterceptor'
  $httpProvider.interceptors.push 'tokenInterceptor'
  $httpProvider.interceptors.push 'logInterceptor'

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
