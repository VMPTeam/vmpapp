angular.module 'starter.controllers', []

.controller 'NewHomeCtrl', (
$scope
Message
) ->
  vm = $scope.vm =
  # 未读消息
    unreadMsg: null
    
  ###
  # 获取未读消息
  ###
  $scope.fnGetMsgCount = ->
    Message.count()
    .then (res) ->
      vm.unreadMsg = res


# 首页控制器
.controller 'AllotCtrl', (
$scope
$state
$stateParams
$ionicPopup
$filter
$ionicLoading
$localStorage
$cordovaGeolocation
$timeout
Order
Account
Message
Map
) ->
  vm = $scope.vm =
    # 列表
    list: []
    # 页数
    pageStart: 1
    # 每页大小
    pageCount: 10
    # 是否更多
    hasMore: true
    # 未读消息
    unreadMsg: null
    # 订单类型
    orderType: 2
  
  $timeout ->
    $('.allot').offset (index, coords) ->
      temp = 
        top: coords.top + 80
        left: coords.left
      return temp
  , 200

  ###
  获取任务订单
  ###
  $scope.fnGetList = (status, concat = false) ->
    $ionicLoading.show()
    Order.list
      status: [status]
      pageStart: 1
      pageCount: 10
    .then (res) ->
      $ionicLoading.hide()
      if concat is true
        vm.list = vm.list.concat res.rows
      else
        vm.list = res.rows
      if res.total < vm.pageCount then vm.hasMore = false else vm.hasMore = true
    , (msg) ->
      $ionicLoading.hide()
      vm.hasMore = false
      return unless msg?
      $ionicPopup.alert
        title: msg
    .finally ()->
      $scope.$broadcast 'scroll.refreshComplete'
      $scope.$broadcast 'scroll.infiniteScrollComplete'

  ###
  获取天气信息
  ###
  $scope.fnWeather = ->
    Map.ip()
    .then (res) ->
      vm.city = res.content.address_detail.city
      Account.weather vm.city
      .then (res) ->
        date = res.today.date
        substr =  date.substr date.indexOf '实时：'
        substr = substr.match(/\d+/g)[0]
        res.today.temp = substr
        vm.weather = res

  ###
  # 获取未读消息
  ###
  $scope.fnGetMsgCount = ->
    Message.count()
    .then (res) ->
      vm.unreadMsg = res

  $scope.$watch 'vm.orderType', (val) ->
    $scope.fnGetList(val) if angular.isNumber val


# 车辆控制器
.controller 'CarCtrl', (
$scope
$state
$stateParams
$timeout
$filter
$http
$q
Car
Map
$ionicPopup
$localStorage
$ionicLoading
$ionicScrollDelegate
) ->
  vm = $scope.vm =
    list: []
    pageStart: 1
    pageCount: 10
    search: ''
    hasMore: true
    order: $localStorage[$stateParams.oid]
    startTime: $stateParams.startTime
    endTime: $stateParams.endTime
    mapView: $stateParams.type is 'map'
    selectedCar: null
  _CarMap = null
  _markerClusterer = null
  _lastInfoWindow = null

  ###
  获取车辆列表
  ###
  $scope.fnGetCarList = (concat = false, all = false) ->
    defer = $q.defer()
    $ionicLoading.show()
    vm.pageStart = 1 if concat is false
    if all
      data = 
        pageCount: 999999
        pageStart: 1
    else   
      data =
        pageCount: vm.pageCount
        pageStart: if concat is true then ++vm.pageStart else vm.pageStart
        matchLic: vm.search
        matchNick: vm.search
    Car.list data
    .then (res) ->
      defer.resolve()
      $ionicLoading.hide()
      if concat is true
        vm.list = vm.list.concat res.rows
      else
        vm.list = res.rows
      if res.total < vm.pageCount then vm.hasMore = false else vm.hasMore = true
      $scope.fnRefreshMarker(vm.list) if vm.mapView
    , (msg) ->
      defer.resolve()
      $ionicLoading.hide()
      vm.hasMore = false
      return unless msg?
      $ionicPopup.alert
        title: msg
    .finally ->
      defer.resolve()
      $scope.$broadcast 'scroll.refreshComplete'
      $scope.$broadcast 'scroll.infiniteScrollComplete'
    return defer.promise

  ###
  改变视图
  ###
  $scope.fnChangeView = ->
    vm.mapView = !vm.mapView

  ###
  初始化地图
  ###
  $scope.fnInitMap = ->
    $scope.fnGetCarList false, true
    .then ->
      _CarMap = new BMap.Map 'carMap', {enableMapClick:false}
      _CarMap.centerAndZoom '合肥', 12
      _CarMap.addControl new BMap.NavigationControl
        anchor: BMAP_ANCHOR_TOP_RIGHT
        #      offset: new BMap.Size(10, 70)
        type: BMAP_NAVIGATION_CONTROL_ZOOM
      _CarMap.addControl new BMap.ScaleControl
        anchor: BMAP_ANCHOR_BOTTOM_LEFT
        #      offset: new BMap.Size(10, 70)
      # _CarMap.addEventListener 'click', (data) ->
        # $timeout ->
        #   vm.selectedCar = null unless data.overlay?
      $timeout ->
        $scope.fnRefreshMarker(vm.list)
      , 1000


  ###
  刷新地图点
  ###
  $scope.fnRefreshMarker = (list) ->
    if list.length > 0 && _CarMap?
      markers = ($scope.fnCreateMarker item for item in list when item.location? and item.location.lo)
      points = (marker.getPosition() for marker in markers)
      _CarMap.setViewport points
      # if _markerClusterer?
        # _markerClusterer.clearMarkers()
        # _markerClusterer.addMarkers markers
      # else
      # if !_markerClusterer
      _CarMap.clearOverlays()
      _markerClusterer = new BMapLib.MarkerClusterer _CarMap,
        markers: markers
    else
      $timeout ->
        $scope.fnRefreshMarker(vm.list)
      , 1000

  ###
  创建标注点
  ###
  $scope.fnCreateMarker = (data) ->
    location = data.location || {}
    status = location.status || 0
      # point = new BMap.Point 117.229985 + Math.random()*0.1,31.82957 + Math.random()*0.1
    point = new BMap.Point location.lo, location.la
    icon = new BMap.Icon 'img/car' + status + '.png', new BMap.Size 18, 38
    marker = new BMap.Marker point,
      icon: icon
      rotation: location.dir || parseInt(Math.random() * 360)
    marker.vehicleUid = data.vehicleUid
    marker.addEventListener 'click', ->
      _CarMap.removeEventListener 'movestart', $scope.fnCloseInfoBox
      height = 195
      width = 256
      offset = 
        top: window.innerHeight / 2 - height - 50
        left: (window.innerWidth - width) / 2 
      $('.custom-info-box').css offset
      $('#carInfoBox').show()
      _CarMap.panTo marker.getPosition(), noAnimation:true
      $timeout ->
        _CarMap.addEventListener 'movestart', $scope.fnCloseInfoBox

      id = @.vehicleUid
      $scope.$apply () ->
        $scope.fnSelectCar id
    return marker

  $scope.fnCloseInfoBox = ->
    $('#carInfoBox').hide()
    _CarMap.removeEventListener 'movestart', $scope.fnCloseInfoBox
    $timeout () ->
      delete vm.selectedCar

  ###
  展示信息窗口
  ###
  $scope.fnOpenInfoBox = (marker, content='') ->
    dom = $('<div>').html(content)
    dom.children('.info').attr('id', marker.vehicleUid)
    data = $filter('filter')(vm.list, {vehicleUid: marker.vehicleUid})[0]
    dom.find('[data-driverName]').text data.driverName
    dom.find('[data-driverPhone]').text(data.driverPhone)
    .attr('src', 'tel:' + data.driverPhone)
    dom.find('[data-vehicleLic]').text data.vehicleLic
    dom.find('[data-buShortName]').text data.buShortName
    dom.find('[data-updateTime]')
    .text $filter('date')(data.location.updateTime, 'yyyy-MM-dd HH:mm:ss')
    Map.geoCoder [data.location.la, data.location.lo]
    .then (res) ->
      $('#' + marker.vehicleUid + ' [data-address]')
      .text res.sematic_description
    infoBoxConfig =
      offset: new BMap.Size 0, 20
      boxClass: 'custom-info-box'
      # enableAutoPan: true
      closeIconUrl: 'img/close(1).png'
      align: INFOBOX_AT_TOP
    # infoWindow = new BMapLib.InfoBox _CarMap, dom.html(), infoBoxConfig
    _lastInfoWindow = infoWindow
    # eventClose = (e, a) ->
    #   target = e.target
    #   return if $('.custom-info-box').contain target
    #   infoWindow.close()
    #   _CarMap.removeEventListener('click', eventClose)
    # _CarMap.addEventListener('click', eventClose)
    infoWindow.open marker

  ###
  选择车辆
  ###
  $scope.fnSelectCar = (id) ->
    vm.selectedCar = $filter('filter')(vm.list, {vehicleUid: id})[0]
    if vm.selectedCar?
      Map.geoCoder [vm.selectedCar.location.la, vm.selectedCar.location.lo]
      .then (res) ->
        vm.selectedCar.address = res.sematic_description if vm.selectedCar?

  $scope.$watch 'vm.mapView', (val) ->
    $ionicScrollDelegate.freezeAllScrolls val

