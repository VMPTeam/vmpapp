angular.module 'starter.services', []

.service 'ErrorHandle', ($state) ->
  handle = (status, res, defer) ->
    if status is 500
      defer.reject '服务器异常'
    else if status is 401
      $state.go 'login'
      defer.reject null
    else if status is 0 or status is 502
      defer.reject '连接服务器异常，请检查网络设置后重试。'
    else
      defer.reject (res && res.msg) || '未知错误:' + status

.service 'Account', (
$http
$q
$timeout
$localStorage
$filter
$cordovaGeolocation
md5
KEY_TOKEN
KEY_ACCOUNT
ErrorHandle
) ->
  # 权限列表
  roles = $localStorage[KEY_ACCOUNT].roles if $localStorage[KEY_ACCOUNT]?
  location = null

  ###
  获取权限列表
  ###
  this.roles = ->
    return roles

  this.permission = (role) ->
    if role is 'user'
      return true if roles.length == 1 and roles[0] == role
    else
      return permission = role in roles

  @.getLocation = () ->
    defer = $q.defer()
    if location?
      defer.resolve location
    else
      posOptions = {timeout: 10000, enableHighAccuracy: true};
      $cordovaGeolocation
        .getCurrentPosition (posOptions)
        .then (position) ->
          location = 
            lat: position.coords.latitude
            lng: position.coords.longitude
          defer.resolve location
        , (err) ->
          defer.reject err
    return defer.promise

  @.getDistance = (lat1, lng1, lat2, lng2) ->
    Rad = (d) ->
      d * Math.PI / 180.0
    radLat1 = Rad(lat1)
    radLat2 = Rad(lat2)
    a = radLat1 - radLat2
    b = Rad(lng1) - Rad(lng2)
    s = 2 * Math.asin(Math.sqrt(Math.pow(Math.sin(a/2),2) +
     Math.cos(radLat1)*Math.cos(radLat2)*Math.pow(Math.sin(b/2),2)))
    s = s *6378.137
    s = Math.round(s * 10000) / 10000
    s = s.toFixed(1)
    return s

  ###
  登录
  ###
  this.login = (username, password) ->
    defer = $q.defer()

    data =
      username: username
      password: md5.createHash password
      grant_type: 'password'

    config =
      headers:
        'Authorization': 'Basic d3R0ZWNoOnd0dGVjaFZNUA=='
        'X-Requested-With': 'Curl'
        'Content-Type': 'application/x-www-form-urlencoded'

    $http.post '/oauth/token', $.param(data), config
    .success (res) ->
      if res.ret
        defer.reject res.message
      else
        $localStorage[KEY_TOKEN] = res
        defer.resolve res
    .error (err, status) ->
      ErrorHandle(status, err, defer)

    return defer.promise

  ###
  退出登录
  ###
  this.logout = () ->
    defer = $q.defer()
    delete $localStorage[KEY_TOKEN]
    delete $localStorage[KEY_ACCOUNT]
    defer.resolve()
    return defer.promise

  ###
  获取用户信息
  ###
  this.userInfo = () ->
    defer = $q.defer()
    $http.get('/user/profile')
    .success (res) ->
      if res.ret
        defer.reject res.message
      else
        $localStorage[KEY_ACCOUNT] = res
        roles = res.roles
        defer.resolve res
    .error (err, status) ->
      ErrorHandle(status, err, defer)
    return defer.promise

  ###
  获取用户列表
  ###
  this.userList = (param) ->
    defer = $q.defer()
    $http.get '/user/list',
      params: param
    .success (res) ->
      if res.ret
        defer.reject res.message
      else
        defer.resolve res
    .error (err, status) ->
      ErrorHandle(status, err, defer)
    return defer.promise

  ###
  获取提醒设置列表
  ###
  this.reminderList = () ->
    defer = $q.defer()
    $http.get('/reminder/list')
    .success (res) ->
      if res.ret
        defer.reject res.message
      else
        defer.resolve res
    .error (err, status) ->
      ErrorHandle(status, err, defer)
    return defer.promise

  ###
  更新提醒
  ###
  this.updateReminder = (data) ->
    defer = $q.defer()
    $http.post '/reminder', data
    .success (res) ->
      if res.ret
        defer.reject res.message
      else
        defer.resolve res
    .error (err, status) ->
      ErrorHandle(status, err, defer)
    return defer.promise

  ###
  修改密码
  ###
  this.modifyPwd = (data) ->
    defer = $q.defer()
    data.cmd = 'set'
    $http.post('/user/profile', data)
    .success (res) ->
      if res.ret
        defer.reject res.message
      else
        defer.resolve res
    .error (err, status) ->
      ErrorHandle(status, err, defer)
    return defer.promise

  this.modifyMobile = (data) ->
    defer = $q.defer()
    return defer.promise

  # 获取企业号
  this.getCompany = (code) ->
    defer = $q.defer()

    $http.get '/organization/' + code
    .success (res) ->
      if res.ret then defer.reject res.message else defer.resolve res
    .error (err, status) ->
      ErrorHandle(status, err, defer)
    return defer.promise

  this.weather = (city) ->
    defer = $q.defer()

    $http.get '/weather',
      params:
        city: city
    .success (res) ->
      if res.ret then defer.reject res.message else defer.resolve res
    .error (err, status) ->
      ErrorHandle(status, err, defer)
    return defer.promise

  @.checkUpdate = ()->
    defer = $q.defer()
    $http.get '/android/version'
    .success (res) ->
      if res.ret then defer.reject res.message else defer.resolve res
    .error (err, status) ->
      ErrorHandle(status, err, defer)
    return defer.promise

  return

