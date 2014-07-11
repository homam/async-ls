# # Promises

# ## Imports
{
	id, map, zip, empty, flip, foldr, filter,
	concat, group-by, div, obj-to-pairs, last,
	sort-by, find, flatten
} = require \prelude-ls
Promise = require \./lazypromise
{
	monadize
	filterM
	foldM
	sequenceM
} = require \./monads



# ## Compositions
# ### returnP
# Inject a value into a promise.
# > returnP :: x -> Promise x
returnP = (x) ->
	Promise.resolve x


# ### fmapP
# Map a normal function over a promise.
# > fmapP :: (x -> y) -> Promise x -> Promise y
fmapP = (f, g) -->
	g.then -> f it

# ### ffmapP
# `fmapP` with its arguments flipped.
# > ffmapP :: Promise x -> (x -> y) -> Promise y
ffmapP = flip fmapP


# ### bindP
# Sequentially compose two promises, passing the value produced
# by the first as an argument to the second.
# > bindP :: Promise x -> (x -> Promise y) -> Promise y
bindP = (f, g) -->
	f.then (fx) ->
		g fx


# ### fbindP
# `bindP` with its arguments flipped.
# > fbindP :: (x -> p y) -> p x -> p y
fbindP = flip bindP

promise-monad = monadize returnP, fmapP, bindP


# ### filterP
# Filter the list by applying the promise predicate function to 
# each of its element one-by-one in serial order.
# > filterP :: (x -> p Boolean) -> [x] -> p [x]
filterP = filterM promise-monad


# ### foldP
# The `foldP` function is analogous to `foldl`, except that its result is
# encapsulated in a promise.
# > foldP :: (a -> b -> p a) -> a -> [b] -> p a
foldP = foldM promise-monad


# ### sequenceP
# Run its input (an array of `Promise` s) in parallel
# (without waiting for the previous promise to fulfill),
# and return the results encapsulated in a promise.
# 
# The returned promise immidiately gets rejected,
# if any of the promises in the input list fail.
# > sequenceP :: [p x] -> p [x]
sequenceP = sequenceM promise-monad


# ## Lists

# #### partition-in-n-parts
# Private utility, Partition the input `arr` 
# into smaller arrays of maximum `n` length.
# > partition-in-n-parts :: Int -> [x] -> [[x]]
partition-in-n-parts = (n, arr) -->
	(arr `zip` [0 to arr.length - 1]) 
		|> (group-by ([_, i]) -> i `div` n) 
		|> obj-to-pairs 
		|> map (.1) >> map (.0)


# #### limit
# Private utility, for creating parallel-limited version of `map`, `filter`, `any`, `all` and `find`.
limit = (serial, parallel, projection, n, f, xs) -->
	parts = partition-in-n-parts n, xs
	(returnP parts) `bindP` (serial (parallel f)) `ffmapP` projection


# ### parallel-map
# > parallel-map :: (a -> p b) -> [a] -> p [b]
parallel-map = (f, xs) -->
	Promise.all(map f, xs)  # equivalent to sequenceP(map f, xs)


# ### serial-map
# > serial-map :: (a -> p b) -> [a] -> p [b]
serial-map = (f, [x, ...xs]:list) -->
	return returnP [] if empty list
	(f x)
		|> fbindP (fx) ->
			(serial-map f, xs) 
			|> fbindP (fxs) ->
				returnP [fx] ++ fxs


# ### parallel-limited-map
# > parallel-limited-map :: Int -> (x -> p y) -> [x] -> p [y]
parallel-limited-map = limit serial-map, parallel-map, concat


# ### parallel-filter
# > parallel-filter :: (x -> m Boolean) -> [x] -> m [x]
parallel-filter = (f, xs) -->
	g = (x) -> 
		(f x) `ffmapP` ((fx) -> [fx, x])

	(parallel-map g, xs) 
		|> fmapP ((filter (.0)) >> (map (.1))) 


# ### serial-filter
# Synonym for `filterP`
# > serial-filter :: (x -> p Boolean) -> [x] -> p [x]
serial-filter = filterP


# ### parallel-limited-filter
# > parallel-limited-filter :: Int -> (x -> p Boolean) -> [x] -> p x
parallel-limited-filter = limit serial-map, parallel-filter, concat


