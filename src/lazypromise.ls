Promise = require \promise
inherit = require \inherits
{Obj} = require \prelude-ls

# `LazyPromise` only starts getting evaluated after `then` is called.
LazyPromise = (fn) !->
	return new LazyPromise fn if not this instanceof LazyPromise
	throw new TypeError 'fn is not a function' if typeof fn is not \function

	promise = null
	this.then = (res, rej) ->
		(promise := new Promise (res_, rej_) !-> set-immediate (!-> fn res_, rej_)) if promise is null
		promise.then res, rej


for k in Obj.keys(Promise)
	LazyPromise[k] = Promise[k]

module.exports = LazyPromise
inherit(LazyPromise, Promise)