.service 'Car', ($http, $q, ErrorHandle) ->
  ###
  车辆列表
  ###
  this.list = (data) ->
    defer = $q.defer()

    $http.get '/vehicle/list',
      params: data
    .success (res) ->
      if res.ret
        defer.reject res.message
      else
        defer.resolve res
    .error (err, status) ->
      ErrorHandle(status, err, defer)
    return defer.promise

  ###
  车辆详情
  ###
  this.detail = (id) ->
    defer = $q.defer()

    $http.get '/vehicle/' + id
    .success (res) ->
      if res.ret
        defer.reject res.message
      else
        defer.resolve res
    .error (err, status) ->
      ErrorHandle(status, err, defer)

    return defer.promise

  ###
  行车记录
  ###
  this.journals = (id, data) ->
    defer = $q.defer()

    $http.get '/vehicle/' + id + '/journals',
      params: data
    .success (res) ->
      if res.ret
        defer.reject res.message
      else
        defer.resolve res
    .error (err, status) ->
      ErrorHandle(status, err, defer)

    return defer.promise

  ###
  车辆位置信息
  ###
  this.location = (id) ->
    defer = $q.defer()

    $http.get '/vehicle/' + id + '/currentLocation'
    .success (res) ->
      if res.ret
        defer.reject res.message
      else
        defer.resolve res
    .error (err, status) ->
      ErrorHandle(status, err, defer)

    return defer.promise

  ###
  历史记录
  ###
  this.park = (id) ->
    defer = $q.defer()

    $http.get '/vehicle/' + id + '/parking'
    .success (res) ->
      if res.ret
        defer.reject res.message
      else
        defer.resolve res
    .error (err, status) ->
      ErrorHandle(status, err, defer)

    return defer.promise

  ###
  应急救援
  ###
  this.rescue = (param) ->
    defer = $q.defer()

    $http.post '/vehicle/rescue', param
    .success (res) ->
      if res.ret
        defer.reject res.message
      else
        defer.resolve res
    .error (err, status) ->
      ErrorHandle(status, err, defer)

    return defer.promise


  return

.service 'Driver', ($http, $q, ErrorHandle) ->

  this.list = (data) ->
    defer = $q.defer()

    $http.get '/driver/list',
      params: data
    .success (res) ->
      if res.ret
        defer.reject res.message
      else
        defer.resolve res
    .error (err, status) ->
      ErrorHandle(status, err, defer)
    return defer.promise

  ###
  查看驾驶员详情
  ###
  this.detail = (id) ->
    defer = $q.defer()
    $http.get '/driver/' + id
    .success (res) ->
      if res.ret then defer.reject res.message else defer.resolve res
    .error (err, status) ->
      ErrorHandle(status, err, defer)

    return defer.promise

  return

.service 'People', ($http, $q, ErrorHandle) ->
  this.list = () ->
    defer = $q.defer()
    $http.get('/user/passenger/list')
    .success (res) ->
      if res.ret then defer.reject res.message else defer.resolve res
    .error (err, status) ->
      ErrorHandle(status, err, defer)

    return defer.promise
  return

