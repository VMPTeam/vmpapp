angular.module 'starter.filters', []
  .filter 'concatName', () ->
    (peoples) ->
      nameArr = []
      if angular.isArray peoples
        peoples.forEach (obj) ->
          nameArr.push obj.name

      return nameArr.join ','
