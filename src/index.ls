compositions = require \./compositions
lists = require \./lists
promises = require \./promises
monads = require \./monads

callbacks = compositions <<< lists
promises = promises

async = {
	monads
	callbacks
	promises
}

async.VERSION = '0.0.1'
module.exports = async