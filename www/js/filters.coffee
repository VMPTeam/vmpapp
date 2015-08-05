angular.module 'starter.filters', []
  .filter 'concatName', () ->
    (peoples, key='name') ->
      nameArr = []
      if angular.isArray peoples
        peoples.forEach (obj) ->
          nameArr.push obj[key]

      return nameArr.join ','
