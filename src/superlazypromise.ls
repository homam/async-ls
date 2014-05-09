# # Lazy Promise

# ## Imports
require \setimmediate
Promise = global.Promise or require \promise
{sequenceM, monadize} = require \./monads
inherit = require \inherits
{Obj, map} = require \prelude-ls

# ## SuperLazyPromise type
# `SuperLazyPromise` only starts getting evaluated after `then` is called.
SuperLazyPromise = (fn) !->
	return new SuperLazyPromise fn if not this instanceof SuperLazyPromise
	throw new TypeError 'Promise constructor takes a function argument' if typeof fn is not \function

	_ress = []
	_rejs = []
	promise = null

	evaluated = false 
	result = null
	error = null

	call = !->
		return if not evaluated
		if error is not null
			while _rejs.length > 0
				_rejs[0](error)
				_rejs.splice(0, 1)

		else
			while _ress.length > 0
				_ress[0](result)
				_ress.splice(0, 1)

	this.go = ->
		(promise := new Promise (res_, rej_) !-> set-immediate (!-> fn res_, rej_)) if promise is null
		promise.then ->
			result := it
			evaluated := true
			call!

		promise.catch ->
			error := it
			evaluated := true
			call!

		this

	this.then = (res, rej) ->
		_ress.push res
		if !!rej 
			_rejs.push rej
		call!
		this

	this.catch = (rej) ->
		_rejs.push rej
		call!
		this
		
# for k in Obj.keys(Promise)
# 	SuperLazyPromise[k] = Promise[k]

super-lazy-promise-monad = monadize do
	((x) -> 
		new SuperLazyPromise (res, rej) !->
			res x
	)
	((f, g) --> 
		new SuperLazyPromise (res, rej) !->
			g.then -> res(f it)
			g.catch -> rej it
			g.go!
	)
	((f, g) --> 
		new SuperLazyPromise (res, rej) !->
			f.then -> (g it).go!.then( res, rej)
			f.catch -> rej it
			f.go!
	)



module.exports = SuperLazyPromise <<< monad: super-lazy-promise-monad
inherit(SuperLazyPromise, Promise)

return
double = (x) ->
	new SuperLazyPromise (res, rej) !->
		setTimeout !->
			if x == 30 
				rej 'err at 30'
			else
				res x*2
		, 200

logP = (p) ->
	p.then !-> console.log \=, it
	p.catch !-> console.log \^, it
	p

sequenceSLP = sequenceM super-lazy-promise-monad
super-lazy-promise-serial-map = (f,xs) --> sequenceSLP(map f, xs)
super-lazy-promise-parallel-map = (f,xs) --> sequenceSLP(map (-> f it .go!), xs)


(double 2000).go! |> logP


((double 30) `super-lazy-promise-monad.ffmap` (-> it * 4)).go! |> logP

super-lazy-promise-parallel-map(double, [10 to 20]).go! |> logP