.service 'Order', ($http, $q, ErrorHandle) ->
  ###
  获取订单列表
  ###
  this.list = (data) ->
    defer = $q.defer()
    $http.get '/order/list',
      params: data
    .success (res) ->
      if res.ret then defer.reject res.message else defer.resolve res
    .error (err, status) ->
      ErrorHandle(status, err, defer)
    return defer.promise

  ###
  查看订单详情
  ###
  this.detail = (id) ->
    defer = $q.defer()
    $http.post '/order/' + id,
      cmd: 'get'
    .success (res) ->
      if res.ret then defer.reject res.message else defer.resolve res
    .error (err, status) ->
      ErrorHandle(status, err, defer)

    return defer.promise


  ###
  创建订单
  ###
  this.create = (data) ->
    defer = $q.defer()

    $http.post '/order', data
    .success (res) ->
      if res.ret then defer.reject res.message else defer.resolve res
    .error (err, status) ->
      ErrorHandle(status, err, defer)

    return defer.promise

  ###
  开始发车
  ###
  this.begin = (id) ->
    defer = $q.defer()
    $http.post '/order/' + id, {cmd: 'begin'}
    .success (res) ->
      if res.ret then defer.reject res.message else defer.resolve res
    .error (err, status) ->
      ErrorHandle(status, err, defer)
    return defer.promise

  ###
  税费列表
  ###
  this.taxList = (id) ->
    defer = $q.defer()
    $http.get('/order/' + id + '/fund/list')
    .success (res) ->
      if res.ret then defer.reject res.message else defer.resolve res
    .error (err, status) ->
      ErrorHandle(status, err, defer)
    return defer.promise

  ###
  税费添加
  ###
  this.addTax = (id, data) ->
    defer = $q.defer()
    $http.post('/order/' + id + '/fund', data)
    .success (res) ->
      if res.ret then defer.reject res.message else defer.resolve res
    .error (err, status) ->
      ErrorHandle(status, err, defer)
    return defer.promise

  ###
  税费详情
  ###
  this.detailTax = (id, data) ->
    defer = $q.defer()
    $http.get('/fund/' + id)
    .success (res) ->
      if res.ret then defer.reject res.message else defer.resolve res
    .error (err, status) ->
      ErrorHandle(status, err, defer)
    return defer.promise

  ###
  税费修改
  ###
  this.modifyTax = (id, data) ->
    defer = $q.defer()
    $http.post('/fund/' + id, data)
    .success (res) ->
      if res.ret then defer.reject res.message else defer.resolve res
    .error (err, status) ->
      ErrorHandle(status, err, defer)
    return defer.promise

  ###
  分配车辆
  ###
  this.issue = (id, data) ->
    defer = $q.defer()
    $http.post '/order/' + id,
      cmd: 'issue'
      issueInfo: data
    .success (res) ->
      if res.ret then defer.reject res.message else defer.resolve res
    .error (err, status) ->
      ErrorHandle(status, err, defer)
    return defer.promise

  ###
  审批通过
  ###
  this.approve = (id, comment) ->
    defer = $q.defer()
    $http.post '/order/' + id,
      cmd: 'approve'
      comment: comment
    .success (res) ->
      if res.ret then defer.reject res.message else defer.resolve res
    .error (err, status) ->
      ErrorHandle(status, err, defer)
    return defer.promise

  ###
  审批不通过
  ###
  this.reject = (id, comment) ->
    defer = $q.defer()
    $http.post '/order/' + id,
      cmd: 'reject'
      comment: comment
    .success (res) ->
      if res.ret then defer.reject res.message else defer.resolve res
    .error (err, status) ->
      ErrorHandle(status, err, defer)
    return defer.promise

  ###
  订单反馈
  ###
  this.feedback = (id, data) ->
    defer = $q.defer()
    $http.post('/order/' + id + '/feedback', data)
    .success (res) ->
      defer.resolve(res)
    .error (err, status) ->
      ErrorHandle(status, err, defer)
    return defer.promise
  return