# #### mplus-promise-boolean-object
# Private utility, sum two `m [Boolean, x]`, by performing logical disjunction on the first item in the tuples.
# > mplus-promise-boolean-object :: m [Boolean, x] -> m [Boolean, x] -> m [Boolean, x]
mplus-promise-boolean-object = (pa, pb) -->
	pa |> fbindP ([b, o]) ->
		| b => pa
		| otherwise => pb


# #### msum-promise-boolean-object
# Private utility, return the first tuple that its first item is `true`.
# > msum-promise-boolean-object :: [m [Boolean, x]] -> m [Boolean, x]
msum-promise-boolean-object = (mxs) -> foldr mplus-promise-boolean-object, (returnP [false, null]), mxs


# #### parallel-find-any
# Private utility, an abstraction for `parallel-any` and `parallel-find`.
# > parallel-find-any :: (x -> Boolean) -> [x] -> [[Boolean, x]]
parallel-find-any = (f, xs) --> 
	map ((x) -> (f x) `ffmapP` (b) -> [b,x]), xs 
		|> msum-promise-boolean-object


# #### serial-find-any
# Private utility, it is an abstraction of `serial-find` and `serial-any`.
# > serial-find-any :: ((x, Boolean) -> [Boolean, _]) -> (x -> p Boolean) -> [x] -> p [Boolean, x]
# > serial-find-any :: ((x, [Boolean, x]) -> [Boolean, x]) -> (x -> p Boolean) -> [x] -> p [Boolean, x]
serial-find-any = (selector, f, [x,...xs]:list) -->
	return returnP [false, null] if empty list
	(f x) 
		|> fmapP selector x 
		|> fbindP ([b, x]) -> 
			| b => returnP [b, x]
			| otherwise => (serial-find-any selector, f, xs)


# ### parallel-any
# Run the boolean predicate (that is encapsulated in a promise) on the list in parallel.
# The returned promise fulfills as soon as a matching item is found with `true`,
# otherwise `false` if no match was found.
# > parallel-any :: (x -> p Boolean) -> [x] -> p Boolean
parallel-any = (f, xs) --> (parallel-find-any f, xs) `ffmapP` (.0)


# ### serial-any
# > serial-any :: (x -> m Boolean) -> [x] -> m Boolean
serial-any = (f, xs) --> (serial-find-any ((_, b) --> [b, _]), f, xs) `ffmapP` (.0)


# ### parallel-limited-any
# > parallel-limited-any :: Int -> (x -> p Boolean) -> [x] -> p Boolean
parallel-limited-any = limit serial-any, parallel-any, id


# ### parallel-all
# > parallel-all :: (x -> p Boolean) -> [x] -> p Boolean
parallel-all = (f, xs) --> (parallel-find-any ((x) -> (f x) `ffmapP` (not)), xs) `ffmapP` ((not) . (.0))


# ### serial-all
# > serial-all :: (x -> p Boolean) -> [x] -> p Boolean
serial-all = (f, xs) --> (serial-find-any ((_, b) --> [b, _]), ((x) --> (f x) `ffmapP` (not)), xs) `ffmapP` ((not) . (.0))


# ### parallel-limited-all
# > parallel-limited-all :: Int -> (x -> p Boolean) -> [x] -> p Boolean
parallel-limited-all = limit serial-all, parallel-all, id


# ### parallel-find
# Run the boolean predicate (that is encapsulated in a promise) on the list in parallel.
# The returned promisefulfills as soon as a matching item is found with the
# matching value, otherwise with `null` if no match was found. 
# > parallel-find :: (x -> m Boolean) -> [x] -> m 
parallel-find = (f, xs) --> (parallel-find-any f, xs) `ffmapP` (.1)


# ### serial-find
# > serial-find :: (x -> m Boolean) -> [x] -> m x
serial-find = (f, xs) --> (serial-find-any ((x, [b, y]) --> 
	[b, y]), ((x) -> (f x) `ffmapP` ((fx) -> 
		[fx, x])), xs) `ffmapP` (.1)
 

# ### parallel-limited-find
# > parallel-limited-find :: Int -> (x -> p Boolean) -> [x] -> p x
parallel-limited-find = limit (serial-find-any ((x, [b, y]) --> [b, y])), parallel-find-any, (.1)