# 驾驶员控制器
.controller 'DriverCtrl', (
$scope
$state
$stateParams
Driver
$ionicPopup
$localStorage
$ionicLoading
) ->
  vm = $scope.vm =
    list: []
    pageStart: 1
    pageCount: 15
    search: ''
    hasMore: true
    id: $stateParams.id

  # 获取驾驶员列表
  $scope.fnGetList = (concat = false) ->
    $ionicLoading.show()
    vm.pageStart = 1 if concat is false
    data =
      pageCount: vm.pageCount
      pageStart: if concat is true then ++vm.pageStart else vm.pageStart
      matchName: vm.search
      matchStaffCode: vm.search
    Driver.list data
    .then (res) ->
      $ionicLoading.hide()
      if concat is true
        vm.list = vm.list.concat res.rows
      else
        vm.list = res.rows
      if res.total < vm.pageCount then vm.hasMore = false else vm.hasMore = true
    , (msg) ->
      $ionicLoading.hide()
      vm.hasMore = false
      return unless msg?
      $ionicPopup.alert
        title: msg
    .finally ->
      $scope.$broadcast 'scroll.refreshComplete'
      $scope.$broadcast 'scroll.infiniteScrollComplete'

  $scope.fnDetail = (id) ->
    $ionicLoading.show()
    Driver.detail id
    .then (res) ->
      $ionicLoading.hide()
      vm.driver = res
    , (msg) ->
      $ionicLoading.hide()
      return unless msg?
      $ionicPopup.alert
        title: msg



# 帐号控制器
.controller 'AccountCtrl', (
$scope
$state
$stateParams
$ionicLoading
$ionicPopup
$localStorage
$cordovaGeolocation
Account
Message
KEY_COMPANY
KEY_TOKEN
KEY_USERNAME
KEY_PASSWORD
KEY_ACCOUNT
CLIENT_TYPE
) ->
  vm = $scope.vm =
    username: $localStorage[KEY_USERNAME]
    password: $localStorage[KEY_PASSWORD]
    companyInfo: $localStorage[KEY_COMPANY]
    account: $localStorage[KEY_ACCOUNT]
    reminderList: []
    msg: null
    # tabs
    tabs: [
      {
        id: 1
        name: '异常用车处理'
      }
      {
        id: 2
        name: '故障维修处理'
      }
      {
        id: 3
        name: '保险年检处理'
      }
    ]
    list: []
    pageStart: 1
    pageCount: 10
    currentTab: parseInt($stateParams.type) || 1
    newHome: $localStorage['newHome']


  # 设置企业号
  $scope.fnSetCompanyCode = (code) ->
    $ionicLoading.show
      template: '正在设置,请稍后'
    Account.getCompany code
    .then (data) ->
      $ionicLoading.hide()
      $localStorage[KEY_COMPANY] = data
      $state.go('login')
    , (msg) ->
      $ionicLoading.hide()
      return unless msg?
      $ionicPopup.alert
        title: msg

  # 登录
  $scope.fnLogin = (username, password) ->
    vm.companyInfo = $localStorage[KEY_COMPANY]
    if !username or !password
      $ionicPopup.alert
        title: '请填写用户名和密码'
      return
    $ionicLoading.show
      template: '正在登录...'
      hideOnStateChange: true
    Account.login username + '@' + vm.companyInfo.orgCode, password
    .then () ->
      return Account.userInfo()
    .then (res) ->
      # 判断用户权限是否能使用该客户端
      $ionicLoading.hide()
      $localStorage[KEY_USERNAME] = username
      $localStorage[KEY_PASSWORD] = password
      if window.cordova and
         window.cordova.plugins and
         window.cordova.plugins.XGPlugin
        cordova.plugins.XGPlugin.register (res) ->
          console.log res
        , (err) ->
          console.log err
        , username + '@' + vm.companyInfo.orgCode
      vm.userInfo = res
      if Account.permission 'vehicle_manager'
        # open timer
        $scope.$emit 'message.open'
        if $localStorage['newHome']
          $state.go 'newHome'
        else  
          $state.go 'allot'
      else if Account.permission 'driver'
        # open timer
        $scope.$emit 'message.open'
        $state.go 'mission'
      else
        $state.go 'userHome'
      # if res.roles? and role = CLIENT_TYPE in res.roles
      #   $localStorage[KEY_USERNAME] = username
      #   $localStorage[KEY_PASSWORD] = password
      #   vm.userInfo = res
      #   $state.go 'tab.allot'
      # else
      #   delete $localStorage[KEY_TOKEN]
      #   $ionicPopup.alert
      #     title: '你没有权限使用该客户端'
    , (msg) ->
      # 清除登录信息
      delete $localStorage[KEY_TOKEN]
      $ionicLoading.hide()
      return unless msg?
      $ionicPopup.alert
        title: msg

  # 退出登录
  $scope.fnLogout = ->
    $scope.$emit 'message.close'
    Account.logout()
    .then () ->
      if window.cordova and
         window.cordova.plugins and
         window.cordova.plugins.XGPlugin
        cordova.plugins.XGPlugin.unregister()
      $state.go('login')

  # 获取提醒设置列表
  $scope.fnGetReminderList = ->
    Account.reminderList()
    .then (res) ->
      vm.reminderList = res.rows
    , (msg) ->
      return unless msg?
      $ionicPopup.alert
        title: msg

  # 更新提醒设置
  $scope.fnUpdateReminder = (item) ->
    Account.updateReminder(item)
    .catch ->
      $ionicPopup.alert
        title: '请检查你的网络'
      item.checked = !item.checked

  $scope.fnSettingNewHome = (status) ->
    console.log status
    $localStorage['newHome'] = status

  # 修改密码
  $scope.fnMofidyPwd = (oldPwd, newPwd, confirmPwd) ->
    if newPwd is confirmPwd
      data =
        oldPassword: oldPwd
        password: newPwd
      Account.modifyPwd data
      .then ->
        $ionicPopup.alert
          title: '密码已修改'
      , (msg) ->
        return unless msg?
        $ionicPopup.alert
          title: msg
    else
      $ionicPopup.alert
        title: '两次密码输入不一致'

  $scope.fnGetPermission = (role) ->
    return Account.permission role

  ###
  # 获取消息列表
  ###
  $scope.fnGetMsgList = (tab, concat = false) ->
    vm.currentTab = tab if tab?
    if concat is false
      vm.pageStart = 1
      vm.list = []
    data =
      messageType: tab
      pageCount: vm.pageCount
      pageStart: if concat is true then ++vm.pageStart else vm.pageStart
    $ionicLoading.show()
    Message.list data
    .then (res) ->
      $ionicLoading.hide()

      if concat is true
        vm.list = vm.list.concat res.rows
      else
        vm.list = res.rows
      if res.total < vm.pageCount then vm.hasMore = false else vm.hasMore = true

    , (msg) ->
      $ionicLoading.hide()

      vm.hasMore = false
      return unless msg?
      $ionicPopup.alert
        title: msg
    .finally ->
      $scope.$broadcast 'scroll.refreshComplete'
      $scope.$broadcast 'scroll.infiniteScrollComplete'

  ###
  # 获取消息详情
  ###
  $scope.fnDetail = ->
    Message.detail $stateParams.messageUid
    .then (res) ->
      vm.msg = res;




