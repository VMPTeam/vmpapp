var indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

angular.module('starter.services', []).service('ErrorHandle', function($rootScope) {
  var handle;
  return handle = function(status, res, defer) {
    if (status === 500) {
      return defer.reject('服务器异常');
    } else if (status === 401) {
      $rootScope.fnReLogin();
      return defer.reject('服务器异常');
    } else if (status === 0) {
      return defer.reject('服务器无响应');
    } else {
      return defer.reject(res.msg || '未知错误:' + status);
    }
  };
}).service('Account', function($http, $q, $timeout, $localStorage, $filter, md5, KEY_TOKEN, KEY_ACCOUNT, ErrorHandle) {
  var roles;
  if ($localStorage[KEY_ACCOUNT] != null) {
    roles = $localStorage[KEY_ACCOUNT].roles;
  }

  /*
  获取权限列表
   */
  this.roles = function() {
    return roles;
  };
  this.permission = function(role) {
    var permission;
    if (role === 'user') {
      if (roles.length === 1 && roles[0] === role) {
        return true;
      }
    } else {
      return permission = indexOf.call(roles, role) >= 0;
    }
  };

  /*
  登录
   */
  this.login = function(username, password) {
    var config, data, defer;
    defer = $q.defer();
    data = {
      username: username,
      password: md5.createHash(password),
      grant_type: 'password'
    };
    config = {
      headers: {
        'Authorization': 'Basic d3R0ZWNoOnd0dGVjaFZNUA==',
        'X-Requested-With': 'Curl',
        'Content-Type': 'application/x-www-form-urlencoded'
      }
    };
    $http.post('/oauth/token', $.param(data), config).success(function(res) {
      if (res.ret) {
        return defer.reject(res.message);
      } else {
        $localStorage[KEY_TOKEN] = res;
        return defer.resolve(res);
      }
    }).error(function(err, status) {
      return ErrorHandle(status, err, defer);
    });
    return defer.promise;
  };

  /*
  退出登录
   */
  this.logout = function() {
    var defer;
    defer = $q.defer();
    delete $localStorage[KEY_TOKEN];
    delete $localStorage[KEY_ACCOUNT];
    defer.resolve();
    return defer.promise;
  };

  /*
  获取用户信息
   */
  this.userInfo = function() {
    var defer;
    defer = $q.defer();
    $http.get('/user/profile').success(function(res) {
      if (res.ret) {
        return defer.reject(res.message);
      } else {
        $localStorage[KEY_ACCOUNT] = res;
        roles = res.roles;
        return defer.resolve(res);
      }
    }).error(function(err, status) {
      return ErrorHandle(status, err, defer);
    });
    return defer.promise;
  };

  /*
  获取提醒设置列表
   */
  this.reminderList = function() {
    var defer;
    defer = $q.defer();
    $http.get('/reminder/list').success(function(res) {
      if (res.ret) {
        return defer.reject(res.message);
      } else {
        return defer.resolve(res);
      }
    }).error(function(err, status) {
      return ErrorHandle(status, err, defer);
    });
    return defer.promise;
  };

  /*
  更新提醒
   */
  this.updateReminder = function(data) {
    var defer;
    defer = $q.defer();
    $http.post('/reminder', data).success(function(res) {
      if (res.ret) {
        return defer.reject(res.message);
      } else {
        return defer.resolve(res);
      }
    }).error(function(err, status) {
      return ErrorHandle(status, err, defer);
    });
    return defer.promise;
  };

  /*
  修改密码
   */
  this.modifyPwd = function(data) {
    var defer;
    defer = $q.defer();
    data.cmd = 'set';
    $http.post('/user/profile', data).success(function(res) {
      if (res.ret) {
        return defer.reject(res.message);
      } else {
        return defer.resolve(res);
      }
    }).error(function(err, status) {
      return ErrorHandle(status, err, defer);
    });
    return defer.promise;
  };
  this.modifyMobile = function(data) {
    var defer;
    defer = $q.defer();
    return defer.promise;
  };
  this.getCompany = function(code) {
    var defer;
    defer = $q.defer();
    $http.get('/organization/' + code).success(function(res) {
      if (res.ret) {
        return defer.reject(res.message);
      } else {
        return defer.resolve(res);
      }
    }).error(function(err, status) {
      return ErrorHandle(status, err, defer);
    });
    return defer.promise;
  };
  this.weather = function(city) {
    var defer;
    defer = $q.defer();
    $http.get('/weather', {
      params: {
        city: city
      }
    }).success(function(res) {
      if (res.ret) {
        return defer.reject(res.message);
      } else {
        return defer.resolve(res);
      }
    }).error(function(err, status) {
      return ErrorHandle(status, err, defer);
    });
    return defer.promise;
  };
}).service('Car', function($http, $q, ErrorHandle) {

  /*
  车辆列表
   */
  this.list = function(data) {
    var defer;
    defer = $q.defer();
    $http.get('/vehicle/list', {
      params: data
    }).success(function(res) {
      if (res.ret) {
        return defer.reject(res.message);
      } else {
        return defer.resolve(res);
      }
    }).error(function(err, status) {
      return ErrorHandle(status, err, defer);
    });
    return defer.promise;
  };

  /*
  车辆详情
   */
  this.detail = function(id) {
    var defer;
    defer = $q.defer();
    $http.get('/vehicle/' + id).success(function(res) {
      if (res.ret) {
        return defer.reject(res.message);
      } else {
        return defer.resolve(res);
      }
    }).error(function(err, status) {
      return ErrorHandle(status, err, defer);
    });
    return defer.promise;
  };

  /*
  行车记录
   */
  this.journals = function(id, data) {
    var defer;
    defer = $q.defer();
    $http.get('/vehicle/' + id + '/journals', {
      params: data
    }).success(function(res) {
      if (res.ret) {
        return defer.reject(res.message);
      } else {
        return defer.resolve(res);
      }
    }).error(function(err, status) {
      return ErrorHandle(status, err, defer);
    });
    return defer.promise;
  };

  /*
  车辆位置信息
   */
  this.location = function(id) {
    var defer;
    defer = $q.defer();
    $http.get('/vehicle/' + id + '/currentLocation').success(function(res) {
      if (res.ret) {
        return defer.reject(res.message);
      } else {
        return defer.resolve(res);
      }
    }).error(function(err, status) {
      return ErrorHandle(status, err, defer);
    });
    return defer.promise;
  };

  /*
  历史记录
   */
  this.park = function(id) {
    var defer;
    defer = $q.defer();
    $http.get('/vehicle/' + id + '/parking').success(function(res) {
      if (res.ret) {
        return defer.reject(res.message);
      } else {
        return defer.resolve(res);
      }
    }).error(function(err, status) {
      return ErrorHandle(status, err, defer);
    });
    return defer.promise;
  };
}).service('Driver', function($http, $q, ErrorHandle) {
  this.list = function(data) {
    var defer;
    defer = $q.defer();
    $http.get('/driver/list', {
      params: data
    }).success(function(res) {
      if (res.ret) {
        return defer.reject(res.message);
      } else {
        return defer.resolve(res);
      }
    }).error(function(err, status) {
      return ErrorHandle(status, err, defer);
    });
    return defer.promise;
  };

  /*
  查看驾驶员详情
   */
  this.detail = function(id) {
    var defer;
    defer = $q.defer();
    $http.get('/driver/' + id).success(function(res) {
      if (res.ret) {
        return defer.reject(res.message);
      } else {
        return defer.resolve(res);
      }
    }).error(function(err, status) {
      return ErrorHandle(status, err, defer);
    });
    return defer.promise;
  };
}).service('People', function($http, $q, ErrorHandle) {
  this.list = function() {
    var defer;
    defer = $q.defer();
    $http.get('/user/passenger/list').success(function(res) {
      if (res.ret) {
        return defer.reject(res.message);
      } else {
        return defer.resolve(res);
      }
    }).error(function(err, status) {
      return ErrorHandle(status, err, defer);
    });
    return defer.promise;
  };
}).service('Order', function($http, $q, ErrorHandle) {

  /*
  获取订单列表
   */
  this.list = function(data) {
    var defer;
    defer = $q.defer();
    $http.get('/order/list', {
      params: data
    }).success(function(res) {
      if (res.ret) {
        return defer.reject(res.message);
      } else {
        return defer.resolve(res);
      }
    }).error(function(err, status) {
      return ErrorHandle(status, err, defer);
    });
    return defer.promise;
  };

  /*
  查看订单详情
   */
  this.detail = function(id) {
    var defer;
    defer = $q.defer();
    $http.post('/order/' + id, {
      cmd: 'get'
    }).success(function(res) {
      if (res.ret) {
        return defer.reject(res.message);
      } else {
        return defer.resolve(res);
      }
    }).error(function(err, status) {
      return ErrorHandle(status, err, defer);
    });
    return defer.promise;
  };

  /*
  创建订单
   */
  this.create = function(data) {
    var defer;
    defer = $q.defer();
    $http.post('/order', data).success(function(res) {
      if (res.ret) {
        return defer.reject(res.message);
      } else {
        return defer.resolve(res);
      }
    }).error(function(err, status) {
      return ErrorHandle(status, err, defer);
    });
    return defer.promise;
  };

  /*
  开始发车
   */
  this.begin = function(id) {
    var defer;
    defer = $q.defer();
    $http.post('/order/' + id, {
      cmd: 'begin'
    }).success(function(res) {
      if (res.ret) {
        return defer.reject(res.message);
      } else {
        return defer.resolve(res);
      }
    }).error(function(err, status) {
      return ErrorHandle(status, err, defer);
    });
    return defer.promise;
  };

  /*
  税费列表
   */
  this.taxList = function(id) {
    var defer;
    defer = $q.defer();
    $http.get('/order/' + id(+'/fund/list')).success(function(res) {
      if (res.ret) {
        return defer.reject(res.message);
      } else {
        return defer.resolve(res);
      }
    }).error(function(err, status) {
      return ErrorHandle(status, err, defer);
    });
    return defer.promise;
  };

  /*
  分配车辆
   */
  this.issue = function(id, data) {
    var defer;
    defer = $q.defer();
    $http.post('/order/' + id, {
      cmd: 'issue',
      issueInfo: data
    }).success(function(res) {
      if (res.ret) {
        return defer.reject(res.message);
      } else {
        return defer.resolve(res);
      }
    }).error(function(err, status) {
      return ErrorHandle(status, err, defer);
    });
    return defer.promise;
  };

  /*
  审批通过
   */
  this.approve = function(id, comment) {
    var defer;
    defer = $q.defer();
    $http.post('/order/' + id, {
      cmd: 'approve',
      comment: comment
    }).success(function(res) {
      if (res.ret) {
        return defer.reject(res.message);
      } else {
        return defer.resolve(res);
      }
    }).error(function(err, status) {
      return ErrorHandle(status, err, defer);
    });
    return defer.promise;
  };

  /*
  审批不通过
   */
  this.reject = function(id, comment) {
    var defer;
    defer = $q.defer();
    $http.post('/order/' + id, {
      cmd: 'reject',
      comment: comment
    }).success(function(res) {
      if (res.ret) {
        return defer.reject(res.message);
      } else {
        return defer.resolve(res);
      }
    }).error(function(err, status) {
      return ErrorHandle(status, err, defer);
    });
    return defer.promise;
  };

  /*
  订单反馈
   */
  this.feedback = function(id, data) {
    var defer;
    defer = $q.defer();
    $http.post('/order/' + id + '/feedback', data).success(function(res) {
      return defer.resolve(res);
    }).error(function(err, status) {
      return ErrorHandle(status, err, defer);
    });
    return defer.promise;
  };
}).service('Area', function($http, $q, ErrorHandle) {
  this.list = function() {
    var defer;
    defer = $q.defer();
    $http.get('/area/list').success(function(res) {
      if (res.ret) {
        return defer.reject(res.message);
      } else {
        return defer.resolve(res);
      }
    }).error(function(err, status) {
      return ErrorHandle(status, err, defer);
    });
    return defer.promise;
  };
  this.detail = function(id) {
    var defer;
    defer = $q.defer();
    $http.get('/area' + id).success(function(res) {
      if (res.ret) {
        return defer.reject(res.message);
      } else {
        return defer.resolve(res);
      }
    }).error(function(err, status) {
      return ErrorHandle(status, err, defer);
    });
    return defer.promise;
  };
  this.create = function(data) {
    var defer;
    defer = $q.defer();
    $http.post('/area', data).success(function(res) {
      if (res.ret) {
        return defer.reject(res.message);
      } else {
        return defer.resolve(res);
      }
    }).error(function(err, status) {
      return ErrorHandle(status, err, defer);
    });
    return defer.promise;
  };
  this.save = function(id, data) {
    var defer;
    defer = $q.defer();
    $http.post('/area/' + id, data).success(function(res) {
      if (res.ret) {
        return defer.reject(res.message);
      } else {
        return defer.resolve(res);
      }
    }).error(function(err, status) {
      return ErrorHandle(status, err, defer);
    });
    return defer.promise;
  };
}).service('Map', function($http, $q, ErrorHandle) {
  this.geoCoder = function(param) {
    var defer, params, url;
    defer = $q.defer();
    url = 'http://api.map.baidu.com/geocoder/v2/';
    params = {
      ak: 'C6941f690ce486f7b3a55371cb235d93',
      coordtype: 'wgs84ll',
      pois: 1,
      output: 'json',
      callback: 'JSON_CALLBACK',
      location: param.join(',')
    };
    $http.jsonp(url, {
      params: params
    }).success(function(res) {
      if (res.status === 0) {
        return defer.resolve(res.result);
      } else {
        return defer.reject('百度地图服务异常：' + res.status);
      }
    });
    return defer.promise;
  };
  this.ip = function() {
    var defer, url;
    defer = $q.defer();
    url = 'http://api.map.baidu.com/location/ip';
    $http.jsonp(url, {
      params: {
        ak: 'C6941f690ce486f7b3a55371cb235d93',
        callback: 'JSON_CALLBACK'
      }
    }).success(function(res) {
      if (res.status === 0) {
        return defer.resolve(res);
      } else {
        return defer.reject('百度地图服务异常：' + res.status);
      }
    });
    return defer.promise;
  };
});