# ### parallel-sequence
# Synonym for `sequenceP`
# > parallel-sequence :: [p x] -> p [x]
parallel-sequence = sequenceP


# ### serial-sequence
# The serial version of `sequenceP`.
#
# To run the list one by one in a serial order, its items
# must be instances of `LazyPromise` type.
# This function runs the list in parallel, if it is a list 
# of normal `Promise` s.
# > serial-sequence :: [p x] -> p [x]
serial-sequence = (list) ->
	foldP ((a, x) -> x `ffmapP` (-> a ++ [it])), [], list


# ### parallel-limited-sequence
# > parallel-limited-sequence :: Int -> [p x] -> p [x]
parallel-limited-sequence = (n, xs) -->
	parts = partition-in-n-parts n, xs
	(returnP parts) `bindP` (serial-map sequenceP) `ffmapP` concat


# ### parallel-apply-each
# > parallel-apply-each :: x -> [x -> p y] -> p [y]
parallel-apply-each = (x, fs) --> parallel-sequence (map (<| x), fs)


# ### serial-apply-each
# > serial-apply-each :: x -> [x -> p y] -> p [y]
serial-apply-each = (x, fs) --> serial-sequence (map (<| x), fs)


# ### parallel-limited-apply-each
# > parallel-limited-apply-each :: x -> [x -> p y] -> p [y]
parallel-limited-apply-each = limit serial-map, parallel-apply-each, concat


# ### parallel-sort-by
# Sort the list using the given function for making the comparison between the items.
# > parallel-sort-by :: (a -> p b) -> [a] -> p [a]
parallel-sort-by = (f, xs)  -->
	g = (x) -> 
		(returnP x) `bindP` f `ffmapP` ((fx) -> [fx, x])

	(returnP xs) 
		|> fbindP (parallel-map g) 
		|> fmapP (sort-by (.0)) >> (map (.1))
#
#
# #### subsets-of-size
# Private utility, return the list of all subsets of size `k` for the given list.
# > subsets-of-size :: [b] -> Int -> [[b]]
subsets-of-size = ([x, ...xs]:set, k) ->
	| k == 0    => [[]]
	| empty set => []
	| otherwise => ([x] ++) `map` (xs `subsets-of-size` (k - 1)) ++ xs `subsets-of-size` k


# ### parallel-sort-with
# `parallel-sort-with` takes a binary function which compares two items and returns either
# a positive number, 0, or a negative number, and sorts the inputted list
# using that function. 
# > parallel-sort-with :: (a -> a -> p i) -> [a] -> p [a]
parallel-sort-with = (f, xs) -->
	compareP = ([[a, ia], [b, ib]]) -->
		(f a, b)
			|> fbindP ((c) -> [ia, ib, c])

	ilist = xs `zip` [0 to xs.length - 1]

	returnP (ilist `subsets-of-size` 2) # [[[o, i]]]
		|> fbindP parallel-map compareP
		|> fmapP (cs) -> 
			compare = ([a,ia],[b,ib]) ->
				direction = ia > ib
				[_,_,c]:tuple? = find (([x,y,_]) -> 
					| direction => y == ia and x == ib
					| otherwise => x == ia and y == ib
				), cs
				if direction then -1*c else c
			ilist.concat!.sort compare .map (.0)


# ### waterfall
# > waterfall :: x -> [x -> Promise x] -> Promise x
waterfall = (x, fs) -->
	foldP ((a, y) -> y a), x, fs


# ### transform-promise-either
# Bind a promise monad to an either monad. The result is a promise monad. 
# Since we can think of promise as a superset of either in the way it handles errors.
# > transform-promise-either :: Promise x -> (x -> Either y) -> Promise y
transform-promise-either = (f, g) -->
	(res, rej) <- new-promise
	f.then (fx) ->
		[errg, gfx] = g fx
		if !!errg
			rej new Error errg
		else
			res gfx
	f.catch (err) ->
		rej err

# ### ftransform-promise-either
# `transform-promise-either` with its arguments flipped.
# > ftransform-promise-either :: (x -> Either y) -> Promise x -> Promise y
ftransform-promise-either = flip transform-promise-either


# ### transform-either-promise
# Bind an either monad to a promise monad.
# > transform-either-promise :: Either x -> (x -> Promise y) -> Promise y
transform-either-promise = ([errf, fx], g) ->
	(res, rej) <- new-promise
	if !!errf
		rej new Error errf
	else
		res g fx

