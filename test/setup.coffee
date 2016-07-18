require 'mocha-fibers'
require 'fibrous'

mongoose = require 'mongoose'
mongoose.connect 'mongodb://localhost/test'