# 订单详情控制器
.controller 'AllotDetailCtrl', (
$scope
$state
$stateParams
$ionicLoading
$ionicPopup
$localStorage
$ionicModal
$ionicHistory
Order
Car
Driver
Account
KEY_ACCOUNT
) ->
  vm = $scope.vm =
    id: $stateParams.id
    nextId: ''
    list: []
    pageStart: 1
    pageCount: 10
    search: ''
    orderList: []
    order: {}
    subOrder: $localStorage[$stateParams.oid]
    account: $localStorage[KEY_ACCOUNT]
    tabs: [
      {
        id: 1,
        name: '审批中'
      },
      {
        id: 2,
        name: '已配车'
      },
      {
        id: 3,
        name: '在途'
      },
      {
        id: 4,
        name: '历史'
      }
    ]
    currentTab: $stateParams.id
    startTime: $stateParams.startTime
    endTime: $stateParams.endTime
    location: null
    retryTime: 3

  ###
  获取地理位置
  ###
  $scope.fnGetLocation = ->
    if !vm.location
      Account.getLocation()
      .then (res) ->
        vm.location = res
      , (err) ->
        if vm.retryTime > 0
          vm.retryTime--;
          $scope.fnGetLocation()

  $scope.fnGetDistance = (location) ->
    if vm.location? and location?
      distance = Account.getDistance vm.location.lat, vm.location.lng, parseInt(location.la), parseInt(location.lo)
      return distance + 'km' if distance?

  ###
  获取订单列表
  ###
  $scope.fnGetOrderList = ->
    Order.list
      status: [2]
    .then (res) ->
      vm.orderList = res.rows
      vm.nextId = $scope.fnGetNextId res.rows
    , (msg) ->
      return unless msg?
      $ionicPopup.alert
        title: msg

  ###
  获取下个订单号
  ###
  $scope.fnGetNextId = (list) ->
    for order,i in list
      if order.serialNum is vm.id
        if vm.orderList[i + 1]?
          return vm.orderList[i + 1].serialNum
        else
          return

  ###
  获取订单详情
  ###
  $scope.fnDetail = () ->
    $ionicLoading.show()
    Order.detail vm.id
    .then (data) ->
      # 刷新分配车辆信息
      $scope.fnRefreshCarList data.driverAndVehicle
      vm.order = data
      $ionicLoading.hide()
    , (msg) ->
      $ionicLoading.hide()
      return unless msg?
      $ionicPopup.alert
        title: msg

  ###
  提交并处理下一条
  ###
  $scope.fnCommit = (next)->
    # 检查是否分配车辆和驾驶员
    for order in vm.order.driverAndVehicle
      if !order.vehicleUid || !order.userUid
        $ionicPopup.alert
          title: '请先分配车辆和驾驶员'
        return
    $ionicLoading.show()
    Order.issue vm.id, vm.order.driverAndVehicle
    .then ->
      $ionicLoading.hide()
      if vm.nextId and next
        $scope.fnChangeTab vm.nextId
      else
        $state.go 'allot'
    , (msg) ->
      $ionicLoading.hide()
      return unless msg?
      $ionicPopup.alert
        title: msg

  ###
  切换tab
  ###
  $scope.fnChangeTab = (id) ->
    $state.go 'allotDetail',
      id: id

  ###
  进入车辆挑选列表
  ###
  $scope.fnGotoCarList = (list) ->
    for order in list
      if !order.vehicleUid
        # 缓存订单号
        $localStorage[order.orderUid] = angular.extend order, {serialNum: vm.id}
        $state.go 'cars',
          oid: order.orderUid
          startTime: vm.order.planStartTime
          endTime: vm.order.planEndTime
        break

  ###
  获取车辆列表
  ###
  $scope.fnGetCarList = (concat = false) ->
    $ionicLoading.show()
    vm.pageStart = 1 if concat is false
    data =
      pageCount: vm.pageCount
      pageStart: if concat is true then ++vm.pageStart else vm.pageStart
      status: 5
      startTime: vm.startTime + ':00'
      endTime: vm.endTime + ':00'
      matchLic: vm.search
      matchNick: vm.search
    Car.list data
    .then (res) ->
      $ionicLoading.hide()

      if concat is true
        vm.list = vm.list.concat res.rows
      else
        vm.list = res.rows
      if res.total < vm.pageCount then vm.hasMore = false else vm.hasMore = true
    , (msg) ->
      $ionicLoading.hide()

      vm.hasMore = false
      return unless msg?
      $ionicPopup.alert
        title: msg
    .finally ->
      $scope.$broadcast 'scroll.refreshComplete'
      $scope.$broadcast 'scroll.infiniteScrollComplete'

  ###
  选择车辆
  ###
  $scope.fnSelectCar = (car) ->
    # 判断是否已选
    angular.extend $localStorage[$stateParams.oid], car
    $state.go 'drivers',
      oid: $stateParams.oid
      startTime: vm.startTime
      endTime: vm.endTime

  ###
  检查是否还有未分配订单
  ###
  $scope.fnCheckEmptyOrder = ->
    return false unless vm.order.driverAndVehicle?
    for order in vm.order.driverAndVehicle
      if !order.vehicleUid || !order.userUid
        return true

  ###
  清除订单信息
  ###
  $scope.fnClearOrder = (order, event) ->
    delete order.vehicleUid
    event.stopPropagation()


  ###
  进入驾驶员列表
  ###
  $scope.fnGotoDriverList = (order) ->
    # 缓存订单号
    $localStorage[order.orderUid] = angular.extend order, {serialNum: vm.id}
    $state.go 'drivers',
      oid: order.orderUid
      startTime: vm.order.planStartTime
      endTime: vm.order.planEndTime

  # 获取驾驶员列表
  $scope.fnGetDriverList = (concat = false) ->
    $ionicLoading.show()
    vm.pageStart = 1 if concat is false
    data =
      pageCount: vm.pageCount
      pageStart: if concat is true then ++vm.pageStart else vm.pageStart
      status: 1
      startTime: vm.startTime + ':00'
      endTime: vm.endTime + ':00'
      matchName: vm.search
      matchStaffId: vm.search
    Driver.list data
    .then (res) ->
      $ionicLoading.hide()

      if concat is true
        vm.list = vm.list.concat res.rows
      else
        vm.list = res.rows
      if res.total < vm.pageCount then vm.hasMore = false else vm.hasMore = true
    , (msg) ->
      $ionicLoading.hide()

      vm.hasMore = false
      return unless msg?
      $ionicPopup.alert
        title: msg
    .finally ->
      $scope.$broadcast 'scroll.refreshComplete'
      $scope.$broadcast 'scroll.infiniteScrollComplete'

  ###
  选择驾驶员
  ###
  $scope.fnSelectDriver = (driver) ->
    #选择驾驶员
    if $localStorage[$stateParams.oid]?
      angular.extend $localStorage[$stateParams.oid], driver
    else
      $localStorage[$stateParams.oid] = driver
    $state.go 'allotDetail',
      id: vm.subOrder.serialNum

  ###
  刷新分配车辆信息
  ###
  $scope.fnRefreshCarList = (list) ->
    angular.extend order, $localStorage[order.orderUid] for order in list

