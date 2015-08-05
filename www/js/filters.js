// Generated by CoffeeScript 1.9.2
angular.module('starter.filters', []).filter('concatName', function() {
  return function(peoples, key) {
    var nameArr;
    if (key == null) {
      key = 'name';
    }
    nameArr = [];
    if (angular.isArray(peoples)) {
      peoples.forEach(function(obj) {
        return nameArr.push(obj[key]);
      });
    }
    return nameArr.join(',');
  };
});
