compositions = require \./compositions
lists = require \./lists
promises = require \./promises

callbacks = compositions <<< lists
promises = promises

async = {
	callbacks
	promises
}

async.VERSION = '0.0.1'
module.exports = async