_ = require 'underscore'

module.exports = (_) ->
  _setPath = (obj, path, value) ->
    keys = path.split('.')
    lastKey = keys.pop()
    for key in keys
      unless obj[key]?
        obj[key] = {}
      obj = obj[key]
    obj[lastKey] = value

  _getPath = (obj, path) ->
    for key in path.split('.')
      obj = obj?[key]
    return obj

  paths =
    paths: (obj) ->
      keys = []
      for own key, value of obj
        if _.isObject(value) and !_.isArray(value) and !(value instanceof Date)
          newKeys = paths.paths(value).map((deepKey) -> [key, deepKey].join('.'))
          keys = keys.concat(newKeys.length and newKeys or [key])
        else
          keys.push key
      keys
    path: (args...) ->
      if args.length is 3
        _setPath args...
      else
        _getPath args...

  return paths





