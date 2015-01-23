require './setup'

mongooseExtensions = require '../src/'
mongoose = require 'mongoose'
{Schema} = mongoose
_ = require 'underscore'
fibrous = require 'fibrous'
{expect} = require 'chai'


schema = new Schema
  balance: type: Schema.Types.Money
  day: type: Schema.Types.Day
TestObject = mongoose.model('TestObject', schema)

describe 'mongoose_types', ->

  beforeEach fibrous ->
    TestObject.sync.remove()

  describe 'Money', ->
    describe 'cast', ->
      it 'should return a true number', fibrous ->
        testObj = new TestObject(balance: 5)
        expect(typeof testObj.balance).to.eql 'number'
        expect(testObj.balance).to.eql 5
        testObj.sync.save()

        testObj = TestObject.sync.findById testObj
        expect(typeof testObj.balance).to.eql 'number'
        expect(testObj.balance).to.eql 5

      it 'should properly round', fibrous ->
        testObj = new TestObject(balance: 5.005)
        expect(testObj.balance).to.eql 5.01
        testObj.sync.save()

        testObj = TestObject.sync.findById testObj
        expect(testObj.balance).to.eql 5.01

      it 'has the rounded value in the db', fibrous ->
        testObj = new TestObject(balance: 5.005)
        testObj.sync.save()

        rawResult = TestObject.collection.sync.find().sync.toArray()
        expect(rawResult[0].balance).to.eql 5.01

        result = TestObject.sync.findOne balance: 5.01
        expect(result.id).to.eql testObj.id

      it 'properly casts', fibrous ->
        testObj = new TestObject(balance: '5.005')
        expect(testObj.balance).to.eql 5.01

      it 'properly casts for queries', fibrous ->
        testObj = new TestObject(balance: 5.01)
        testObj.sync.save()

        result = TestObject.sync.findOne balance: '5.01'
        expect(result.id).to.eql testObj.id

      it 'handles really small values', fibrous ->
        testObj = new TestObject(balance: 7.105427357601002e-15)
        expect(testObj.balance).to.eql 0


  describe 'Day', ->
    describe 'cast', ->
      it 'should stores days as strings', fibrous ->
        testObj = new TestObject(day: '2013-04-01')
        expect(typeof testObj.day).to.eql 'string'
        expect(testObj.day).to.eql '2013-04-01'
        testObj.sync.save()

        testObj = TestObject.sync.findById testObj
        expect(typeof testObj.day).to.eql 'string'
        expect(testObj.day).to.eql '2013-04-01'

      it 'handles empty strings', fibrous ->
        testObj = new TestObject(day: '')
        expect(testObj.day).to.be.null
        testObj.sync.save()

        testObj = TestObject.sync.findById testObj
        expect(testObj.day).to.be.null

      it 'throws for invalid values', fibrous ->
        testObj = new TestObject(day: '20130401')
        expect(-> testObj.sync.save()).to.throw('Cast to day failed for value "20130401" at path "day"')