# 车辆详情控制器
.controller 'CarInfoCtrl', (
$scope
$state
$stateParams
$timeout
$filter
$interval
$ionicLoading
$ionicPopup
$cordovaDatePicker
$ionicScrollDelegate
$localStorage
$ionicModal
Car
Map
) ->
  vm = $scope.vm =
    id: $stateParams.id
    tabList: [
      '车辆档案'
      '行车记录'
      '车辆跟踪'
      '车辆状况'
      '停车分布'
    ]
    info: {}
    journals: {}
    today: new Date()
    beginTime: new Date()
    endTime: new Date()
    currentLocation: {}
  $scope.today = new Date()
  _traceMap = null
  _carMarker = null
  _parkMap = null
  _gauge = null

  if ionic.Platform.isIOS()
    $timeout ->
      $('.car-info-content').offset (index, coords) ->
        temp = 
          top: coords.top + 20
          left: coords.left
        return temp
    , 800

  $scope.fnInitTab = ->
    if $stateParams.type?
      vm.tab = vm.tabList[$stateParams.type - 1]
    else
      vm.tab = vm.tabList[0]
  # 打开日期选择器
  $scope.fnOpenPicker = ()->
    vm.todayInstance.show()

  # 查询车辆详情
  $scope.fnGetCarDetail = ->
    Car.detail vm.id
    .then (res) ->
      vm.info = res
      vm.currentLocation = res.location || {}
    , (msg) ->
      return unless msg?
      $ionicPopup.alert
        title: msg

  # 启动/关闭获取位置定时器
  $scope.fnToggleLocationTimer = (flag = false) ->
    $interval.cancel vm.locationTimer
    if flag is true
      vm.locationTimer = $interval ->
        Car.location vm.id
        .then (res) ->
          vm.currentLocation = res
          $scope.fnRefreshMarker vm.currentLocation if vm.tab is '车辆跟踪'
          $scope.fnRefreshDashboard vm.currentLocation if vm.tab is '车辆状况'
          $scope.fnInitPark vm.currentLocation if vm.tab is '停车分布'
      , 30000

  # 刷新定位点
  $scope.fnRefreshMarker = (location) ->
    # 初始化坐标点
    point = new BMap.Point location.lo, location.la
    #    point = new BMap.Point 117.229985 + Math.random()*0.1,31.82957 + Math.random()*0.1
    # 初始化覆盖物
    if !_carMarker
      _carMarker = new BMap.Marker point
      _traceMap.addOverlay _carMarker
      _traceMap.setViewport [point]
    # 设置覆盖物相关属性
    _carMarker.setPosition point
    icon = new BMap.Icon 'img/car' + (location.status || 0) + '.png', new BMap.Size 18, 38
    _carMarker.setIcon icon
    _carMarker.setRotation location.dir || parseInt(Math.random() * 360)
    _traceMap.panTo point

  # 刷新仪表盘
  $scope.fnRefreshDashboard = (location) ->
    # chart option  
    speedOption =
      name: '时速'
      type: 'gauge'
      z: 3
      min: 0
      max: 240
      splitNumber: 6
      axisLine:
        lineStyle:
          color: [[0.2, '#1bb2d8'],[0.8, '#1790cf'],[1, '#1c7099']]
          width: 6
      axisTick:
        splitNumber: 10
        lenth: 14
        lineStyle:
          color: 'auto'
      splitLine:
        length: 20
        lineStyle:
          color: 'auto'
      pointer:
        length: '90%'
        color: 'auto'
      title:
        offsetCenter: [0, '84%']
        textStyle:
          color: '#333'
          fontWeight: 'bolder'
          fontSize: 12
          fontStyle: 'italic'
      detail:
        textStyle:
          fontWeight: 'bloder'
          color: 'auto'
      data: [
        {
          value: parseFloat location.speed || 0
          name: 'km/h'
        }
      ]
    rpmOption =
      name: '转速'
      type: 'gauge'
      center: ['16%', '55%']
      radius: ['50%', '50%']
      min: 0
      max: 8
      endAngle: 45
      splitNumber: 4
      axisLine:
        lineStyle:
          color: [[0.2, '#1bb2d8'],[0.8, '#1790cf'],[1, '#1c7099']]
          width: 6
      axisTick:
        splitNumber: 10
        lenth: 12
        lineStyle:
          color: 'auto'
      splitLine:
        length: 18
        lineStyle:
          color: 'auto'
      pointer:
        width: 5
      title:
        offsetCenter: [0, '100%']
        textStyle:
          color: '#333'
          fontWeight: 'bolder'
          fontSize: 12
          fontStyle: 'italic'
      detail:
        offsetCenter: [0, '20%']
        textStyle:
          fontWeight: 'bloder'
          color: 'auto'
      data: [
        {
          value: parseFloat(location.rpm || 0) * 0.001
          name: 'x1000 r/min'
        }
      ]
    voltageOption =
      name: '电压'
      type: 'gauge'
      center: ['84%', '50%']
      radius: '50%'
      min: 0
      max: 36
      startAngle: 135
      endAngle: 45
      splitNumber: 2
      axisLine:
        lineStyle:
          color: [[0.2, '#ff4500'],[0.8, '#48b'],[1, '#228b22']]
          width: 8
      axisTick:
        splitNumber: 9
        lenth: 10
        lineStyle:
          color: 'auto'
      axisLabel:
        formatter: (v) ->
          switch v
            when 9 then return 'L'
            when 18 then return '电压'
            when 36 then return 'H'
      splitLine:
        length: 15
        lineStyle:
          color: 'auto'
      pointer:
        width: 2
      title:
        show: false
      detail:
        show: false
      data: [
        {
          value: parseFloat(location.voltage || 0)
        }
      ]
    waterOption =
      name: '水温'
      type: 'gauge'
      center: ['84%', '60%']
      radius: '50%'
      min: -40
      max: 200
      startAngle: 315
      endAngle: 225
      splitNumber: 2
      axisLine:
        lineStyle:
          color: [[0.2, '#ff4500'],[0.8, '#48b'],[1, '#228b22']]
          width: 8
      axisTick:
        splitNumber: 9
        lenth: 10
        lineStyle:
          color: 'auto'
      axisLabel:
        formatter: (v) ->
          console.log v, '电压'

          switch v
            when -40 then return 'L'
            when 80 then return '水温'
            when 200 then return 'H'
      splitLine:
        length: 15
        lineStyle:
          color: 'auto'
      pointer:
        width: 2
      title:
        show: false
      detail:
        show: false
      data: [
        {
          value: parseFloat(location.waterDegree || 0)
        }
      ]

    option = 
      series: [
        speedOption
        rpmOption
        voltageOption
        waterOption
      ]
    $timeout () ->
      if !_gauge
        _gauge = echarts.init(document.getElementById('gauge'), 'blue')
      _gauge.setOption option
      _gauge.refresh()
    , 500


  #初始化车辆跟踪页面
  $scope.fnInitTrace = ->
    $timeout ->
      _traceMap = new BMap.Map 'traceMap'
      _traceMap.centerAndZoom '合肥', 10
      _traceMap.addControl new BMap.NavigationControl
        anchor: BMAP_ANCHOR_BOTTOM_RIGHT
        type: BMAP_NAVIGATION_CONTROL_ZOOM
      _traceMap.addControl new BMap.ScaleControl
        anchor: BMAP_ANCHOR_BOTTOM_LEFT
      # else
        # _traceMap.reset()
      $timeout ->
        $scope.fnRefreshMarker vm.currentLocation if vm.currentLocation?
      , 2000
    , 500

  # 初始化停车分布页面
  $scope.fnInitPark = ->
    if !_parkMap
      _parkMap = new BMap.Map 'parkMap'
      _parkMap.centerAndZoom '合肥', 10
      _parkMap.addControl new BMap.NavigationControl
        anchor: BMAP_ANCHOR_BOTTOM_RIGHT
        type: BMAP_NAVIGATION_CONTROL_ZOOM
      _parkMap.addControl new BMap.ScaleControl
        anchor: BMAP_ANCHOR_BOTTOM_LEFT
    else
      _parkMap.clearOverlays()
    points = (item.point for item in vm.parks)
    # currentPoint = new BMap.Point 117.229985 + Math.random()*0.1,31.82957 + Math.random()*0.1
    if vm.currentLocation.lo? and vm.currentLocation.la?
      currentPoint = new BMap.Point vm.currentLocation.lo, vm.currentLocation.la
      marker = new BMap.Marker currentPoint,
        icon: new BMap.Icon 'img/car3.png', new BMap.Size 18, 38
        rotation: vm.currentLocation.dir || parseInt(Math.random() * 360)
      points.push currentPoint
      _parkMap.addOverlay marker
    _parkMap.setViewport points
    _parkMap.addOverlay($scope.fnCreateLabelMarker(item.point)) for item in vm.parks

  $scope.fnCreateLabelMarker = (point) ->
    marker = new BMap.Marker(point)
    geoc = new BMap.Geocoder()
    geoc.getLocation point, (rs) ->
      # 获取POI地点
      pois = rs.surroundingPois
      business = rs.business
      if pois? and pois.length > 0
        text = pois[0].title
      else if business
        bArr = business.split ','
        text = bArr[0]
      else
        addComp = rs.addressComponents
        text = addComp.province +
        addComp.city +
        addComp.district +
        addComp.street +
        addComp.streetNumber
      label = new BMap.Label(text, {offset: new BMap.Size(20, -10)})
      marker.setLabel(label)
    return marker

  # 获取历史记录
  $scope.fnGetPark = ->
    $timeout ->
      $scope.fnInitPark()
    , 500
    getPoint = (item) ->
      item.point = new BMap.Point(item.lo, item.la)
      return item
    Car.park vm.id
    .then (res) ->
      vm.parks = (getPoint item for item in res.rows)
      $scope.fnInitPark()
    , (msg) ->
      return unless msg?
      $ionicPopup.alert
        title: msg

  # 获取行车记录
  $scope.fnGetJournals = ->
    data =
      day: $filter('date')(vm.today, 'yyyy-MM-dd')
    Car.journals vm.id, data
    .then (res) ->
      vm.journals = res.rows
      $scope.fnGeoCoder vm.journals
    , (msg) ->
      return unless msg?
      $ionicPopup.alert
        title: msg

  # 获取地理信息
  $scope.fnGeoCoder = (list) ->
    angular.forEach list, (item) ->
      Map.geoCoder [item.startLoc.locLa, item.startLoc.locLo]
      .then (res) ->
        angular.extend item.startLoc, res

      Map.geoCoder [item.endLoc.locLa, item.endLoc.locLo]
      .then (res) ->
        angular.extend item.endLoc, res

  # 查询时间差
  $scope.fnDateLenth = (time) ->
    date3 = parseInt time * 1000
    days = Math.floor(date3/(24*3600*1000))
    leave1 = date3 % (24*3600*1000)
    hours = Math.floor(leave1/(3600*1000))
    leave2 = leave1%(3600*1000)
    minutes = Math.floor(leave2/(60*1000))
    if days > 0
      return days + '天' + hours + '小时'
    else if hours > 0
      return hours + '小时' + minutes + '分钟'
    else
      return minutes + '分钟'

  $scope.fnGetFuel = ->
    result = 0
    (result += parseFloat item.fuel for item in vm.journals)
    return result

  $scope.fnGetMile = ->
    result = 0
    (result += parseFloat item.miles for item in vm.journals)
    return result/1000

  $scope.fnGetAvgFuel = ->
    fuel = 0
    mile = 0
    for item in vm.journals
      fuel += parseFloat(item.fuel)
      mile += parseFloat(item.miles)
    return (fuel/mile)*100

  # 获取其他日期
  $scope.fnOtherDay = (date, day) ->
    d = new Date(date.valueOf())
    d.setDate(d.getDate() + day)
    vm.todayInstance.setVal vm.today, false, false, true
    return d

  # 设置日期
  $scope.fnSetDay = (date, day) ->
    if day > 0
      return if ($scope.today.valueOf() - date.valueOf()) < 1*24*60*60*1000
    vm.today.setDate(date.getDate() + day)

  $scope.fnCanNextDay = ->
    return if ($scope.today.valueOf() - vm.today.valueOf()) > 1*24*60*60*1000

  $scope.$watch 'vm.today', ->
    if vm.tab is '行车记录'
      $scope.fnGetJournals()
  , true

  $scope.$watch 'vm.tab', (val) ->
    $ionicScrollDelegate.freezeAllScrolls false
    $scope.fnToggleLocationTimer false
    switch val
      when '车辆跟踪'
        vm.mapView = true
        $scope.fnInitTrace()
        $scope.fnToggleLocationTimer true
        $ionicScrollDelegate.freezeAllScrolls true
      when '车辆状况'
        $scope.fnRefreshDashboard vm.currentLocation
        $scope.fnToggleLocationTimer true
        $ionicScrollDelegate.freezeAllScrolls true
      when '行车记录'
        $scope.fnGetJournals()
      when '停车分布'
        vm.mapView = true
        $scope.fnGetPark()
        $scope.fnToggleLocationTimer true
        $ionicScrollDelegate.freezeAllScrolls true

