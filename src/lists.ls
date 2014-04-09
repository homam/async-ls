# # Lists

# Imports
{zip, each, concat, map, group-by, obj-to-pairs, div, sort-by, filter, id, empty} = require \prelude-ls
{returnA, bindA, fbindA, ffmapA, fmapA, sequenceA} = require \./compositions

# Private utility function used to create the parallel-limited version of the functions.

# 	limit :: ((a -> CB b) -> [a] -> CB c) -> 
#			 	((a -> CB b) -> [a] -> CB c) -> 
#			 	(c -> d) ->
#			 	Int -> 
#			 	(a -> CB b) -> [a] -> CB d
limit = (serial, parallel, projection, n, f, xs, callback) !-->
	parts = partition-in-n-parts n, xs
	(returnA parts) `bindA` (serial (parallel f)) `ffmapA` projection <| callback


# Private utility function for partitioning the input `arr` into sets of `n` members.

# 	partition-in-n-parts :: Int -> [x] -> [[x]]
partition-in-n-parts = (n, arr) -->
	(arr `zip` [0 to arr.length - 1]) 
		|> (group-by ([a, i]) -> i `div` n) 
		|> obj-to-pairs 
		|> map (([_, ar]) -> (map (([a, _]) -> a), ar))


# ## Map

# ### parallel-map

# 	parallel-map :: (a -> CB b) -> [a] -> CB [b]
parallel-map = (f, xs, callback) !-->
	if empty xs
		callback null, []
		return

	xs = xs `zip` [0 to xs.length - 1]
	results = []
	call = (err) !->
		callback err, (results |> (sort-by ([_,i]) -> i) >> (map ([r,_]) -> r))

	got = (i, err, r) !-->
		if !!err
			call err
		else
			results := results ++ [[r,i]]
			if results.length == xs.length
				call null
	xs |> each ([x,i]) -> f x, (got i)


# ### serial-map
# Serial Asynchronous Map

# 	serial-map :: (a -> CB b) -> [a] -> CB [b]
serial-map = (f, xs, callback) !-->
	if empty xs
		callback null, []
		return

	next = (f, xs, results) ->
		(err, r) <- f(xs[results.length])
		if !!err
			callback err, results
		else
			results.push r
			if results.length == xs.length
				callback null, results
			else
				next f, xs, results
	next f, xs, []


# ### parallel-map-limited
# Similar to `parallel-map`, only no more than 
# `limit` iterators will be simultaneously running at any time.

# 	parallel-map-limited :: Int -> (x -> CB y) -> [x] -> CB [y]
parallel-map-limited = limit serial-map, parallel-map, concat


# -----
# ## Filter

# ### parallel-filter

# 	parallel-filter :: (x -> CB Bool) -> [x] -> CB [x]
parallel-filter = (f, xs, callback) !-->
	g = (x, cb) -> 
		(returnA x) `bindA` f `ffmapA` ((fx) -> [fx, x]) <| cb

	(returnA xs) 
		|> fbindA (parallel-map g) 
		|> fmapA ((filter ([s,_]) -> s) >> (map ([_,x]) -> x)) <| callback


### serial-filter

# 	serial-filter :: (x -> CB Bool) -> [x] -> CB [x]
serial-filter = (f, arr, callback) !-->
	next = (f, [x,...xs]:list, callback, res) ->
		if empty list
			callback null, res
		else
			(err, fx) <- f x
			if !!err
				callback err, null
			else
				next f, xs, callback, (if fx then res ++ [x] else res)

	next f, arr, callback, []


# ### parallel-limited-filter

# 	parallel-limited-filter :: Int -> (x -> CB Bool) -> [x] -> CB x
parallel-limited-filter = limit serial-map, parallel-filter, concat

# -----
# ## Any

# ### parallel-any

# 	parallel-any :: (x -> CB Bool) -> [x] -> CB Bool
parallel-any = (f, xs, callback) !-->
	if empty xs
		callback null, false
		return

	how-many-got = 0
	callback-called = false
	call = (err, res) ->
		if not callback-called
			callback-called := true 
			callback err, res
	total = xs.length
	got = (err, res) -> 
		how-many-got := how-many-got + 1
		if !!err or res or how-many-got == total
			call err, res
	xs |> each ((x) -> f x, got)

# serial-any :: (x -> CB Bool) -> [x] -> CB Bool
serial-any = (f, xs, callback) !-->
	if empty xs
		callback null, false
		return

	next = (xs, callback, i) ->
		(err, r) <- f xs[i]
		if !!err
			callback err, null
		else
			if r
				callback null, true
			else
				if i == xs.length - 1
					callback null, false
				else
					next xs, callback, i+1
	next xs, callback, 0


# ### parallel-limited-any

# 	parallel-limited-any :: Int -> (x -> CB Bool) -> [x] -> CB Bool
parallel-limited-any = limit serial-any, parallel-any, id


# make-all-by-any :: ((x -> CB Bool) -> [x] -> Bool) -> (x -> CB Bool) -> [x] -> CB Bool
make-all-by-any = (which-any, f, xs, callback) !-->
	g = (x, cb) ->
		(returnA x) `bindA` f `ffmapA` (not) <| cb
	(returnA xs) `bindA` (which-any g) `ffmapA` (not) <| callback


# parallel-all :: (x -> CB Bool) -> [x] -> CB Bool
parallel-all = make-all-by-any parallel-any


# serial-all :: (x -> CB Bool) -> [x] -> CB Bool
serial-all = make-all-by-any serial-any


# parallel-limited-all :: Int -> (x -> CB Bool) -> [x] -> CB Bool
parallel-limited-all = limit serial-all, parallel-all, id


# ## Control Flow

# ### parallel-sequence
# Run its sole input (a tasks array of functions) in parallel, 
# without waiting until the previous function has completed. 
# If any of the functions pass an error to its callback, 
# the main callback is immediately called with the value of the error. 
# Once the tasks have completed, the results are passed to the final callback as an array.

# 	parallel-sequence :: [CB x] -> CB [x]
parallel-sequence = (..., callback) -> sequenceA ... <| callback


# ### parallel-limited-sequence

# 	parallel-limited-sequence :: Int -> [CB x] -> CB [x]
parallel-limited-sequence = limit serial-map, sequenceA, concat








exports = exports or this
exports.serial-map = serial-map
exports.parallel-map = parallel-map
exports.parallel-map-limited = parallel-map-limited

exports.parallel-filter = parallel-filter
exports.serial-filter = serial-filter
exports.parallel-limited-filter = parallel-limited-filter

exports.parallel-any = parallel-any
exports.serial-any = serial-any
exports.parallel-limited-any = parallel-limited-any

exports.parallel-all = parallel-all
exports.serial-all = serial-all
exports.parallel-limited-all = parallel-limited-all

exports.parallel-sequence = parallel-sequence
exports.parallel-limited-sequence = parallel-limited-sequence