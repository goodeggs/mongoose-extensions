_ = require 'underscore'

module.exports = (mongoose) ->

  Types = mongoose.Schema.Types
  {CastError} = mongoose.SchemaType
  class Money extends Types.Number
    cast: (value, doc, init) ->
      throw new CastError('money', value, @path) if isNaN(value)

      return value if value is null
      return null if value is ''
      value = Number(value) if typeof(value) is 'string'

      if value instanceof Number or (typeof(value) is 'number') or (value?.toString() is Number(value))
        return Math.round(100 * value) / 100

  class Cents extends Types.Number
    cast: (value, doc, init) ->
      value = value.toNumber() if value.toNumber? # eg bignumber.js, goodeggs-money instances
      value = Number(value) if typeof(value) is 'string'

      throw new CastError('cents', value, @path) if isNaN(value)

      return value if value is null
      return null if value is ''

      if value instanceof Number or (typeof(value) is 'number')
        throw new CastError('cents', value, @path) if value % 1 != 0 # not an int
        throw new CastError('cents', value, @path) if value < 0
        return value

      throw new CastError('cents', value, @path)

  class Day extends Types.String
    cast: (value, doc, init) ->
      return value if value is null
      return null if value is ''

      throw new CastError('day', value, @path) if !/\d{4}\-\d{2}-\d{2}/.test value
      super(value, doc, init)

  _(Types).extend({Money, Cents, Day})