# 电子栅栏控制器
.controller 'AreaCtrl', ($scope
$state
$stateParams
$timeout
$filter
$ionicActionSheet
$ionicHistory
$ionicLoading
$ionicPopup
$localStorage
Area
Car
) ->
  vm = $scope.vm =
    # 栅栏列表
    list: []
    carList: []
    id: $stateParams.id
    formData:
      type: 0
      points: []
      trigger: 0
      startTime: new Date()
      endTime: new Date()
      vehicles: []
  _areaMap = null

  # 打开日期选择
  $scope.fnOpenPicker = (attr) ->
    $cordovaDatePicker.show
      mode: 'time'
      date: vm.formData[attr]
      doneButtonLabel: '确定'
      cancelButtonLabel: '取消'
    .then (date) ->
      vm.formData[attr] = date if date?
    return

  # 获取列表
  $scope.fnGetList = ->
    $ionicLoading.show()
    Area.list()
    .then (res) ->
      $ionicLoading.hide()
      vm.list = res.rows
    , (msg) ->
      $ionicLoading.hide()
      return unless msg?
      $ionicPopup.alert
        title: msg

  # 获取车辆列表
  $scope.fnGetCarList = ->
    $ionicLoading.show()
    Car.list
      pageCount: 20000
    .then (res) ->
      $ionicLoading.hide()
      vm.carList = res.rows
      for item in vm.carList
        if (item.vehicleUid in $localStorage['AREA_CARS'])
          item.checked = true
    , (msg) ->
      $ionicLoading.hide()
      return unless msg?
      $ionicPopup.alert
        title: msg

  # 勾选车辆
  $scope.fnSaveCheckCar = ->
    selectedCar = $filter('filter')(vm.carList, {checked: true})
    $localStorage['AREA_CARS'] = (item.vehicleUid for item in selectedCar)
    $ionicHistory.goBack(-1)

  # 获取详情
  $scope.fnDetail = ->
    if vm.id?
      Area.detail vm.id
      .then (res) ->
        angular.extend vm.formData, res
        $localStorage['points_' + res.areaUid] = 
          type: res.type
          radius: res.radius
          points: res.points
      , (msg) ->
        return unless msg?
        $ionicPopup.alert
          title: msg

  # 显示菜单
  $scope.fnShowSheet = (item) ->
    hideSheet = $ionicActionSheet.show
      buttons: [
        { text: '查看详情'}
        { text: '开启'}
        { text: '关闭'}
      ]
      cancelText: '取消'
      # destructiveText: '删除'
      buttonClicked: (index) ->
        # 开启关闭操作
        switch index
          when 0
            $state.go 'areaDetail',
              id: item.areaUid
          when 1
            console.log '开启'
            Area.enable item.areaUid
            .then ->
              $scope.fnGetList()
            , (msg) ->
              $ionicPopup.alert
                title: msg
          when 2
            console.log '关闭'
            Area.disable item.areaUid
            .then ->
              $scope.fnGetList()
            , (msg) ->
              $ionicPopup.alert
                title: msg
        return true
      destructiveButtonClicked: ->
        # 删除操作
        Area.remove item.areaUid
        .then ->
          $scope.fnGetList()
        , (msg) ->
          $ionicPopup.alert
            title: msg
        return true

  # 初始化地图
  $scope.fnInitMap = ->
    _areaMap = new BMap.Map 'areaMap'
    _areaMap.centerAndZoom '合肥', 14
    _areaMap.addControl new BMap.NavigationControl()
      # anchor: BMAP_ANCHOR_TOP_RIGHT
      #      offset: new BMap.Size(10, 70)
      # type: BMAP_NAVIGATION_CONTROL_ZOOM
    _areaMap.addControl new BMap.ScaleControl()
      # anchor: BMAP_ANCHOR_TOP_LEFT
      #      offset: new BMap.Size(10, 70)

    # 定义区域控件
    areaControl = () ->
      lineWidth = window.innerWidth / 2
      x = (window.innerWidth - lineWidth) / 2
      y = (window.innerHeight - lineWidth) / 2
      @.defaultAnchor = BMAP_ANCHOR_TOP_LEFT
      @.defaultOffset = new BMap.Size(x, y)
      return

    areaControl.prototype = new BMap.Control()

    areaControl.prototype.initialize = (map) ->
      div = document.createElement('div')
      lineWidth = window.innerWidth/2
      div.style.width = lineWidth + 'px'
      div.style.height = lineWidth + 'px'
      div.style.border = '2px solid rgb(23,121,253)'
      div.style.backgroundColor = "rgba(0,0,0,.4)"
      map.getContainer().appendChild(div)
      return div

    if $stateParams.read
      $scope.fnDrawPoints $localStorage['points_' + vm.id]
    else
      _areaMap.addControl new areaControl()

  #坐标处理
  $scope.fnDrawPoints = (pointInfo) ->
    type = pointInfo.type
    points = (new BMap.Point(point.lo, point.la) for point in pointInfo.points)
    if type is 1
      # 画圆
      circle = new BMap.Circle points[0], pointInfo.radius,
        strokeWeight: 2
        strokeColor: "#ff0000"
      _areaMap.addOverlay circle
      $timeout ->
        _areaMap.panTo points[0]
      , 200
      return
    else
      # 画多边形
      polygon = new BMap.Polygon points,
        strokeWeight: 2
        strokeColor: "#ff0000"
      _areaMap.addOverlay polygon
      # points = points.concat polygon.getPath()
      $timeout ->
        _areaMap.setViewport points
      , 200
      return

  # 获取选取区域
  $scope.fnGetPoints = ->
    points = $localStorage['AREA_POINTS'] || []
    if points.length > 0
      vm.formData.points = points
    return points

  # 获取选择车辆
  $scope.fnGetSelectedCar = ->
    cars = $localStorage['AREA_CARS'] || []
    if cars.length > 0
      vm.formData.vehicles = cars
    return cars

  # 获取选定范围
  $scope.fnGetBounds = ->
    pointArray = []
    pointFormat = (point) ->
      data =
        lo: point.lng
        la: point.lat
    lineWidth = window.innerWidth / 2
    # 左上
    lt = new BMap.Pixel((window.innerWidth - lineWidth) / 2, (window.innerHeight - lineWidth) / 2)
    pointArray.push _areaMap.pixelToPoint lt
    # 右上
    rt = new BMap.Pixel((window.innerWidth + lineWidth) / 2, (window.innerHeight - lineWidth) / 2)
    pointArray.push _areaMap.pixelToPoint(rt)
    # 右下
    rb = new BMap.Pixel((window.innerWidth + lineWidth) / 2, (window.innerHeight + lineWidth) / 2)
    pointArray.push _areaMap.pixelToPoint rb
    # 左下
    lb = new BMap.Pixel((window.innerWidth - lineWidth) / 2, (window.innerHeight + lineWidth) / 2)
    pointArray.push _areaMap.pixelToPoint()
    $localStorage['AREA_POINTS'] = (pointFormat item for item in pointArray)
    $ionicHistory.goBack -1

  # 创建区域
  $scope.fnCreate = ->
    $ionicLoading.show()
    data = angular.copy vm.formData
    data.startTime = $filter('date')(data.startTime, 'HH:mm')
    data.endTime = $filter('date')(data.endTime, 'HH:mm')
    Area.create data
    .then () ->
      $ionicLoading.hide()
      $state.go 'areaList'
    , (msg) ->
      $ionicLoading.hide()
      return unless msg?
      $ionicPopup.alert
        title: msg


