require './setup'
fibrous  = require 'fibrous'
{expect} = require 'chai'

{Schema, Error} = mongoose = require 'mongoose'
Cents = require 'goodeggs-money'

mongooseTypes = require('../src/mongoose_types')(mongoose)

schema = new Schema
  balance: type: Schema.Types.Money
  cents: type: Schema.Types.Cents
  day: type: Schema.Types.Day
  timeOfDay: type: Schema.Types.TimeOfDay

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

  describe 'Cents', ->
    describe 'cast', ->
      it 'should return a true number', fibrous ->
        testObj = new TestObject(cents: 5)
        expect(typeof testObj.cents).to.eql 'number'
        expect(testObj.cents).to.eql 5
        testObj.sync.save()

        testObj = TestObject.sync.findById testObj
        expect(typeof testObj.cents).to.eql 'number'
        expect(testObj.cents).to.eql 5

      it 'should throw if cents is not an int', fibrous ->
        expect(-> new TestObject(cents: 1.001).sync.save()).to.throw Error.ValidationError

      it 'should throw if cents is a negative int', fibrous ->
        expect(-> new TestObject(cents: -1).sync.save()).to.throw Error.ValidationError

      it 'properly casts string', fibrous ->
        testObj = new TestObject(cents: '5')
        expect(testObj.cents).to.eql 5

      it 'properly casts Cents', fibrous ->
        testObj = new TestObject(cents: new Cents(10))
        expect(testObj.cents).to.eql 10

      it 'properly casts string for queries', fibrous ->
        testObj = new TestObject(cents: 501)
        testObj.sync.save()

        result = TestObject.sync.findOne cents: '501'
        expect(result.id).to.eql testObj.id

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
        expect(-> testObj.sync.save()).to.throw Error.ValidationError

      it 'throws when garbage is added to valid day', fibrous ->
        testObj = new TestObject(timeOfDay: '2015-02-05x')
        expect(-> testObj.sync.save()).to.throw Error.ValidationError

  describe 'TimeOfDay', ->
    describe 'cast', ->
      it 'should stores time of day as a string', fibrous ->
        testObj = new TestObject(timeOfDay: '13:29')
        expect(typeof testObj.timeOfDay).to.eql 'string'
        expect(testObj.timeOfDay).to.eql '13:29'
        testObj.sync.save()

        testObj = TestObject.sync.findById testObj
        expect(typeof testObj.timeOfDay).to.eql 'string'
        expect(testObj.timeOfDay).to.eql '13:29'

      it 'handles empty strings', fibrous ->
        testObj = new TestObject(timeOfDay: '')
        expect(testObj.timeOfDay).to.be.null
        testObj.sync.save()

        testObj = TestObject.sync.findById testObj
        expect(testObj.timeOfDay).to.be.null

      it 'throws for malformed values', fibrous ->
        testObj = new TestObject(timeOfDay: '13')
        expect(-> testObj.sync.save()).to.throw Error.ValidationError

      it 'throws for invalid hours', fibrous ->
        testObj = new TestObject(timeOfDay: '24:00')
        expect(-> testObj.sync.save()).to.throw Error.ValidationError

      it 'throws for invalid minutes', fibrous ->
        testObj = new TestObject(timeOfDay: '13:60')
        expect(-> testObj.sync.save()).to.throw Error.ValidationError

      it 'throws when garbage is added to valid time', fibrous ->
        testObj = new TestObject(timeOfDay: '13:40x')
        expect(-> testObj.sync.save()).to.throw Error.ValidationError
