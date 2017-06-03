_ = require 'underscore'

module.exports = (mongoose) ->

  {paths, path} = require('./paths')()
  Q = require 'q'

  # Adds additional mongoose schema types
  require('./mongoose_types')(mongoose)
  inflections = require './inflections'

  mongoose.Model::validateAndSave = (cb) ->
    @save (err, result) =>
      if err?.name is 'ValidationError'
        @_id = null if @isNew
        @errors ?= err.errors or {}
        cb(null, false)
      else if err?
        cb(err, false)
      else
        cb(err, true)

  mongoose.Model::getValidationErrors = (cb) ->
    try
      @sync.validate()
      cb(null, false)
    catch ValidationError
      messages = {}
      for key, {type} of @errors
        messages[key] = type
      cb(null, messages)

  # records the previous document in @previousDoc
  recordPreviousDoc = ->
    try
      @previousDoc = JSON.parse(JSON.stringify(@))
    catch e
    #We've seen "Converting circular structure to JSON" errors stringifying some models; add some context
      e.message = e.message + " (model context: #{@constructor.modelName} #{@id})"
      throw e

  # Store previousDoc on model instances so we can compare changes before and after save/update
  resetWithoutPreviousDoc = mongoose.Model::$__reset
  mongoose.Model::$__reset = (args...) ->
    result = resetWithoutPreviousDoc.apply(@, args)
    recordPreviousDoc.call(@)
    return result

  initWithoutPreviousDoc = mongoose.Document::init
  mongoose.Document::init = (args...) ->
    cb = args.pop() if args.length > 1
    result = initWithoutPreviousDoc.call @, args..., =>
      recordPreviousDoc.call(@)
      cb(null) if cb?
    return result

  mongoose.Document::paths = ->
    paths @toJSON()

  # always merges, unsets values set to null
  mongoose.Document::mergeAndClearNulls = (attributes) ->
    for key in paths attributes
      value = path attributes, key
      if value?
        @set key, value
      else
        @set key

  mongoose.Document::setOrUnsetPath = (path, value) ->
    if value?
      @set path, value
    else
      @set path # unset

  # Monkey patch Mongoose::model to default to collection names as pluralized underscore. e.g. PhotoLibrary -> photo_libraries
  modelWithoutUnderscoreCollectionName = mongoose.Mongoose::model
  modelWithUnderScoreCollectionName = (name, schema, collection, skipInit) ->
    collection ?=  inflections.pluralize(inflections.underscore(name))
    modelWithoutUnderscoreCollectionName.call(this, name, schema, collection, skipInit)
  mongoose.Mongoose::model = modelWithUnderScoreCollectionName