.controller 'MissionCtrl', (
$scope
$state
$stateParams
$filter
$ionicLoading
$ionicPopup
$localStorage
$ionicHistory
Order
Account
Car
Map
KEY_ACCOUNT
) ->
  vm = $scope.vm =
    current: null
    list: []
    isBegin: false
    taxId: $stateParams.taxId
    costId: $stateParams.costId
    account: $localStorage[KEY_ACCOUNT]
    retryTime: 3
    tax:
      costTime: new Date()
  $scope.today = new Date()

  $scope.fnConcatPeople = (list) ->
    return '' unless angular.isArray list
    _arr = (people.name for people in list)
    return _arr.join(',')

  $scope.fnGetTaxInfo = ->
    if vm.costId?
      Order.detailTax vm.costId
      .then (res)->
        angular.extend vm.tax, res

  ###
  拼接车牌号
  ###
  $scope.fnConcatVehicleLic = (list) ->
    if angular.isArray list
      vehicleLicArray = (vehicle.vehicleLic for vehicle in list)
      return vehicleLicArray.join ','

  ###
  获取任务订单
  ###
  $scope.fnGetList = ->
    $ionicLoading.show()
    Order.list
      status: [3, 4].join(',')
    .then (res) ->
      vm.list = res.rows
      vm.current = vm.list.shift()
      $ionicLoading.hide()
    , (msg) ->
      $ionicLoading.hide()
      return unless msg?
      $ionicPopup.alert
        title: msg
    .finally ()->
      $scope.$broadcast 'scroll.refreshComplete'
      $scope.$broadcast 'scroll.infiniteScrollComplete'

  ###
  开始发车
  ###
  $scope.fnBegining = (id,event) ->
    Order.begin id
    .then ->
      vm.current.status = 4
    , (msg) ->
      $ionicPopup.alert
        title: msg
    event.stopPropagation()

  ###
  完成任务
  ###
  $scope.fnFinish = (id, event) ->
    $ionicPopup.confirm
      title: '完成任务',
      template: '是否确认完成任务'
    .then (res) ->
      if res
        Order.finish id
        .then ->
          $scope.fnGetList()
        , (msg) ->
          return unless msg?
          $ionicPopup.alert
            title: msg
    event.stopPropagation()

  ###
  查询税费列表
  ###
  $scope.fnGetTaxList = () ->
    Order.taxList vm.taxId
    .then (res) ->
      vm.taxList = res.rows
    , (msg) ->
      return unless msg?
      $ionicPopup.alert
        title: msg

  ###
  打开税费管理列表
  ###
  $scope.fnGotoTaxList = (id, event) ->
    $state.go('tax', {taxId: id})
    event.stopPropagation()

  ###
  计算总价格
  ###
  $scope.fnTaxCount = ->
    if angular.isArray vm.taxList
      cost = 0
      (cost += parseFloat(tax.costAmount) for tax in vm.taxList)
      return cost
    else
      return 0

  ###
  税费提交
  ###
  $scope.fnAddTax = (data) ->
    data.costTime = $filter('date')(data.costTime, 'yyyy-MM-dd HH:mm:ss')
    data.costAmount = parseFloat data.costAmount
    if vm.costId?
      Order.modifyTax vm.costId, data
      .then ->
        $ionicHistory.goBack -1
      , (msg) ->
        return unless msg?
        $ionicPopup.alert
          title: msg
    else  
      Order.addTax vm.taxId, data
      .then ->
        $ionicHistory.goBack -1
      , (msg) ->
        return unless msg?
        $ionicPopup.alert
          title: msg


  $scope.fnGetLocation = ->
    Account.getLocation()
    .then (res) ->
      vm.locLo = res.lng
      vm.locLa = res.lat
      Map.geoCoder [vm.locLa, vm.locLo]
      .then (res) ->
        vm.location = res.sematic_description
    , (err) ->
      if vm.retryTime > 0
        vm.retryTime--;
        $scope.fnGetLocation()
      else
        vm.text = '无法获取事故地点,请手动填写'

  ###
  事故报警
  ###
  $scope.fnAlarm = () ->
    $ionicPopup.confirm
      title: '是否确认?'
    .then (flag) ->
      if flag
        data = 
          location: vm.location
          locLo: vm.locLo
          locLa: vm.locLa
          vehicleLic: vm.vehicleLic
          accidentDesc: vm.accidentDesc
          driverName: vm.account.realName
        Car.rescue data
        .then () ->
          $ionicPopup.alert
            title: '救援成功!'
        , (msg) ->
          $ionicPopup.alert
            title: msg


  return

.controller 'Driver.OrderCtrl', (
$scope
$state
$stateParams
$ionicLoading
$localStorage
$ionicPopup
Order
KEY_ACCOUNT
) ->
  vm = $scope.vm =
    id: $stateParams.id
    list: []
    order: {}
    account: $localStorage[KEY_ACCOUNT]

  $scope.fnGetList = ->
    $ionicLoading.show()
    Order.list()
    .then (res) ->
      vm.list = res.rows
      $ionicLoading.hide()
    .finally ()->
      $scope.$broadcast 'scroll.refreshComplete'
      $scope.$broadcast 'scroll.infiniteScrollComplete'

  $scope.fnDetail = (id) ->
    $ionicLoading.show()
    Order.detail id
    .then (data) ->
      vm.order = data
      $ionicLoading.hide()

  $scope.nameFilter = (list) ->
    res = []
    return [] unless angular.isArray list
    for item in list
      if item.driver is vm.account.realName
        res.push item

    return res

  ###
  开始发车
  ###
  $scope.fnBegining = (id) ->
    Order.begin id
    .then ->
      vm.order.status = 4
    , (msg) ->
      return unless msg?
      $ionicPopup.alert
        title: msg

  ###
  完成任务
  ###
  $scope.fnFinish = (id) ->
    $ionicPopup.confirm
      title: '完成任务',
      template: '是否确认完成任务'
    .then (res) ->
      if res
        Order.finish id
        .then ->
          $state.go 'mission'
        , (msg) ->
          return unless msg?
          $ionicPopup.alert
            title: msg

