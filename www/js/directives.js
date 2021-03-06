angular.module('starter.directives', []).directive('vmpTabs', function(Account) {
  var directive;
  directive = {
    restrict: 'E',
    templateUrl: 'templates/tabs.new.html',
    link: function(scope) {
      return scope.fnGetPermission = function(role) {
        return Account.permission(role);
      };
    }
  };
  return directive;
}).directive('baiduMap', function($ionicPopup, $timeout, $ionicLoading) {
  return {
    scope: {
      lat: '=',
      lng: '=',
      address: '=',
      onConfirm: '&'
    },
    restrict: 'E',
    link: function($scope, iElm, iAttrs, controller) {
      var ac, createMarker, geolocation, map, top_right_navigation;
      createMarker = function(point) {
        var geoc, marker;
        marker = new BMap.Marker(point);
        map.addOverlay(marker);
        geoc = new BMap.Geocoder();
        return geoc.getLocation(point, function(rs) {
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
          marker.setLabel(label);
          map.panTo(point);
          return $timeout(function() {
            return angular.extend($scope, {
              lat: point.lat,
              lng: point.lng,
              address: text
            });
          });
        });
      };
      map = new BMap.Map(iElm[0]);
      top_right_navigation = new BMap.NavigationControl({
        anchor: BMAP_ANCHOR_BOTTOM_RIGHT,
        type: BMAP_NAVIGATION_CONTROL_ZOOM
      });
      map.addControl(top_right_navigation);
      geolocation = new BMap.Geolocation();
      ac = new BMap.Autocomplete({
        input: 'searchInput',
        location: map
      });
      ac.addEventListener('onconfirm', function(e) {
        console.log(e.item);
        return $timeout(function() {
          return $scope.onConfirm({
            address: e.item.value.city + e.item.value.district + e.item.value.business
          });
        });
      });
      map.addEventListener('load', function() {
        return $ionicLoading.show({
          template: '正在加载地图,请稍后'
        });
      });
      map.addEventListener('tilesloaded', function() {
        return $ionicLoading.hide();
      });
      map.addEventListener('click', function(e) {
        map.clearOverlays();
        return createMarker(e.point);
      });
      map.centerAndZoom('合肥', 12);
      geolocation.getCurrentPosition(function(r) {
        if (this.getStatus() === BMAP_STATUS_SUCCESS) {
          return createMarker(r.point);
        } else {
          return $ionicPopup.alert({
            title: '定位失败',
            template: '获取位置信息失败,请手动选择'
          });
        }
      }, {
        enableHighAccuracy: true
      });
    }
  };
});
