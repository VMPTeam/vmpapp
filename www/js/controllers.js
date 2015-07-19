var indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

angular.module('starter.controllers', []).controller('AllotCtrl', function($scope, $state, $ionicPopup, $filter, $ionicLoading, $localStorage, $cordovaGeolocation, Order) {
  var vm;
  vm = $scope.vm = {
    list: [],
    pageStart: 1,
    pageCount: 10,
    hasMore: true
  };

  /*
  获取任务订单
   */
  return $scope.fnGetList = function(concat) {
    if (concat == null) {
      concat = false;
    }
    $ionicLoading.show();
    return Order.list({
      status: [2],
      pageStart: 1,
      pageCount: 10
    }).then(function(res) {
      $ionicLoading.hide();
      if (concat === true) {
        vm.list = vm.list.concat(res.rows);
      } else {
        vm.list = res.rows;
      }
      if (res.total < vm.pageCount) {
        return vm.hasMore = false;
      } else {
        return vm.hasMore = true;
      }
    }, function(msg) {
      $ionicLoading.hide();
      vm.hasMore = false;
      return $ionicPopup.alert({
        title: msg
      });
    })["finally"](function() {
      $scope.$broadcast('scroll.refreshComplete');
      return $scope.$broadcast('scroll.infiniteScrollComplete');
    });
  };
}).controller('CarCtrl', function($scope, $state, $stateParams, $timeout, $filter, $http, Car, Map, $ionicPopup, $localStorage, $ionicLoading, $ionicScrollDelegate) {
  var _CarMap, _lastInfoWindow, _markerClusterer, vm;
  vm = $scope.vm = {
    list: [],
    pageStart: 1,
    pageCount: 10,
    search: '',
    hasMore: true,
    order: $localStorage[$stateParams.oid],
    startTime: $stateParams.startTime,
    endTime: $stateParams.endTime,
    mapView: true,
    selectedCar: null
  };
  _CarMap = null;
  _markerClusterer = null;
  _lastInfoWindow = null;

  /*
  获取车辆列表
   */
  $scope.fnGetCarList = function(concat) {
    var data;
    if (concat == null) {
      concat = false;
    }
    $ionicLoading.show();
    if (concat === true) {
      vm.pageStart = 1;
    }
    data = {
      pageCount: vm.pageCount,
      pageStart: concat === true ? ++vm.pageStart : vm.pageStart,
      matchLic: vm.search,
      matchNick: vm.search
    };
    return Car.list(data).then(function(res) {
      $ionicLoading.hide();
      if (concat === true) {
        vm.list = vm.list.concat(res.rows);
      } else {
        vm.list = res.rows;
      }
      if (res.total < vm.pageCount) {
        return vm.hasMore = false;
      } else {
        return vm.hasMore = true;
      }
    }, function(msg) {
      $ionicLoading.hide();
      vm.hasMore = false;
      return $ionicPopup.alert({
        title: msg
      });
    })["finally"](function() {
      $scope.$broadcast('scroll.refreshComplete');
      return $scope.$broadcast('scroll.infiniteScrollComplete');
    });
  };

  /*
  改变视图
   */
  $scope.fnChangeView = function() {
    return vm.mapView = !vm.mapView;
  };

  /*
  初始化地图
   */
  $scope.fnInitMap = function() {
    _CarMap = new BMap.Map('carMap');
    _CarMap.centerAndZoom('合肥', 12);
    _CarMap.addControl(new BMap.NavigationControl({
      anchor: BMAP_ANCHOR_TOP_RIGHT,
      type: BMAP_NAVIGATION_CONTROL_ZOOM
    }));
    _CarMap.addControl(new BMap.ScaleControl({
      anchor: BMAP_ANCHOR_BOTTOM_LEFT
    }));
    return $timeout(function() {
      return $scope.fnRefreshMarker(vm.list);
    }, 1000);
  };

  /*
  刷新地图点
   */
  $scope.fnRefreshMarker = function(list) {
    var item, marker, markers, points;
    if (list.length > 0 && (_CarMap != null)) {
      markers = (function() {
        var j, len, results;
        results = [];
        for (j = 0, len = list.length; j < len; j++) {
          item = list[j];
          if (item.location != null) {
            results.push($scope.fnCreateMarker(item));
          }
        }
        return results;
      })();
      points = (function() {
        var j, len, results;
        results = [];
        for (j = 0, len = markers.length; j < len; j++) {
          marker = markers[j];
          results.push(marker.getPosition());
        }
        return results;
      })();
      _CarMap.setViewport(points);
      if (_markerClusterer != null) {
        _markerClusterer.clearMarkers();
        return _markerClusterer.addMarkers(markers);
      } else {
        return _markerClusterer = new BMapLib.MarkerClusterer(_CarMap, {
          markers: markers
        });
      }
    } else {
      return $timeout(function() {
        return $scope.fnRefreshMarker(vm.list);
      }, 1000);
    }
  };

  /*
  创建标注点
   */
  $scope.fnCreateMarker = function(data) {
    var icon, location, marker, point, status;
    location = data.location || {};
    status = location.status || 0;
    point = new BMap.Point(location.lo, location.la);
    icon = new BMap.Icon('img/car' + status + '.png', new BMap.Size(18, 38));
    marker = new BMap.Marker(point, {
      icon: icon,
      rotation: location.dir || parseInt(Math.random() * 360)
    });
    marker.vehicleUid = data.vehicleUid;
    marker.addEventListener('click', function() {
      var id;
      _CarMap.panTo(marker.getPosition(), {
        noAnimation: true
      });
      $timeout(function() {
        var close;
        close = function() {
          _CarMap.removeEventListener('movestart', close);
          return $timeout(function() {
            return delete vm.selectedCar;
          });
        };
        return _CarMap.addEventListener('movestart', close);
      }, 500);
      id = this.vehicleUid;
      return $scope.$apply(function() {
        return $scope.fnSelectCar(id);
      });
    });
    return marker;
  };

  /*
  展示信息窗口
   */
  $scope.fnOpenInfoBox = function(marker, content) {
    var data, dom, infoBoxConfig;
    if (content == null) {
      content = '';
    }
    dom = $('<div>').html(content);
    dom.children('.info').attr('id', marker.vehicleUid);
    data = $filter('filter')(vm.list, {
      vehicleUid: marker.vehicleUid
    })[0];
    dom.find('[data-driverName]').text(data.driverName);
    dom.find('[data-driverPhone]').text(data.driverPhone).attr('src', 'tel:' + data.driverPhone);
    dom.find('[data-vehicleLic]').text(data.vehicleLic);
    dom.find('[data-buShortName]').text(data.buShortName);
    dom.find('[data-updateTime]').text($filter('date')(data.location.updateTime, 'yyyy-MM-dd HH:mm:ss'));
    Map.geoCoder([data.location.la, data.location.lo]).then(function(res) {
      return $('#' + marker.vehicleUid + ' [data-address]').text(res.sematic_description);
    });
    infoBoxConfig = {
      offset: new BMap.Size(0, 20),
      boxClass: 'custom-info-box',
      closeIconUrl: 'img/close(1).png',
      align: INFOBOX_AT_TOP
    };
    _lastInfoWindow = infoWindow;
    return infoWindow.open(marker);
  };

  /*
  选择车辆
   */
  $scope.fnSelectCar = function(id) {
    vm.selectedCar = $filter('filter')(vm.list, {
      vehicleUid: id
    })[0];
    if (vm.selectedCar != null) {
      return Map.geoCoder([vm.selectedCar.location.la, vm.selectedCar.location.lo]).then(function(res) {
        return vm.selectedCar.address = res.sematic_description;
      });
    }
  };
  return $scope.$watch('vm.mapView', function(val) {
    return $ionicScrollDelegate.freezeAllScrolls(val);
  });
}).controller('DriverCtrl', function($scope, $state, $stateParams, Driver, $ionicPopup, $localStorage, $ionicLoading) {
  var vm;
  vm = $scope.vm = {
    list: [],
    pageStart: 1,
    pageCount: 10,
    search: '',
    hasMore: true
  };
  return $scope.fnGetList = function(concat) {
    var data;
    if (concat == null) {
      concat = false;
    }
    $ionicLoading.show();
    if (concat === true) {
      vm.pageStart = 1;
    }
    data = {
      pageCount: vm.pageCount,
      pageStart: concat === true ? ++vm.pageStart : vm.pageStart,
      matchName: vm.search,
      matchStaffId: vm.search
    };
    return Driver.list(data).then(function(res) {
      $ionicLoading.hide();
      if (concat === true) {
        vm.list = vm.list.concat(res.rows);
      } else {
        vm.list = res.rows;
      }
      if (res.total < vm.pageCount) {
        return vm.hasMore = false;
      } else {
        return vm.hasMore = true;
      }
    }, function(msg) {
      $ionicLoading.hide();
      vm.hasMore = false;
      return $ionicPopup.alert({
        title: msg
      });
    })["finally"](function() {
      $scope.$broadcast('scroll.refreshComplete');
      return $scope.$broadcast('scroll.infiniteScrollComplete');
    });
  };
}).controller('AccountCtrl', function($scope, $state, $ionicLoading, $ionicPopup, $localStorage, $cordovaGeolocation, Account, KEY_COMPANY, KEY_TOKEN, KEY_USERNAME, KEY_PASSWORD, KEY_ACCOUNT, CLIENT_TYPE) {
  var vm;
  vm = $scope.vm = {
    username: $localStorage[KEY_USERNAME],
    password: $localStorage[KEY_PASSWORD],
    companyInfo: $localStorage[KEY_COMPANY],
    account: $localStorage[KEY_ACCOUNT],
    reminderList: []
  };
  $scope.fnSetCompanyCode = function(code) {
    $ionicLoading.show({
      template: '正在设置,请稍后'
    });
    return Account.getCompany(code).then(function(data) {
      $ionicLoading.hide();
      $localStorage[KEY_COMPANY] = data;
      return $state.go('login');
    }, function(msg) {
      $ionicLoading.hide();
      return $ionicPopup.alert({
        title: msg
      });
    });
  };
  $scope.fnLogin = function(username, password) {
    if (!username || !password) {
      $ionicPopup.alert({
        title: '请填写用户名和密码'
      });
      return;
    }
    $ionicLoading.show({
      template: '正在登录...',
      hideOnStateChange: true
    });
    return Account.login(username, password).then(function() {
      return Account.userInfo();
    }).then(function(res) {
      $ionicLoading.hide();
      $localStorage[KEY_USERNAME] = username;
      $localStorage[KEY_PASSWORD] = password;
      vm.userInfo = res;
      if (Account.permission('vehicle_manager')) {
        return $state.go('allot');
      } else if (Account.permission('driver')) {
        return $state.go('mission');
      }
    }, function(msg) {
      delete $localStorage[KEY_TOKEN];
      $ionicLoading.hide();
      return $ionicPopup.alert({
        title: msg
      });
    });
  };
  $scope.fnLogout = function() {
    return Account.logout().then(function() {
      return $state.go('login');
    });
  };
  $scope.fnGetReminderList = function() {
    return Account.reminderList().then(function(res) {
      return vm.reminderList = res.rows;
    }, function(msg) {
      return $ionicPopup.alert({
        title: msg
      });
    });
  };
  $scope.fnUpdateReminder = function(item) {
    return Account.updateReminder(item)["catch"](function() {
      $ionicPopup.alert({
        title: '请检查你的网络'
      });
      return item.checked = !item.checked;
    });
  };
  return $scope.fnMofidyPwd = function(oldPwd, newPwd, confirmPwd) {
    var data;
    if (newPwd === confirmPwd) {
      data = {
        oldPassword: oldPwd,
        password: newPwd
      };
      return Account.modifyPwd(data).then(function() {
        return $ionicPopup.alert({
          title: '密码已修改'
        });
      }, function(msg) {
        return $ionicPopup.alert({
          title: msg
        });
      });
    } else {
      return $ionicPopup.alert({
        title: '两次密码输入不一致'
      });
    }
  };
}).controller('AllotDetailCtrl', function($scope, $state, $stateParams, $ionicLoading, $ionicPopup, $localStorage, $ionicModal, Order, Car, Driver, KEY_ACCOUNT) {
  var vm;
  vm = $scope.vm = {
    id: $stateParams.id,
    nextId: '',
    list: [],
    pageStart: 1,
    pageCount: 10,
    search: '',
    orderList: [],
    order: {},
    subOrder: $localStorage[$stateParams.oid],
    account: $localStorage[KEY_ACCOUNT],
    tabs: [
      {
        id: 1,
        name: '审批中'
      }, {
        id: 2,
        name: '已配车'
      }, {
        id: 3,
        name: '在途'
      }, {
        id: 4,
        name: '历史'
      }
    ],
    currentTab: $stateParams.id,
    startTime: $stateParams.startTime,
    endTime: $stateParams.endTime
  };

  /*
  获取订单列表
   */
  $scope.fnGetOrderList = function() {
    return Order.list({
      status: [2]
    }).then(function(res) {
      vm.orderList = res.rows;
      return vm.nextId = $scope.fnGetNextId(res.rows);
    }, function(msg) {
      return $ionicPopup.alert({
        title: msg
      });
    });
  };

  /*
  获取下个订单号
   */
  $scope.fnGetNextId = function(list) {
    var i, j, len, order;
    for (i = j = 0, len = list.length; j < len; i = ++j) {
      order = list[i];
      if (order.serialNum === vm.id) {
        if (vm.orderList[i + 1] != null) {
          return vm.orderList[i + 1].serialNum;
        } else {
          return;
        }
      }
    }
  };

  /*
  获取订单详情
   */
  $scope.fnDetail = function() {
    $ionicLoading.show();
    return Order.detail(vm.id).then(function(data) {
      $scope.fnRefreshCarList(data.driverAndVehicle);
      vm.order = data;
      return $ionicLoading.hide();
    }, function(msg) {
      $ionicLoading.hide();
      return $ionicPopup.alert({
        title: msg
      });
    });
  };

  /*
  提交并处理下一条
   */
  $scope.fnCommit = function() {
    var j, len, order, ref;
    ref = vm.order.driverAndVehicle;
    for (j = 0, len = ref.length; j < len; j++) {
      order = ref[j];
      if (!order.vehicleUid || !order.userUid) {
        $ionicPopup.alert({
          title: '请先分配车辆和驾驶员'
        });
        return;
      }
    }
    $ionicLoading.show();
    return Order.issue(vm.id, vm.order.driverAndVehicle).then(function() {
      $ionicLoading.hide();
      return $ionicPopup.alert({
        title: '分配成功'
      }).then(function() {
        if (vm.nextId) {
          return $scope.fnChangeTab(vm.nextId);
        } else {
          return $state.go('tab.allot');
        }
      });
    }, function(msg) {
      $ionicLoading.hide();
      return $ionicPopup.alert({
        title: msg
      });
    });
  };

  /*
  切换tab
   */
  $scope.fnChangeTab = function(id) {
    return $state.go('allotDetail', {
      id: id
    });
  };

  /*
  进入车辆挑选列表
   */
  $scope.fnGotoCarList = function(list) {
    var j, len, order, results;
    results = [];
    for (j = 0, len = list.length; j < len; j++) {
      order = list[j];
      if (!order.vehicleUid) {
        $localStorage[order.orderUid] = angular.extend(order, {
          serialNum: vm.id
        });
        $state.go('cars', {
          oid: order.orderUid,
          startTime: vm.order.planStartTime,
          endTime: vm.order.planEndTime
        });
        break;
      } else {
        results.push(void 0);
      }
    }
    return results;
  };

  /*
  获取车辆列表
   */
  $scope.fnGetCarList = function(concat) {
    var data;
    if (concat == null) {
      concat = false;
    }
    $ionicLoading.show();
    if (concat === true) {
      vm.pageStart = 1;
    }
    data = {
      pageCount: vm.pageCount,
      pageStart: concat === true ? ++vm.pageStart : vm.pageStart,
      status: 5,
      startTime: vm.startTime + ':00',
      endTime: vm.endTime + ':00',
      matchLic: vm.search,
      matchNick: vm.search
    };
    return Car.list(data).then(function(res) {
      $ionicLoading.hide();
      if (concat === true) {
        vm.list = vm.list.concat(res.rows);
      } else {
        vm.list = res.rows;
      }
      if (res.total < vm.pageCount) {
        return vm.hasMore = false;
      } else {
        return vm.hasMore = true;
      }
    }, function(msg) {
      $ionicLoading.hide();
      vm.hasMore = false;
      return $ionicPopup.alert({
        title: msg
      });
    })["finally"](function() {
      $scope.$broadcast('scroll.refreshComplete');
      return $scope.$broadcast('scroll.infiniteScrollComplete');
    });
  };

  /*
  选择车辆
   */
  $scope.fnSelectCar = function(car) {
    angular.extend($localStorage[$stateParams.oid], car);
    return $state.go('drivers', {
      oid: $stateParams.oid,
      startTime: vm.startTime,
      endTime: vm.endTime
    });
  };

  /*
  检查是否还有未分配订单
   */
  $scope.fnCheckEmptyOrder = function() {
    var j, len, order, ref;
    if (vm.order.driverAndVehicle == null) {
      return false;
    }
    ref = vm.order.driverAndVehicle;
    for (j = 0, len = ref.length; j < len; j++) {
      order = ref[j];
      if (!order.vehicleUid || !order.userUid) {
        return true;
      }
    }
  };

  /*
  清除订单信息
   */
  $scope.fnClearOrder = function(order, event) {
    delete order.vehicleUid;
    return event.stopPropagation();
  };

  /*
  进入驾驶员列表
   */
  $scope.fnGotoDriverList = function(order) {
    return $state.go('drivers', {
      oid: order.orderUid,
      startTime: vm.order.planStartTime,
      endTime: vm.order.planEndTime
    });
  };
  $scope.fnGetDriverList = function(concat) {
    var data;
    if (concat == null) {
      concat = false;
    }
    $ionicLoading.show();
    if (concat === true) {
      vm.pageStart = 1;
    }
    data = {
      pageCount: vm.pageCount,
      pageStart: concat === true ? ++vm.pageStart : vm.pageStart,
      status: 1,
      startTime: vm.startTime + ':00',
      endTime: vm.endTime + ':00',
      matchName: vm.search,
      matchStaffId: vm.search
    };
    return Driver.list(data).then(function(res) {
      $ionicLoading.hide();
      if (concat === true) {
        vm.list = vm.list.concat(res.rows);
      } else {
        vm.list = res.rows;
      }
      if (res.total < vm.pageCount) {
        return vm.hasMore = false;
      } else {
        return vm.hasMore = true;
      }
    }, function(msg) {
      $ionicLoading.hide();
      vm.hasMore = false;
      return $ionicPopup.alert({
        title: msg
      });
    })["finally"](function() {
      $scope.$broadcast('scroll.refreshComplete');
      return $scope.$broadcast('scroll.infiniteScrollComplete');
    });
  };

  /*
  选择驾驶员
   */
  $scope.fnSelectDriver = function(driver) {
    angular.extend($localStorage[$stateParams.oid], driver);
    return $state.go('allotDetail', {
      id: vm.subOrder.serialNum
    });
  };

  /*
  刷新分配车辆信息
   */
  return $scope.fnRefreshCarList = function(list) {
    var j, len, order, results;
    results = [];
    for (j = 0, len = list.length; j < len; j++) {
      order = list[j];
      results.push(angular.extend(order, $localStorage[order.orderUid]));
    }
    return results;
  };
}).controller('CarInfoCtrl', function($scope, $state, $stateParams, $timeout, $filter, $interval, $ionicLoading, $ionicPopup, $cordovaDatePicker, $ionicScrollDelegate, $localStorage, $ionicModal, Car, Map) {
  var _carMarker, _parkMap, _traceMap, vm;
  vm = $scope.vm = {
    id: $stateParams.id,
    tabList: ['车辆档案', '行车记录', '车辆跟踪', '车辆状况', '停车分布'],
    info: {},
    journals: {},
    today: new Date(),
    beginTime: new Date(),
    endTime: new Date(),
    currentLocation: {}
  };
  _traceMap = null;
  _carMarker = null;
  _parkMap = null;
  $scope.fnInitTab = function() {
    if ($stateParams.type != null) {
      return vm.tab = vm.tabList[$stateParams.type - 1];
    } else {
      return vm.tab = vm.tabList[0];
    }
  };
  $scope.fnOpenPicker = function(val, mode) {
    if (mode == null) {
      mode = 'date';
    }
    $cordovaDatePicker.show({
      mode: mode,
      date: vm.today,
      maxDate: new Date(),
      allowFutureDates: false,
      doneButtonLabel: '确定',
      cancelButtonLabel: '取消'
    }).then(function(date) {
      if (date != null) {
        return vm.today = date;
      }
    });
  };
  $scope.fnGetCarDetail = function() {
    return Car.detail(vm.id).then(function(res) {
      vm.info = res;
      return vm.currentLocation = res.location || {};
    }, function(msg) {
      return $ionicPopup.alert({
        title: msg
      });
    });
  };
  $scope.fnToggleLocationTimer = function(flag) {
    if (flag == null) {
      flag = false;
    }
    $interval.cancel(vm.locationTimer);
    if (flag === true) {
      return vm.locationTimer = $interval(function() {
        return Car.location(vm.id).then(function(res) {
          vm.currentLocation = res;
          if (vm.tab === '车辆跟踪') {
            $scope.fnRefreshMarker(vm.currentLocation);
          }
          if (vm.tab === '车辆状况') {
            $scope.fnRefreshDashboard(vm.currentLocation);
          }
          if (vm.tab === '停车分布') {
            return $scope.fnInitPark(vm.currentLocation);
          }
        });
      }, 30000);
    }
  };
  $scope.fnRefreshMarker = function(location) {
    var icon, point;
    point = new BMap.Point(location.lo, location.la);
    if (!_carMarker) {
      _carMarker = new BMap.Marker(point);
      _traceMap.addOverlay(_carMarker);
      _traceMap.setViewport([point]);
    }
    _carMarker.setPosition(point);
    icon = new BMap.Icon('img/car' + (location.status || 0) + '.png', new BMap.Size(18, 38));
    _carMarker.setIcon(icon);
    _carMarker.setRotation(location.dir || parseInt(Math.random() * 360));
    return _traceMap.panTo(point);
  };
  $scope.fnRefreshDashboard = function(location) {
    var rpm, rpmAngle, rpmMaxAngle, rpmStartAngle, speed, speedAngle, speedMaxAngle, speedStartAngle, voltage, voltageAngle, voltageMaxAngle, voltageStartAngle;
    speedMaxAngle = 210;
    speedStartAngle = -105;
    speed = parseFloat(location.speed) || 0;
    speedAngle = (speedMaxAngle / 240 * speed) + speedStartAngle;
    $('#speed').css({
      'transform': 'rotateZ(' + speedAngle + 'deg)'
    });
    voltageMaxAngle = 116;
    voltageStartAngle = -58;
    voltage = parseFloat(location.voltage) || 0;
    voltageAngle = (voltageMaxAngle / 27 * voltage) + voltageStartAngle;
    $('#voltage').css({
      'transform': 'rotateZ(' + voltageAngle + 'deg)'
    });
    rpmMaxAngle = 116;
    rpmStartAngle = -58;
    rpm = parseFloat(location.rpm) || 0;
    rpmAngle = (rpmMaxAngle / 10000 * rpm) + rpmStartAngle;
    return $('#rpm').css({
      'transform': 'rotateZ(' + rpmAngle + 'deg)'
    });
  };
  $scope.fnInitTrace = function() {
    _traceMap = new BMap.Map('traceMap');
    _traceMap.centerAndZoom('合肥', 10);
    _traceMap.addControl(new BMap.NavigationControl({
      anchor: BMAP_ANCHOR_BOTTOM_RIGHT,
      type: BMAP_NAVIGATION_CONTROL_ZOOM
    }));
    _traceMap.addControl(new BMap.ScaleControl({
      anchor: BMAP_ANCHOR_BOTTOM_LEFT
    }));
    return $timeout(function() {
      if (vm.currentLocation != null) {
        return $scope.fnRefreshMarker(vm.currentLocation);
      }
    }, 2000);
  };
  $scope.fnInitPark = function() {
    var currentPoint, item, j, len, marker, points, ref, results;
    if (!_parkMap) {
      _parkMap = new BMap.Map('parkMap');
      _parkMap.centerAndZoom('合肥', 10);
      _parkMap.addControl(new BMap.NavigationControl({
        anchor: BMAP_ANCHOR_BOTTOM_RIGHT,
        type: BMAP_NAVIGATION_CONTROL_ZOOM
      }));
      _parkMap.addControl(new BMap.ScaleControl({
        anchor: BMAP_ANCHOR_BOTTOM_LEFT
      }));
    } else {
      _parkMap.clearOverlays();
    }
    points = (function() {
      var j, len, ref, results;
      ref = vm.parks;
      results = [];
      for (j = 0, len = ref.length; j < len; j++) {
        item = ref[j];
        results.push(item.point);
      }
      return results;
    })();
    if ((vm.currentLocation.lo != null) && (vm.currentLocation.la != null)) {
      currentPoint = new BMap.Point(vm.currentLocation.lo, vm.currentLocation.la);
      marker = new BMap.Marker(currentPoint, {
        icon: new BMap.Icon('img/car3.png', new BMap.Size(18, 38)),
        rotation: vm.currentLocation.dir || parseInt(Math.random() * 360)
      });
      points.push(currentPoint);
      _parkMap.addOverlay(marker);
    }
    _parkMap.setViewport(points);
    ref = vm.parks;
    results = [];
    for (j = 0, len = ref.length; j < len; j++) {
      item = ref[j];
      results.push(_parkMap.addOverlay($scope.fnCreateLabelMarker(item.point)));
    }
    return results;
  };
  $scope.fnCreateLabelMarker = function(point) {
    var geoc, marker;
    marker = new BMap.Marker(point);
    geoc = new BMap.Geocoder();
    geoc.getLocation(point, function(rs) {
      var addComp, bArr, business, label, pois, text;
      pois = rs.surroundingPois;
      business = rs.business;
      if ((pois != null) && pois.length > 0) {
        text = pois[0].title;
      } else if (business) {
        bArr = business.split(',');
        text = bArr[0];
      } else {
        addComp = rs.addressComponents;
        text = addComp.province + addComp.city + addComp.district + addComp.street + addComp.streetNumber;
      }
      label = new BMap.Label(text, {
        offset: new BMap.Size(20, -10)
      });
      return marker.setLabel(label);
    });
    return marker;
  };
  $scope.fnGetPark = function() {
    var getPoint;
    getPoint = function(item) {
      item.point = new BMap.Point(item.lo, item.la);
      return item;
    };
    return Car.park(vm.id).then(function(res) {
      var item;
      vm.parks = (function() {
        var j, len, ref, results;
        ref = res.rows;
        results = [];
        for (j = 0, len = ref.length; j < len; j++) {
          item = ref[j];
          results.push(getPoint(item));
        }
        return results;
      })();
      return $scope.fnInitPark(vm.parks);
    }, function(msg) {
      return $ionicPopup.alert({
        title: msg
      });
    });
  };
  $scope.fnGetJournals = function() {
    var data;
    data = {
      day: $filter('date')(vm.today, 'yyyy-MM-dd')
    };
    return Car.journals(vm.id, data).then(function(res) {
      vm.journals = res.rows;
      return $scope.fnGeoCoder(vm.journals);
    }, function(msg) {
      return $ionicPopup.alert({
        title: msg
      });
    });
  };
  $scope.fnGeoCoder = function(list) {
    return angular.forEach(list, function(item) {
      Map.geoCoder([item.startLoc.locLa, item.startLoc.locLo]).then(function(res) {
        return angular.extend(item.startLoc, res);
      });
      return Map.geoCoder([item.endLoc.locLa, item.endLoc.locLo]).then(function(res) {
        return angular.extend(item.endLoc, res);
      });
    });
  };
  $scope.fnDateLenth = function(time) {
    var date3, days, hours, leave1, leave2, minutes;
    date3 = parseInt(time * 1000);
    days = Math.floor(date3 / (24 * 3600 * 1000));
    leave1 = date3 % (24 * 3600 * 1000);
    hours = Math.floor(leave1 / (3600 * 1000));
    leave2 = leave1 % (3600 * 1000);
    minutes = Math.floor(leave2 / (60 * 1000));
    if (days > 0) {
      return days + '天' + hours + '小时';
    } else if (hours > 0) {
      return hours + '小时' + minutes + '分钟';
    } else {
      return minutes + '分钟';
    }
  };
  $scope.fnGetFuel = function() {
    var item, j, len, ref, result;
    result = 0;
    ref = vm.journals;
    for (j = 0, len = ref.length; j < len; j++) {
      item = ref[j];
      result += parseFloat(item.fuel);
    }
    return result;
  };
  $scope.fnGetMile = function() {
    var item, j, len, ref, result;
    result = 0;
    ref = vm.journals;
    for (j = 0, len = ref.length; j < len; j++) {
      item = ref[j];
      result += parseFloat(item.miles);
    }
    return result;
  };
  $scope.fnGetAvgFuel = function() {
    var fuel, item, j, len, mile, ref;
    fuel = 0;
    mile = 0;
    ref = vm.journals;
    for (j = 0, len = ref.length; j < len; j++) {
      item = ref[j];
      fuel += parseFloat(item.fuel);
      mile += parseFloat(item.miles);
    }
    return (fuel / mile) * 100;
  };
  $scope.fnOtherDay = function(date, day) {
    var d;
    d = new Date(date.valueOf());
    d.setDate(d.getDate() + day);
    return d;
  };
  $scope.fnSetDay = function(date, day) {
    return vm.today.setDate(date.getDate() + day);
  };
  $scope.$watch('vm.today', function() {
    if (vm.tab === '行车记录') {
      return $scope.fnGetJournals();
    }
  }, true);
  return $scope.$watch('vm.tab', function(val) {
    $ionicScrollDelegate.freezeAllScrolls(false);
    $scope.fnToggleLocationTimer(false);
    switch (val) {
      case '车辆跟踪':
        vm.mapView = true;
        $scope.fnInitTrace();
        $scope.fnToggleLocationTimer(true);
        return $ionicScrollDelegate.freezeAllScrolls(true);
      case '车辆状况':
        $scope.fnRefreshDashboard(vm.currentLocation);
        $scope.fnToggleLocationTimer(true);
        return $ionicScrollDelegate.freezeAllScrolls(true);
      case '行车记录':
        return $scope.fnGetJournals();
      case '停车分布':
        vm.mapView = true;
        $scope.fnGetPark();
        $scope.fnToggleLocationTimer(true);
        return $ionicScrollDelegate.freezeAllScrolls(true);
    }
  });
}).controller('AreaCtrl', function($scope, $state, $stateParams, $timeout, $filter, $ionicActionSheet, $ionicHistory, $ionicLoading, $ionicPopup, $localStorage, Area, Car) {
  var _areaMap, vm;
  vm = $scope.vm = {
    list: [],
    carList: [],
    id: $stateParams.id,
    formData: {
      type: 0,
      points: [],
      trigger: 0,
      startTime: new Date(),
      endTime: new Date(),
      vehicles: []
    }
  };
  _areaMap = null;
  $scope.fnOpenPicker = function(attr) {
    $cordovaDatePicker.show({
      mode: 'time',
      date: vm.formData[attr],
      doneButtonLabel: '确定',
      cancelButtonLabel: '取消'
    }).then(function(date) {
      if (date != null) {
        return vm.formData[attr] = date;
      }
    });
  };
  $scope.fnGetList = function() {
    $ionicLoading.show();
    return Area.list().then(function(res) {
      $ionicLoading.hide();
      return vm.list = res.rows;
    }, function(msg) {
      $ionicLoading.hide();
      return $ionicPopup.alert({
        title: msg
      });
    });
  };
  $scope.fnGetCarList = function() {
    $ionicLoading.show();
    return Car.list({
      pageCount: 20000
    }).then(function(res) {
      var item, j, len, ref, ref1, results;
      $ionicLoading.hide();
      vm.carList = res.rows;
      ref = vm.carList;
      results = [];
      for (j = 0, len = ref.length; j < len; j++) {
        item = ref[j];
        if ((ref1 = item.vehicleUid, indexOf.call($localStorage['AREA_CARS'], ref1) >= 0)) {
          results.push(item.checked = true);
        } else {
          results.push(void 0);
        }
      }
      return results;
    }, function(msg) {
      $ionicLoading.hide();
      return $ionicPopup.alert({
        title: msg
      });
    });
  };
  $scope.fnSaveCheckCar = function() {
    var item, selectedCar;
    selectedCar = $filter('filter')(vm.carList, {
      checked: true
    });
    $localStorage['AREA_CARS'] = (function() {
      var j, len, results;
      results = [];
      for (j = 0, len = selectedCar.length; j < len; j++) {
        item = selectedCar[j];
        results.push(item.vehicleUid);
      }
      return results;
    })();
    return $ionicHistory.goBack(-1);
  };
  $scope.fnDetail = function() {
    if (vm.id != null) {
      return Area.detail(vm.id).then(function(res) {
        return angular.extend(vm.formData, res);
      }, function(msg) {
        return $ionicPopup.alert({
          title: msg
        });
      });
    }
  };
  $scope.fnShowSheet = function(item) {
    var hideSheet;
    return hideSheet = $ionicActionSheet.show({
      buttons: [
        {
          text: '查看详情'
        }, {
          text: '开启'
        }, {
          text: '关闭'
        }
      ],
      cancelText: '取消',
      destructiveText: '删除',
      buttonClicked: function() {
        return true;
      },
      destructiveButtonClicked: function() {
        return true;
      }
    });
  };
  $scope.fnInitMap = function() {
    var areaControl;
    _areaMap = new BMap.Map('areaMap');
    _areaMap.centerAndZoom('合肥', 14);
    _areaMap.addControl(new BMap.NavigationControl());
    _areaMap.addControl(new BMap.ScaleControl());
    areaControl = function() {
      var lineWidth, x, y;
      lineWidth = window.innerWidth / 2;
      x = (window.innerWidth - lineWidth) / 2;
      y = (window.innerHeight - lineWidth) / 2;
      this.defaultAnchor = BMAP_ANCHOR_TOP_LEFT;
      this.defaultOffset = new BMap.Size(x, y);
    };
    areaControl.prototype = new BMap.Control();
    areaControl.prototype.initialize = function(map) {
      var div, lineWidth;
      div = document.createElement('div');
      lineWidth = window.innerWidth / 2;
      div.style.width = lineWidth + 'px';
      div.style.height = lineWidth + 'px';
      div.style.border = '2px solid rgb(23,121,253)';
      div.style.backgroundColor = "rgba(0,0,0,.4)";
      map.getContainer().appendChild(div);
      return div;
    };
    return _areaMap.addControl(new areaControl());
  };
  $scope.fnGetPoints = function() {
    var points;
    points = $localStorage['AREA_POINTS'] || [];
    if (points.length > 0) {
      vm.formData.points = points;
    }
    return points;
  };
  $scope.fnGetSelectedCar = function() {
    var cars;
    cars = $localStorage['AREA_CARS'] || [];
    if (cars.length > 0) {
      vm.formData.vehicles = cars;
    }
    return cars;
  };
  $scope.fnGetBounds = function() {
    var item, lb, lineWidth, lt, pointArray, pointFormat, rb, rt;
    pointArray = [];
    pointFormat = function(point) {
      var data;
      return data = {
        lo: point.lng,
        la: point.lat
      };
    };
    lineWidth = window.innerWidth / 2;
    lt = new BMap.Pixel((window.innerWidth - lineWidth) / 2, (window.innerHeight - lineWidth) / 2);
    pointArray.push(_areaMap.pixelToPoint(lt));
    rt = new BMap.Pixel((window.innerWidth + lineWidth) / 2, (window.innerHeight - lineWidth) / 2);
    pointArray.push(_areaMap.pixelToPoint(rt));
    rb = new BMap.Pixel((window.innerWidth + lineWidth) / 2, (window.innerHeight + lineWidth) / 2);
    pointArray.push(_areaMap.pixelToPoint(rb));
    lb = new BMap.Pixel((window.innerWidth - lineWidth) / 2, (window.innerHeight + lineWidth) / 2);
    pointArray.push(_areaMap.pixelToPoint());
    $localStorage['AREA_POINTS'] = (function() {
      var j, len, results;
      results = [];
      for (j = 0, len = pointArray.length; j < len; j++) {
        item = pointArray[j];
        results.push(pointFormat(item));
      }
      return results;
    })();
    return $ionicHistory.goBack(-1);
  };
  return $scope.fnCreate = function() {
    var data;
    $ionicLoading.show();
    data = angular.copy(vm.formData);
    data.startTime = $filter('date')(data.startTime, 'HH:mm');
    data.endTime = $filter('date')(data.endTime, 'HH:mm');
    return Area.create(data).then(function() {
      $ionicLoading.hide();
      return $state.go('areaList');
    }, function(msg) {
      $ionicLoading.hide();
      return $ionicPopup.alert({
        title: msg
      });
    });
  };
}).controller('MissionCtrl', function($scope, $state, $stateParams, $filter, $ionicLoading, $ionicPopup, Order) {
  var vm;
  vm = $scope.vm = {
    current: null,
    list: [],
    isBegin: false,
    taxId: $stateParams.taxId,
    tax: {
      costTime: new Date()
    }
  };
  $scope.fnConcatPeople = function(list) {
    var _arr, people;
    if (!angular.isArray(list)) {
      return '';
    }
    _arr = (function() {
      var j, len, results;
      results = [];
      for (j = 0, len = list.length; j < len; j++) {
        people = list[j];
        results.push(people.name);
      }
      return results;
    })();
    return _arr.join(',');
  };

  /*
  拼接车牌号
   */
  $scope.fnConcatVehicleLic = function(list) {
    var vehicle, vehicleLicArray;
    if (angular.isArray(list)) {
      vehicleLicArray = (function() {
        var j, len, results;
        results = [];
        for (j = 0, len = list.length; j < len; j++) {
          vehicle = list[j];
          results.push(vehicle.vehicleLic);
        }
        return results;
      })();
      return vehicleLicArray.join(',');
    }
  };

  /*
  获取任务订单
   */
  $scope.fnGetList = function() {
    $ionicLoading.show();
    return Order.list({
      status: [3, 4].join(',')
    }).then(function(res) {
      vm.list = res.rows;
      vm.current = vm.list.shift();
      return $ionicLoading.hide();
    }, function(msg) {
      $ionicLoading.hide();
      return $ionicPopup.alert({
        title: msg
      });
    })["finally"](function() {
      $scope.$broadcast('scroll.refreshComplete');
      return $scope.$broadcast('scroll.infiniteScrollComplete');
    });
  };

  /*
  开始发车
   */
  $scope.fnBegining = function(id, event) {
    Order.begin(id).then(function() {
      return vm.current.status = 4;
    }, function(msg) {
      return $ionicPopup.alert({
        title: msg
      });
    });
    return event.stopPropagation();
  };

  /*
  完成任务
   */
  $scope.fnFinish = function(id, event) {
    Order.finish(id).then(function() {
      return $scope.fnGetList();
    }, function(msg) {
      return $ionicPopup.alert({
        title: msg
      });
    });
    return event.stopPropagation();
  };

  /*
  查询税费列表
   */
  $scope.fnGetTaxList = function() {
    return Order.taxList(vm.taxId).then(function(res) {
      return vm.taxList = res.rows;
    }, function(msg) {
      return $ionicPopup.alert({
        title: msg
      });
    });
  };

  /*
  打开税费管理列表
   */
  $scope.fnGotoTaxList = function(id, event) {
    $state.go('tax', {
      taxId: id
    });
    return event.stopPropagation();
  };

  /*
  计算总价格
   */
  $scope.fnTaxCount = function() {
    var cost, j, len, ref, tax;
    if (angular.isArray(vm.taxList)) {
      cost = 0;
      ref = vm.taxList;
      for (j = 0, len = ref.length; j < len; j++) {
        tax = ref[j];
        cost += parseFloat(tax.costAmount);
      }
      return cost;
    } else {
      return 0;
    }
  };

  /*
  税费提交
   */
  $scope.fnAddTax = function(data) {
    data.costTime = $filter('date')(data.costTime, 'yyyy-MM-dd HH:mm:ss');
    return Order.addTax(vm.taxId, data).then(function() {
      return $ionicPopup.alert({
        title: '税费提交成功'
      });
    }, function(msg) {
      return $ionicPopup.alert({
        title: msg
      });
    });
  };

  /*
  事故报警
   */
  $scope.fnAlarm = function() {
    return $ionicPopup.alert({
      title: '事故报警成功'
    });
  };
}).controller('Driver.OrderCtrl', function($scope, $state, $stateParams, $ionicLoading, $localStorage, $ionicPopup, Order, KEY_ACCOUNT) {
  var vm;
  vm = $scope.vm = {
    id: $stateParams.id,
    list: [],
    order: {},
    account: $localStorage[KEY_ACCOUNT]
  };
  $scope.fnGetList = function() {
    $ionicLoading.show();
    return Order.list().then(function(res) {
      vm.list = res.rows;
      return $ionicLoading.hide();
    })["finally"](function() {
      $scope.$broadcast('scroll.refreshComplete');
      return $scope.$broadcast('scroll.infiniteScrollComplete');
    });
  };
  $scope.fnDetail = function(id) {
    $ionicLoading.show();
    return Order.detail(id).then(function(data) {
      vm.order = data;
      return $ionicLoading.hide();
    });
  };
  $scope.nameFilter = function(list) {
    var item, j, len, res;
    res = [];
    if (!angular.isArray(list)) {
      return [];
    }
    for (j = 0, len = list.length; j < len; j++) {
      item = list[j];
      if (item.driver === vm.account.realName) {
        res.push(item);
      }
    }
    return res;
  };

  /*
  开始发车
   */
  $scope.fnBegining = function(id) {
    return Order.begin(id).then(function() {
      return vm.order.status = 4;
    }, function(msg) {
      return $ionicPopup.alert({
        title: msg
      });
    });
  };

  /*
  完成任务
   */
  return $scope.fnFinish = function(id) {
    return Order.finish(id).then(function() {
      return $state.go('tab.home');
    }, function(msg) {
      return $ionicPopup.alert({
        title: msg
      });
    });
  };
});