# 首页控制器
.controller 'User.HomeCtrl', (
$scope
$ionicPopup
$filter
$ionicLoading
$localStorage
$cordovaDatePicker
$cordovaGeolocation
$ionicHistory
$stateParams
Order
Map
) ->
  vm = $scope.vm =
    planStartTime: new Date()
    planEndTime: new Date()
    carList: $localStorage['selectedCar']

  $scope.today = new Date()


  validate = ->
    msg = '用车数量为空' unless vm.vehicleCount?
    msg = '用车结束时间未选择' unless vm.planEndTime?
    msg = '用车起始时间未选择' unless vm.planStartTime?
    msg = '上车地点为空' unless vm.planStartPlace?
    msg = '目的地为空' unless vm.planEndPlace?
    $ionicPopup.alert
      title: msg

  $scope.fnCreateOrder = () ->
    if vm.planEndPlace? and vm.planStartPlace? and vm.planStartTime? and vm.planEndTime?
      if vm.planStartTime.valueOf() > vm.planEndTime.valueOf()
        $ionicPopup.alert
          title: '开始时间不能大于结束时间'
        return
      $ionicLoading.show()
      data = angular.extend vm
      data.startLocLa = String vm.startLocLa if vm.startLocLa?
      data.startLocLo = String vm.startLocLo if vm.startLocLo
      data.endLocLa = String vm.endLocLa if vm.endLocLa
      data.endLocLo = String vm.endLocLo if vm.endLocLo
      data.vehicleCount = String vm.vehicleCount if vm.vehicleCount
      data.planStartTime = $filter('date')(vm.planStartTime, 'yyyy-MM-dd HH:mm:ss')
      data.planEndTime = $filter('date')(vm.planEndTime, 'yyyy-MM-dd HH:mm:ss')
      Order.create data
      .then () ->
        $ionicLoading.hide()
        $ionicPopup.alert
          title: '提交成功！'
        $scope.fnResetForm()
      , (msg) ->
        return unless msg?
        $ionicLoading.hide()
        $ionicPopup.alert
          title: msg
    else
      validate()

  ###
  重置表单
  ###
  $scope.fnResetForm = ->
    delete $localStorage['selectedPeople']
    delete $localStorage['selectedCar']
    delete vm.passengers
    delete vm.vehicleCount
    delete vm.description
    delete vm.planEndPlace
    delete vm.endLocLa
    delete vm.endLocLo

  $scope.fnSearch = ->
    return unless vm.searchText
    data =
      q: vm.searchText
    Map.suggestion data
    .then (res) ->
      vm.poiResults = res
      vm.errorText = null
    , (msg) ->
      return unless msg?
      vm.errorText = msg

  $scope.fnGetLocation = () ->
    planStartPlace = $localStorage['planStartPlace']
    planEndPlace = $localStorage['planEndPlace']
    if planStartPlace?
      vm.planStartPlace = planStartPlace.address
      vm.startLocLa = planStartPlace.lat
      vm.startLocLo = planStartPlace.lng
      delete $localStorage['planStartPlace']
    if planEndPlace?
      vm.planEndPlace = planEndPlace.address
      vm.endLocLa = planEndPlace.lat
      vm.endLocLo = planEndPlace.lng
      delete $localStorage['planEndPlace']

  $scope.fnResetCarList = ->
    delete $localStorage['selectedCar']
    vm.carList = $localStorage['selectedCar']
    vm.vehicleCount = vm.carList.length if angular.isArray vm.carList

  $scope.fnGetSelectedPeople = () ->
    list = $localStorage['selectedPeople']
    if angular.isArray(list) && list.length > 0
      vm.passengers = list
    else
      vm.passengers = []

  $scope.fnConfirm = ->
    if (!vm.lat || !vm.lng)
      $ionicPopup.alert
        title: '你还未选择地点'
    else
      $localStorage[$stateParams.from] = vm
      $ionicHistory.goBack()

  $scope.fnConfirm2 = (address) ->
    vm.address = address
    $localStorage[$stateParams.from] = vm
    $ionicHistory.goBack()

  $scope.$on '$ionicView.enter', ->
    $scope.fnGetLocation()
    $scope.fnGetSelectedPeople()
    vm.carList = $localStorage['selectedCar']
    vm.vehicleCount = vm.carList.length if angular.isArray vm.carList


# 选车控制器
.controller 'User.CarCtrl', (
$scope
Car
Account
$ionicPopup
$localStorage
$ionicLoading
) ->
  vm = $scope.vm =
    list: []
    pageStart: 1
    pageCount: 50
    search: ''
    hasMore: true
    location: null
    retryTime: 3

  $scope.fnGetLocation = ->
    if !vm.location
      Account.getLocation()
      .then (res) ->
        vm.location = res
      , (err) ->
        if vm.retryTime > 0
          vm.retryTime--;
          $scope.fnGetLocation()

  $scope.fnGetDistance = (location) ->
    if vm.location? and location?
      distance = Account.getDistance vm.location.lat, vm.location.lng, parseInt(location.la), parseInt(location.lo)
      return distance + 'km' if distance?



  $scope.fnGetList = (concat=false) ->
    $ionicLoading.show()
    vm.pageStart = 1 if concat is false
    data =
      pageCount: vm.pageCount
      pageStart: if concat is true then ++vm.pageStart else vm.pageStart
      matchLic: vm.search
      matchNick: vm.search
    Car.list data
    .then (res) ->
      $ionicLoading.hide()
      if concat is true
        vm.list = vm.list.concat res.rows
      else
        vm.list = res.rows
      if res.total < vm.pageCount then vm.hasMore = false else vm.hasMore = true
    , (msg) ->
      $ionicLoading.hide()
      vm.hasMore = false
      return unless msg?
      $ionicPopup.alert
        title: msg
    .finally ->
      $scope.$broadcast 'scroll.refreshComplete'
      $scope.$broadcast 'scroll.infiniteScrollComplete'

  ###
  选择车辆
  ###
  $scope.fnSelect = (car) ->
    # 判断是否已选
    if angular.isArray $localStorage['selectedCar']
      if obj = car.vehicleUid in $localStorage['selectedCar']
        $ionicPopup.alert
          title: '该车辆已选'
      else
        $localStorage['selectedCar'].push car.vehicleUid
    else
      $localStorage['selectedCar'] = [car.vehicleUid]

  $scope.fnIsChecked = (id) ->
    if $localStorage['selectedCar']?
      return obj = id in $localStorage['selectedCar']

# 选人控制器
.controller 'User.PeopleCtrl', (
$scope
$filter
$localStorage
$ionicLoading
$ionicPopup
$ionicModal
People
Account
) ->
  vm = $scope.vm =
    list: []
    tempList: $localStorage['peoples']
    pageStart: 1
    pageCount: 20
    hasMore: true
    search: ''

  $scope.fnGetList = (concat=false) ->
    $ionicLoading.show()
    vm.pageStart = 1 if concat is false
    data =
      pageCount: vm.pageCount
      pageStart: if concat is true then ++vm.pageStart else vm.pageStart
      realName: vm.search
    Account.userList data
    .then (res) ->
      $ionicLoading.hide()
      if concat is true
        vm.list = vm.list.concat res.rows
      else
        vm.list = res.rows
      if res.total < vm.pageCount then vm.hasMore = false else vm.hasMore = true
    , (msg) ->
      $ionicLoading.hide()
      vm.hasMore = false
      return unless msg?
      $ionicPopup.alert
        title: msg
    .finally ->
      $scope.$broadcast 'scroll.refreshComplete'
      $scope.$broadcast 'scroll.infiniteScrollComplete'

  $ionicModal.fromTemplateUrl 'people-modal.html',
    scope: $scope,
    animation: 'slide-in-up'
  .then (modal) ->
    vm.modal = modal

  $scope.fnOpenModal = ->
    vm.modal.show()

  $scope.fnCloseModal = ->
    vm.modal.hide()

  $scope.fnDelete = (item, index)->
    confirmPopup = $ionicPopup.confirm
     title: "是否删除 #{item.realName} 的信息?"
    confirmPopup.then (res) ->
     if res
       vm.tempList.splice index, 1

  $scope.fnAddPassenger = (form) ->
    $ionicLoading.show()
    if !vm.tempList or !angular.isArray vm.tempList
      vm.tempList = $localStorage['peoples'] = []
    vm.tempList.push angular.extend form,
      checked: true
    $ionicLoading.hide()
    vm.form = {}
    $scope.fnCloseModal()

  $scope.$watch 'vm.list', ->
    arr1 = $filter('filter')(vm.list, {checked: true})
    arr2 = $filter('filter')(vm.tempList or [], {checked: true})
    $localStorage['selectedPeople'] = arr1.concat arr2
    console.log $localStorage['selectedPeople']
  , true

  $scope.$watch 'vm.tempList', ->
    arr1 = $filter('filter')(vm.list, {checked: true})
    arr2 = $filter('filter')(vm.tempList or [], {checked: true})
    $localStorage['selectedPeople'] = arr1.concat arr2
    console.log $localStorage['selectedPeople']
  , true

