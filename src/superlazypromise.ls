# # Lazy Promise

# ## Imports
require \setimmediate
Promise = global.Promise or require \promise
inherit = require \inherits
{Obj} = require \prelude-ls

# ## SuperLazyPromise type
# `SuperLazyPromise` only starts getting evaluated after `then` is called.
SuperLazyPromise = (fn) !->
	return new SuperLazyPromise fn if not this instanceof SuperLazyPromise
	throw new TypeError 'Promise constructor takes a function argument' if typeof fn is not \function

	_res = null
	_rej = null
	promise = null

	this.go = ->
		(promise := new Promise (res_, rej_) !-> set-immediate (!-> fn res_, rej_)) if promise is null
		promise.then _res, _rej
		this

	this.then = (res, rej) ->
		_res := res
		_rej := rej
		this

	this.catch = (rej) ->
		_rej := rej
		


for k in Obj.keys(Promise)
	SuperLazyPromise[k] = Promise[k]

module.exports = SuperLazyPromise
inherit(SuperLazyPromise, Promise)


_ = require \./promises

double = (x) ->
	new SuperLazyPromise (res, rej) !->
		console.log \double, x
		setTimeout !->
			if x == 30 
				rej 'err at 30'
			else
				res x*2
		, 1000

logP = (p) ->
	p.then !-> console.log \=, it
	p.catch !-> console.log \^, it
	p


logP(double 5).go!.then ->
	console.log it


return
logP(_.parallelMap(double, [1,2,3,4,5])).go!
logP(_.sequenceP([double(10), double(20), double(30), double(40), double(50)]))
logP(_.serial-sequence([double(10), double(20), double(30), double(40), double(50)]))