.service 'Area', ($http, $q, ErrorHandle) ->
  # 获取区域列表
  this.list = ->
    defer = $q.defer()

    $http.get '/area/list'
    .success (res) ->
      if res.ret then defer.reject res.message else defer.resolve res
    .error (err, status) ->
      ErrorHandle(status, err, defer)
    return defer.promise

  # 获取区域详情
  this.detail = (id) ->
    defer = $q.defer()
    $http.get '/area/' + id
    .success (res) ->
      if res.ret then defer.reject res.message else defer.resolve res
    .error (err, status) ->
      ErrorHandle(status, err, defer)
    return defer.promise

  # 删除区域详情
  this.remove = (id) ->
    defer = $q.defer()
    $http.post '/area/' + id + '/delete'
    .success (res) ->
      if res.ret then defer.reject res.message else defer.resolve res
    .error (err, status) ->
      ErrorHandle(status, err, defer)
    return defer.promise

  # 启用区域详情
  this.enable = (id) ->
    defer = $q.defer()
    $http.post '/area/' + id,
      status: 0
    .success (res) ->
      if res.ret then defer.reject res.message else defer.resolve res
    .error (err, status) ->
      ErrorHandle(status, err, defer)
    return defer.promise

  # 禁用区域详情
  this.disable = (id) ->
    defer = $q.defer()
    $http.post '/area/' + id,
      status: 1
    .success (res) ->
      if res.ret then defer.reject res.message else defer.resolve res
    .error (err, status) ->
      ErrorHandle(status, err, defer)
    return defer.promise

  # 创建区域
  this.create = (data) ->
    defer = $q.defer()
    $http.post '/area', data
    .success (res) ->
      if res.ret then defer.reject res.message else defer.resolve res
    .error (err, status) ->
      ErrorHandle(status, err, defer)
    return defer.promise


  # 保存区域
  this.save = (id, data) ->
    defer = $q.defer()
    $http.post '/area/' + id, data
    .success (res) ->
      if res.ret then defer.reject res.message else defer.resolve res
    .error (err, status) ->
      ErrorHandle(status, err, defer)
    return defer.promise


  return

.service 'Message', ($http, $q, ErrorHandle) ->
  # 获取消息数量
  @.count = ->
    defer = $q.defer()
    $http.get '/message/count'
    .success (res) ->
      if res.ret then defer.reject res.message else defer.resolve res
    .error (err, status) ->
      ErrorHandle(status, err, defer)
    return defer.promise

  # 获取消息列表
  @.list = (param) ->
    defer = $q.defer()
    $http.get '/message/list',
      params: param

    .success (res) ->
      if res.ret then defer.reject res.message else defer.resolve res
    .error (err, status) ->
      ErrorHandle(status, err, defer)
    return defer.promise

  # 获取消息
  @.detail = (id) ->
    defer = $q.defer()
    $http.get '/message/' + id
    .success (res) ->
      if res.ret then defer.reject res.message else defer.resolve res
    .error (err, status) ->
      ErrorHandle(status, err, defer)
    return defer.promise

  return

.service 'Statistic', ($http, $q, ErrorHandle) ->
  @.fuel = (data) ->
    defer = $q.defer()
    $http.get '/statistic/chart/single',
      params: data
    .success (res) ->
      if res.ret then defer.reject res.message else defer.resolve res
    .error (err, status) ->
      ErrorHandle(status, err, defer)
    return defer.promise



  return

.service 'Map', ($http, $q, ErrorHandle) ->

  this.geoCoder = (param) ->
    defer = $q.defer()
    url = 'http://api.map.baidu.com/geocoder/v2/'
    params =
      ak: 'C6941f690ce486f7b3a55371cb235d93'
      coordtype: 'wgs84ll'
      pois: 1
      output: 'json'
      callback: 'JSON_CALLBACK'
      location: param.join ','
    $http.jsonp url,
      params: params
    .success (res) ->
      if res.status is 0
        defer.resolve res.result
      else
        defer.reject '百度地图服务异常：' + res.status
    return defer.promise

  this.ip = ->
    defer = $q.defer()
    url = 'http://api.map.baidu.com/location/ip'
    $http.jsonp url,
      params:
        ak: 'C6941f690ce486f7b3a55371cb235d93'
        callback: 'JSON_CALLBACK'
    .success (res) ->
      if res.status is 0
        defer.resolve res
      else
        defer.reject '百度地图服务异常：' + res.status
    return defer.promise

  return
