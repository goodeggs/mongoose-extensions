require './setup'

mongoose = require 'mongoose'
_ = require 'underscore'
mongooseExtensions = require('../src/index')(mongoose)
{ValidationError} = require('mongoose').Error

{expect} = require 'chai'
sinon = require 'sinon'


# mongoose_extensions.coffee get loaded by app/globals.coffee
schema = new mongoose.Schema
  field: String
  numField: Number
  nested:
    field1: String
    field2: String
, strict: true
Model = mongoose.model('MongooseExtensionsTestModel', schema)

schema = new mongoose.Schema
  models: [Model.schema]
  modelId: {type: mongoose.Schema.ObjectId, ref: 'MongooseExtensionsTestModel'}
  modelIds: [{type: mongoose.Schema.ObjectId, ref: 'MongooseExtensionsTestModel'}]
, strict: true
ParentModel = mongoose.model('ParentTestModel', schema)

describe 'mergeAndClearNulls', ->
  model = null

  beforeEach ->
    model = new Model
      field: 'is set!'
      nested:
        field1: 'is also set!'
        field2: 'will not change'

  it 'unsets attributes set to null', ->
    expect('field' of model.toJSON()).to.equal true
    model.mergeAndClearNulls field: null
    expect('field' of model.toJSON()).to.equal false

  it 'unsets paths set to null', ->
    expect(model.toJSON().nested.field1).to.equal 'is also set!'
    model.mergeAndClearNulls 'nested.field1': null
    expect('field1' of model.toJSON().nested).to.equal false

  it 'unsets deep attributes in object values', ->
    expect(model.toJSON().nested.field1).to.equal 'is also set!'
    model.mergeAndClearNulls 'nested': {field1: null}
    expect('field1' of model.toJSON().nested).to.equal false

  it 'merges set attributes, leaving omitted attributes unchanged', ->
    expect(model.toJSON().nested.field2).to.equal 'will not change'
    model.mergeAndClearNulls 'nested': {field1: null}
    expect(model.toJSON().nested.field2).to.equal 'will not change'

describe 'recordPreviousDoc', ->
  describe 'init', ->
    {model} = {}
    beforeEach ->
      model = Model.sync.create field: 'foo'

    it 'sets previousDoc on model initialization', ->
      expect(model.previousDoc).to.be.ok

    it 'sets previous doc on model initialized from stream', ->
      model = null
      Model.find().stream()
      .on 'data', (m) ->
        model = m
      .sync.on 'end'
      expect(model.previousDoc).to.be.ok

  describe 'on an error', ->
    beforeEach ->
      sinon.stub(JSON, 'stringify').throws new Error('boom')
    afterEach ->
      JSON.stringify.restore()

    it 'appends some context to the exception message', ->
      model = new Model
      expect(-> model.$__reset()).to.throw "boom (model context: MongooseExtensionsTestModel #{model.id})"

describe 'setOrUnsetPath', ->
  {model} = {}

  beforeEach ->
    model = new Model

  it 'sets for not null or undefined', ->
    model.setOrUnsetPath 'field', 'bar'
    expect(model.field).to.equal 'bar'

  it "sets for falsy values that aren't null or undefined", ->
    model.setOrUnsetPath 'numField', 0
    expect(model.numField).to.equal 0

  it 'unsets for null', ->
    model.setOrUnsetPath 'field', null
    expect(model.field).to.be.undefined

  it 'unsets for undefined', ->
    model.setOrUnsetPath 'field', undefined
    expect(model.field).to.be.undefined

describe 'collection name default', ->
  it 'underscores and pluralizes', ->
    schema = new mongoose.Schema()
    model = mongoose.model 'BigPerson', schema
    expect(model.collection.name).to.equal 'big_people'

  it 'does not apply if specified', ->
    schema = new mongoose.Schema()
    model = mongoose.model 'SmallPerson', schema, 'smallpeople'
    expect(model.collection.name).to.equal 'smallpeople'

describe '#validateAndSave', ->
  model = null

  before ->
    schema = new mongoose.Schema
      field: {type: String, required: true}
    , strict: true
    Model = mongoose.model('VaSTestModel', schema)

  describe 'with a valid model', ->
    beforeEach ->
      Model.sync.remove()
      model = new Model field: 'foo'

    it 'returns true', ->
      expect(model.sync.validateAndSave()).to.be.true

    it 'saves the model', ->
      model.sync.validateAndSave()
      expect(Model.sync.count()).to.eql 1

  describe 'with an invalid model', ->

    beforeEach ->
      Model.sync.remove()
      model = new Model()

    it 'returns false', ->
      expect(model.sync.validateAndSave()).to.be.false

    it 'does not save the model', ->
      model.sync.validateAndSave()
      expect(Model.sync.count()).to.eql 0

  describe 'when a model raises a ValidationError directly', ->

    before ->
      schema = new mongoose.Schema
        field: String
      , strict: true
      schema.pre 'save', (next) ->
        error = new ValidationError({})
        error.errors.foo = type: "Beep boop"
        next error
      Model = mongoose.model('ThrowTestModel', schema)

    beforeEach ->
      Model.sync.remove()
      model = new Model()

    it 'returns false', ->
      expect(model.sync.validateAndSave()).to.be.false

    it 'does not save the model', ->
      model.sync.validateAndSave()
      expect(Model.sync.count()).to.eql 0

    it 'ensures an errors object exists on the parent', ->
      model.sync.validateAndSave()
      expect(model.errors).to.be.ok
      expect(model.errors.foo.type).to.equal 'Beep boop'

  describe 'when a model raises a non-Validation Error', ->

    before ->
      schema = new mongoose.Schema
        field: String
      , strict: true
      schema.pre 'save', (next) ->
        next new Error "Beep boop"
      Model = mongoose.model('ThrowTestModel2', schema)

    beforeEach ->
      Model.sync.remove()
      model = new Model()

    it 'throws through', ->
      expect(-> model.sync.validateAndSave()).to.throw Error
