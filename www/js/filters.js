angular.module('starter.filters', []).filter('concatName', function() {
  return function(peoples) {
    var nameArr;
    nameArr = [];
    if (angular.isArray(peoples)) {
      peoples.forEach(function(obj) {
        return nameArr.push(obj.name);
      });
    }
    return nameArr.join(',');
  };
});