# 用户订单列表控制器
.controller 'User.OrderCtrl', (
$scope
$ionicLoading
$ionicPopup
$ionicScrollDelegate
$localStorage
Order
KEY_ACCOUNT
) ->
  vm = $scope.vm =
    account: $localStorage[KEY_ACCOUNT]
    list: []
    tabs: [
      {
        id: 1,
        name: '审批中'
      },
      {
        id: 2,
        name: '已配车'
      },
      {
        id: 3,
        name: '在途'
      },
      {
        id: 4,
        name: '历史'
      }
    ]
    pageStart: 1
    pageCount: 50
    currentTab: 1
    hasMore: true

  getStatusArray = ->
    status = []
    switch vm.currentTab
      when 1 # 审批中
        status.push 1
        status.push 2
        # 非领导帐号则请求待配车数据
        # status.push 2 unless role = 'leader' in vm.account.roles
      when 2 then status.push 3 # 已配车
      when 3 then status.push 4 # 在途
      when 4 then status.push 5 # 历史
    return status.join ','

  $scope.fnChangeTab = (id) ->
    vm.currentTab = id
    $ionicScrollDelegate.scrollTop()
    $scope.fnGetList()

  $scope.fnIsLeader = ->
    role = 'leader' in vm.account.roles


  $scope.fnGetList = (concat=false) ->
    $ionicLoading.show()
    vm.pageStart = 1 if concat is false
    data =
      status: getStatusArray()
      pageStart: vm.pageStart
      pageCount: vm.pageCount
    Order.list data
    .then (res) ->
      $ionicLoading.hide()
      if concat is true
        vm.list = vm.list.concat res.rows
      else
        vm.list = res.rows
      if res.total < vm.pageCount then vm.hasMore = false else vm.hasMore = true
    , (msg) ->
      $ionicLoading.hide()
      vm.hasMore = false
      return unless msg?
      $ionicPopup.alert
        title: msg
    .finally ()->
      $scope.$broadcast 'scroll.refreshComplete'
      $scope.$broadcast 'scroll.infiniteScrollComplete'

  $scope.fnAgree = (item, event) ->
    Order.approve item.serialNum, '同意用车'
    .then ->
      $scope.fnGetList()
    , (msg) ->
      $ionicPopup.alert
        title: msg
    event.stopPropagation()

# 用户订单详情控制器
.controller 'User.OrderDetailCtrl', (
$scope
$stateParams
$ionicLoading
$ionicPopup
$localStorage
$ionicHistory
$ionicModal
Order
KEY_ACCOUNT
) ->
  vm = $scope.vm =
    id: $stateParams.id,
    order: {}
    account: $localStorage[KEY_ACCOUNT]

  $ionicModal.fromTemplateUrl 'feedback-modal.html',
    scope: $scope,
    animation: 'slide-in-up'
  .then (modal) ->
    vm.modal = modal

  $scope.fnIsLeader = ->
    role = 'leader' in vm.account.roles


  $scope.fnDetail = () ->
    $ionicLoading.show()
    Order.detail vm.id
    .then (data) ->
      vm.order = data
      $ionicLoading.hide()

  $scope.fnFeedback = (content) ->
    if content.trim()
      $ionicLoading.show()
      Order.feedback vm.id, {content: content}
      .then () ->
        $ionicLoading.hide()
        $scope.fnCloseModal()
        vm.order.isFeedback = 1

  $scope.fnOpenPopup = (type) ->
    if type is 'approve'
      vm.comment = '同意用车'
    else
      vm.comment = '拒绝用车'
    $ionicPopup.show
      template: '<input autofocus type="test" ng-model="vm.comment">'
      title: '审批意见'
      scope: $scope
      buttons: [
        {
          text: '确定'
          type: 'button-positive'
          onTap: ->
            return [type, vm.comment]
        }
        {
          text: '取消'
        }
      ]
    .then ([type, comment] = []) ->
      if type is 'approve'
        Order.approve vm.id, comment
        .then ->
          $scope.fnDetail()
        , (msg) ->
          return unless msg?
          $ionicPopup.alert
            title: msg
      else if type is 'reject'
        Order.reject vm.id, comment
        .then ->
          $scope.fnDetail()
        , (msg) ->
          return unless msg?
          $ionicPopup.alert
            title: msg

  $scope.fnApprove = ->
    $ionicLoading.show()
    Order.approve vm.id, vm.comment
    .then ->
      $ionicLoading.hide()
      $ionicHistory.goBack -1
    , (msg) ->
      $ionicLoading.hide()
      return unless msg?
      $ionicPopup.alert
        title: msg

  $scope.fnReject = ->
    $ionicLoading.show()
    Order.reject vm.id, vm.comment
    .then ->
      $ionicLoading.hide()
      $ionicHistory.goBack -1
    , (msg) ->
      $ionicLoading.hide()
      return unless msg?
      $ionicPopup.alert
        title: msg

  $scope.fnOpenModal = () ->
    vm.modal.show()

  $scope.fnCloseModal = () ->
    vm.modal.hide()

  # Cleanup the modal when we're done with it!
  $scope.$on '$destroy', () ->
    vm.modal.remove()

.controller 'ReportCtrl',
(
  $scope
  $state
  $stateParams
  $localStorage
  $ionicPopup
  $ionicLoading
  $filter
  Statistic
  KEY_ACCOUNT
) ->
  vm = $scope.vm = 
    user: $localStorage[KEY_ACCOUNT]
    date: new Date()
    labels:
      'c001': '  行驶里程（公里）'
      'c002': '总油耗（升）'
      'c004': '\t\t\t\t\t\t\t\t\t\t平均油耗（升/百公里）'
      'c003': '总油费（元）'
      'c005': '  用车时间（小时）'
      'c006': '车机拆除（次）'
      'c007': '怠速超长（次）'
      'c008': '越界（次）'
      'c009': '非调度用车（次）'
      'c010': '车辆违章（次）'
      'c011': '车辆超速（次）'
    type: $stateParams.type
  $scope.today = new Date()
  myChart = echarts.init(document.getElementById('main')) if document.getElementById('main')?
    
  # 刷新图表
  $scope.fnRefreshChart = (list, type="bar") ->
    # 基于准备好的dom，初始化echarts图表
    myChart.clear()
    values = []
    dates = []
    # for item in list
    #   #values
    #   values.push item['Y1']
    #   #date
    #   dates.push parseInt item['CREATE_DATE'].substr 8
    for num in [1..31]
      dates.push num
      if list[num - 1]? and num is parseInt list[num - 1]['CREATE_DATE'].substr 8
        if vm.type is 'c005'
          values.push list[num - 1]['Y1']/60
        else
          values.push list[num - 1]['Y1']
      else
        values.push 0
        # values.push parseInt Math.random() * 10
    option =
      # title:
      #   text: '日耗油费统计柱图'
      tooltip:
        show: false
        trigger: 'axis'
      toolbox:
        show : true
        y:'top'
        itemSize: 26
        feature: 
          magicType: 
            show: true
            type: ['line', 'bar']
      grid:
        x: 50
        x2: 50
        y: 40
      xAxis: 
        name: '日期(日)'
        data: dates
        axisLabel:
          interval: (index, val) ->
            return (index + 1) % 3 is 0
      yAxis:
        name: vm.labels[vm.type]
        type: 'value'
      series: [
        type: type
        data: values
      ]
    myChart.setOption option
  # 读取数据
  $scope.fnLoadData = ->
    console.log 'load data'
    $ionicLoading.show()
    startTime = angular.copy vm.date
    startTime.setDate 1
    endTime = angular.copy vm.date
    endTime.setMonth endTime.getMonth() + 1
    endTime.setDate 1
    endTime.setDate -1
    data =
      startDate: $filter('date')(startTime, 'yyyyMMdd')
      endDate: $filter('date')(endTime, 'yyyyMMdd')
      unitId: vm.user.dept.deptUid
      code: $stateParams.type
    Statistic.fuel data
    .then (res) ->
      $ionicLoading.hide()
      $scope.fnRefreshChart(res.rows)
      console.log res
    , (msg) ->
      $ionicLoading.hide()
      return unless msg?
      $ionicPopup.alert
        title: msg

  # 改变日期
  $scope.fnChangeDate = (flag) ->
    duration = 24*60*60*1000
    return if flag > 0 and vm.date.valueOf() > (new Date()).valueOf() - duration
    vm.date.setMonth vm.date.getMonth() + flag
    vm.dateInstance.setVal vm.date
  
  $scope.$watch 'vm.date', (val) ->
    if $state.is 'reportDtail'
      $scope.fnLoadData()
  ,true