# ### ftransform-either-promise
# `transform-either-promise` with its arguments flipped.
# > ftransform-either-promise :: (x -> Promise y) -> Either x -> Promise y
ftransform-either-promise = flip transform-either-promise


# ### left-or-right
# Executes the left promie first and only execute the right promise if the left fails.
# > left-or-right: (a -> Promise b) -> (a -> Promise b) -> (a -> Promise b)
left-or-right = (f, g, x) --> 
	(res, rej) <- new-promise
	f x
		..then -> res it
		..catch -> g x .then res, rej


# ### to-callback
# Convert the promise object to a callback with the signature of `(error, result) -> void`
# > p x -> CB x
to-callback = (p, callback) !-->
	p.then ->
		callback null, it
	p.catch ->
		callback it, null


# ### from-value-callback
# Make a promise object from a callback with the signature of `(result) -> void`, like `fs.exist`
# > Cb x -> p x
from-value-callback = (f) ->
	(...args) ->
		_res = null
		args = args ++ [->
			_res it
		]
		(res, rej) <- new-promise
		_res := res
		try
			f.apply null, args
		catch ex
			rej ex
	
# ### from-void-callback
# Make a promise object from a callback with the signature of `(result) -> (error)`, like `fs.writeFile`
# > Cbv x -> p x
from-void-callback = (f) ->
	(...args) ->
		_res = null
		args = args ++ [->
			_res!
		]
		(res, rej) <- new-promise
		_res := res
		try
			f.apply null, args
		catch ex
			rej ex
	

# ### from-error-value-callback
# Make a promise object from a callback with the signature of `(error, result) -> void`, like `fs.stat`
# > CB x -> Promise x

from-error-value-callback = (f) ->
	(...args) ->
		_res = null
		_rej = null
		args = args ++ [(error, result) ->
			return _rej error if !!error
			_res result
		]
		(res, rej) <- new-promise
		_res := res
		_rej := rej
		try
			f.apply null, args
		catch ex
			rej ex


# ### from-error-values-callback
# Make a promise object from a callback with the signature of `(error, result1, result2, ...) -> void`, like `(error, response, body) <- request url`
# > ((...x) -> y) -> CB x -> Promise y
from-error-values-callback = (projection, f) ->
	(...args) ->
		_res = null
		_rej = null
		args = args ++ [(error, ...more) ->
			return _rej error if !!error
			_res projection ...more
		]
		(res, rej) <- new-promise
		_res := res
		_rej := rej
		try
			f.apply null, args
		catch ex
			rej ex


# ### from-named-callbacks
# Make a promise object from `obj`.
# > String -> String -> obj -> Promise x
from-named-callbacks = (success-name, error-name, obj) ->
	_res = null
	_rej = null
	obj[success-name] = (-> _res it)
	obj[error-name] = (-> _rej it)

	(res, rej) <- new-promise
	_res := res
	_rej := rej
		
# ### new-promise
# A convenient way for creating new promises without nesting:
# ```LiveScript
# (resolve, reject) <- new-promise
# ...
# resolve ...
# ```
# > ((x -> void), (Error -> void) -> void) -> Promise x
new-promise = (callback) ->
	new Promise (res, rej) ->
		callback res, rej

# exports
exports = exports or this
exports <<< {
	LazyPromise: Promise
	new-promise

	returnP
	fmapP 
	ffmapP
	bindP 
	fbindP
	foldP
	filterP
	sequenceP

	promise-monad

	parallel-sequence
	serial-sequence
	parallel-limited-sequence

	serial-filter
	parallel-filter
	parallel-limited-filter

	serial-map
	parallel-map
	parallel-limited-map

	parallel-any
	serial-any
	parallel-limited-any

	parallel-all
	serial-all
	parallel-limited-all

	parallel-find
	serial-find
	parallel-limited-find

	parallel-sort-by
	parallel-sort-with


	parallel-apply-each
	serial-apply-each
	parallel-limited-apply-each

	waterfall

	transform-either-promise
	ftransform-either-promise
	transform-promise-either
	ftransform-promise-either
	left-or-right

	to-callback
	from-value-callback
	from-void-callback
	from-error-value-callback
	from-error-values-callback
	from-named-callbacks
}