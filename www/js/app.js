angular.module('starter', ['ionic', 'ngCordova', 'starter.controllers', 'starter.services', 'angular-md5', 'ngStorage']).constant('BASE_URL', '/Business').constant('CLIENT_TYPE', 'vehicle_manager').constant('KEY_COMPANY', 'VMP_COMPANY').constant('KEY_TOKEN', 'VMP_TOKEN').constant('KEY_ACCOUNT', 'VMP_ACCOUNT').constant('KEY_USERNAME', 'VMP_USERNAME').constant('KEY_PASSWORD', 'VMP_PASSWORD').run(function($rootScope, $ionicPlatform, $ionicScrollDelegate, $location, $localStorage, KEY_COMPANY, KEY_TOKEN) {
  var companyCode, oToken;
  oToken = $localStorage[KEY_TOKEN];
  companyCode = $localStorage[KEY_COMPANY];
  if (!companyCode) {
    $location.path('/company');
  } else if (!oToken || !oToken.access_token) {
    $location.path('/login');
  }
  $ionicPlatform.ready(function() {
    if (window.cordova && window.cordova.plugins && window.cordova.plugins.Keyboard) {
      cordova.plugins.Keyboard.hideKeyboardAccessoryBar(true);
    }
    if (window.StatusBar) {
      return StatusBar.styleLightContent();
    }
  });
  $rootScope.$on('$stateChangeStart', function(e, state) {
    if (state.name === 'tab.car') {
      $ionicScrollDelegate.freezeAllScrolls(true);
    } else {
      $ionicScrollDelegate.freezeAllScrolls(false);
    }
  });
}).factory('pathInterceptor', function(BASE_URL) {
  var interceptor;
  interceptor = {
    request: function(config) {
      var exp1, exp2;
      exp1 = !/.+(?=\.html$)/.test(config.url);
      exp2 = !/^(?=(http\:|https\:)).*/.test(config.url);
      if (exp1 && exp2) {
        config.url = BASE_URL + config.url;
        config.timeout = 10000;
      }
      return config;
    }
  };
  return interceptor;
}).factory('tokenInterceptor', function($q, $location, $localStorage, KEY_TOKEN) {
  var interceptor;
  interceptor = {
    request: function(config) {
      var access_token, oToken, token_type;
      oToken = $localStorage[KEY_TOKEN];
      token_type = oToken != null ? oToken.token_type : '';
      access_token = oToken != null ? oToken.access_token : '';
      if (oToken != null) {
        config.headers['Authorization'] = token_type + access_token;
      }
      return config;
    },
    responseError: function(rejection) {
      switch (rejection.status) {
        case 401:
          delete $localStorage[KEY_TOKEN];
          $location.url('/login');
      }
      return $q.reject(rejection);
    }
  };
  return interceptor;
}).factory('logInterceptor', function($q, $log) {
  var interceptor;
  interceptor = {
    request: function(config) {
      if (!/.+(?=\.html$)/.test(config.url)) {
        $log.debug('开始请求接口.接口地址=' + config.url + '; 请求参数=' + angular.toJson(config.data));
      }
      return config;
    },
    response: function(response) {
      if (!/.+(?=\.html$)/.test(response.config.url)) {
        $log.debug('接口请求成功.接口地址=' + response.config.url + '; 返回结果=' + angular.toJson(response.data));
      }
      return response;
    },
    responseError: function(rejection) {
      if (!/.+(?=\.html$)/.test(rejection.config.url)) {
        $log.debug('接口请求失败.接口地址=' + rejection.config.url);
      }
      return $q.reject(rejection);
    }
  };
  return interceptor;
}).config(function($stateProvider, $urlRouterProvider, $ionicConfigProvider, $httpProvider) {
  var fnTransParam;
  $ionicConfigProvider.views.transition('none');
  $ionicConfigProvider.tabs.position('bottom');
  $ionicConfigProvider.navBar.alignTitle('center');
  $stateProvider.state('tab', {
    url: "",
    abstract: true,
    templateUrl: "templates/tabs.html"
  }).state('tab.allot', {
    url: '/allots',
    views: {
      'tab-allot': {
        templateUrl: 'templates/allot.html',
        controller: 'AllotCtrl'
      }
    }
  }).state('tab.car', {
    url: '/car',
    views: {
      'tab-car': {
        templateUrl: 'templates/tab-car.html',
        controller: 'CarCtrl'
      }
    }
  }).state('tab.report', {
    url: '/reports',
    views: {
      'tab-report': {
        templateUrl: 'templates/tab-report.html'
      }
    }
  }).state('tab.driver', {
    url: '/driver',
    views: {
      'tab-driver': {
        templateUrl: 'templates/tab-driver.html',
        controller: 'DriverCtrl'
      }
    }
  }).state('tab.account', {
    url: '/account',
    views: {
      'tab-account': {
        templateUrl: 'templates/account.html',
        controller: 'AccountCtrl'
      }
    }
  }).state('password', {
    url: '/password',
    templateUrl: 'templates/setting-password.html',
    controller: 'AccountCtrl'
  }).state('msg-list', {
    url: '/setting/msgs',
    templateUrl: 'templates/setting-message.html',
    controller: 'AccountCtrl'
  }).state('login', {
    url: '/login',
    templateUrl: 'templates/login.html',
    controller: 'AccountCtrl'
  }).state('company', {
    url: '/company',
    templateUrl: 'templates/setting-company.html',
    controller: 'AccountCtrl'
  }).state('allotDetail', {
    url: '/allot/:id',
    templateUrl: 'templates/allot-detail.html',
    controller: 'AllotDetailCtrl'
  }).state('cars', {
    url: 'cars/:oid?startTime&endTime',
    templateUrl: 'templates/car-list.html',
    controller: 'AllotDetailCtrl'
  }).state('drivers', {
    url: 'drivers/:oid?startTime&endTime',
    templateUrl: 'templates/driver-list.html',
    controller: 'AllotDetailCtrl'
  }).state('carInfo', {
    url: '/carinfo/:id?type',
    templateUrl: 'templates/car-info.html',
    controller: 'CarInfoCtrl'
  }).state('areaList', {
    url: '/areas',
    templateUrl: 'templates/area-list.html',
    controller: 'AreaCtrl'
  }).state('area', {
    url: '/area',
    templateUrl: 'templates/area-form.html',
    controller: 'AreaCtrl'
  }).state('areaEdit', {
    url: '/area/:id',
    templateUrl: 'templates/area-form.html',
    controller: 'AreaCtrl'
  }).state('areaMap', {
    url: '/areamap',
    templateUrl: 'templates/area-map.html',
    controller: 'AreaCtrl'
  }).state('areaCar', {
    url: '/areacar',
    templateUrl: 'templates/area-carlist.html',
    controller: 'AreaCtrl'
  });
  $urlRouterProvider.otherwise('/');
  $httpProvider.interceptors.push('pathInterceptor');
  $httpProvider.interceptors.push('tokenInterceptor');
  $httpProvider.interceptors.push('logInterceptor');
  fnTransParam = function(data, headersGetter) {
    var ct;
    ct = headersGetter()['Content-Type'];
    if (ct && ct.match('application/x-www-form-urlencoded')) {
      if (angular.isObject(data) && String(data) !== '[object File]') {
        return $.param(data);
      } else {
        return data;
      }
    } else {
      return angular.toJson(data);
    }
  };
});
