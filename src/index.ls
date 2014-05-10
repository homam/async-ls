compositions = require \./compositions
lists = require \./lists
promises = require \./promises
monads = require \./monads
SuperLazyPromise = require \./superlazypromise
Queue = require \./queue

callbacks = compositions <<< lists
promises = promises

async = {
	monads
	callbacks
	promises
	# TODO: put superLazyPromises <<< SuperLazyPromise: SuperLazyPromise
	SuperLazyPromise
	Queue
}

async.VERSION = '0.0.2'
module.exports = async