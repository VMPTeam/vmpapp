angular.module 'starter.directives', []
.directive 'vmpTabs', (Account) ->
  directive =
    restrict: 'E'
    templateUrl: 'templates/tabs.new.html'
    link: (scope) ->
      scope.fnGetPermission = (role) ->
        return Account.permission role

  return directive

.directive 'baiduMap', ($ionicPopup, $timeout, $ionicLoading) ->
# Runs during compile
  return {
# name: '',
# priority: 1,
# terminal: true,
  scope:
    lat: '=',
    lng: '=',
    address: '='
    onConfirm: '&'
    , # {} = isolate, true = child, false/undefined = no change
# controller: function($scope, $element, $attrs, $transclude) {},
# require: 'ngModel', # Array = multiple requires, ? = optional, ^ = check parent elements
  restrict: 'E', # E = Element, A = Attribute, C = Class, M = Comment
# template: '',
# templateUrl: '',
# replace: true,
# transclude: true,
# compile: function(tElement, tAttrs, function transclude(function(scope, cloneLinkingFn){ return function linking(scope, elm, attrs){}})),
  link: ($scope, iElm, iAttrs, controller) ->
    # create marker
    createMarker = (point) ->
      marker = new BMap.Marker(point)  # 创建标注
      map.addOverlay(marker)              # 将标注添加到地图中
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
          text = addComp.province + addComp.city + addComp.district + addComp.street + addComp.streetNumber
        label = new BMap.Label(text, {offset: new BMap.Size(20, -10)})
        marker.setLabel(label)
        map.panTo(point)
        $timeout () ->
          angular.extend $scope,
            lat: point.lat,
            lng: point.lng,
            address: text

    map = new BMap.Map(iElm[0])
    # 放大缩小控件
    top_right_navigation = new BMap.NavigationControl
      anchor: BMAP_ANCHOR_BOTTOM_RIGHT
      type: BMAP_NAVIGATION_CONTROL_ZOOM
    map.addControl top_right_navigation
    geolocation = new BMap.Geolocation()
    ac = new BMap.Autocomplete
      input: 'searchInput'
      location: map
    ac.addEventListener 'onconfirm', (e) ->
      console.log e.item
      $timeout ->
        $scope.onConfirm
          address: e.item.value.city + e.item.value.district + e.item.value.business

    map.addEventListener 'load', ->
      $ionicLoading.show
        template: '正在加载地图,请稍后'

    map.addEventListener 'tilesloaded', ->
      $ionicLoading.hide()

    map.addEventListener 'click', (e) ->
      map.clearOverlays()
      createMarker e.point

    map.centerAndZoom('合肥', 12)

    geolocation.getCurrentPosition (r) ->
      if this.getStatus() == BMAP_STATUS_SUCCESS
        createMarker(r.point)
      else
        $ionicPopup.alert(
          title: '定位失败',
          template: '获取位置信息失败,请手动选择'
        )
    , enableHighAccuracy: true

    return
  }
