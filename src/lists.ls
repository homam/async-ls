# # Lists

# #### Imports
{
	zip, each, concat, map, group-by, obj-to-pairs, div, sort-by, 
	filter, id, empty, find
} = require \prelude-ls
{
	returnA, bindA, fbindA, ffmapA, fmapA, sequenceA, foldA, filterA,
	filterL
} = require \./compositions

# #### limit
# Utility to create the parallel-limited version of the asynchronous functions.

# 	limit :: ((a -> CB b) -> [a] -> CB c) -> 
#			 	((a -> CB b) -> [a] -> CB c) -> 
#			 	(c -> d) ->
#			 	Int -> 
#			 	(a -> CB b) -> [a] -> CB d
limit = (serial, parallel, projection, n, f, xs, callback) !-->
	parts = partition-in-n-parts n, xs
	(returnA parts) `bindA` (serial (parallel f)) `ffmapA` projection <| callback


# #### fst
# First item in a tuple

# 	fst :: [a, _] -> a
fst = (.0)

# #### snd
# Second item in a tuple

# 	snd :: [_, a] -> a
snd = (.1) # appreciate the irony

# #### partition-in-n-parts
# Partition the input `arr` 
# into smaller arrays of maximum `n` length.

# 	partition-in-n-parts :: Int -> [x] -> [[x]]
partition-in-n-parts = (n, arr) -->
	(arr `zip` [0 to arr.length - 1]) 
		|> (group-by ([a, i]) -> i `div` n) 
		|> obj-to-pairs 
		|> map (([_, ar]) -> (map (([a, _]) -> a), ar))


# #### once
# Ensure that the input `f` will be called maximum one time.

# 	once :: (a -> b) -> (a -> b)
once = (f) ->
	called = false
	fx = null
	(...) -> 
		return fx if called
		called := true
		fx := f ...

# ## Map

# ### parallel-map

# 	parallel-map :: (a -> CB b) -> [a] -> CB [b]
parallel-map = (f, xs, callback) !-->
	return callback null, [] if empty xs

	callback = once callback
	total = xs.length
	xs = xs `zip` [0 to total - 1]
	results = []
	call = (err) !->
		callback err, (results |> (sort-by snd) >> (map fst))

	got = (i, err, r) !-->
		if !!err
			call err
		else
			results.push [r,i]
			if results.length == total
				call null

	xs |> each ([x,i]) -> f x, (got i)


# ### serial-map
# Serial Asynchronous Map

# 	serial-map :: (a -> CB b) -> [a] -> CB [b]
serial-map = (f, xs, callback) !-->
	return callback null, [] if empty xs

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

# 	parallel-filter :: (x -> CB Boolean) -> [x] -> CB [x]
parallel-filter = (f, xs, callback) !-->
	g = (x, cb) -> 
		(returnA x) `bindA` f `ffmapA` ((fx) -> [fx, x]) <| cb

	(returnA xs) 
		|> fbindA (parallel-map g) 
		|> fmapA ((filter fst) >> (map snd)) <| callback


### serial-filter

# 	serial-filter :: (x -> CB Boolean) -> [x] -> CB [x]
serial-filter = filterA


# ### parallel-limited-filter

# 	parallel-limited-filter :: Int -> (x -> CB Boolean) -> [x] -> CB x
parallel-limited-filter = limit serial-map, parallel-filter, concat

# -----
# ## Any, All, Find

# Private utility function used to create `serial-find` and `serial-any` 

# 	serial-find-any :: (x -> CB Boolean) -> [x] -> CB [Boolean, x]
serial-find-any = (f, xs, callback) !-->
	return callback null, [false, null] if empty xs

	next = (xs, callback, i) ->
		x = xs[i]
		(err, r) <- f x
		callback err, [null, null] if !!err
		if r
			callback null, [true, x]
		else
			if i == xs.length - 1
				callback null, [false, null]
			else
				next xs, callback, i+1
	next xs, callback, 0


# Private utility function used to create `parallel-find` and `parallel-any` 

# 	parallel-any :: (x -> CB Boolean) -> [x] -> CB [Boolean, x]
parallel-find-any = (f, xs, callback) !-->
	return callback null, [false, null] if empty xs

	callback = once callback
	how-many-got = 0

	call = (err, res) ->
		callback err, res
	total = xs.length

	got = (err, [res, x]) -> 
		how-many-got := how-many-got + 1
		return call err, [false, null] if !!err
		return call null, [res, x] if res 
		return call null, [false, null] if how-many-got == total

	xs |> each ((x) -> 
		(err, res) <- f x
		got err, [res, x]
	)


# ### parallel-any

# 	parallel-any :: (x -> CB Boolean) -> [x] -> CB Boolean
parallel-any = (f, xs, callback) !-->
	(parallel-find-any f, xs) `ffmapA` fst <| callback


# ### serial-any

# serial-any :: (x -> CB Boolean) -> [x] -> CB Boolean
serial-any = (f, xs, callback) !-->
	(serial-find-any f, xs) `ffmapA` fst <| callback


# ### parallel-limited-any

# 	parallel-limited-any :: Int -> (x -> CB Boolean) -> [x] -> CB Boolean
parallel-limited-any = limit serial-any, parallel-any, id


# Private utility function: `all f = not any (not . f)`

#	 make-all-by-any :: ((x -> CB Boolean) -> [x] -> Boolean) -> (x -> CB Boolean) -> [x] -> CB Boolean
make-all-by-any = (which-any, f, xs, callback) !-->
	g = (x, cb) ->
		(returnA x) `bindA` f `ffmapA` (not) <| cb
	(returnA xs) `bindA` (which-any g) `ffmapA` (not) <| callback


# ### parallel-all

# 	parallel-all :: (x -> CB Boolean) -> [x] -> CB Boolean
parallel-all = make-all-by-any parallel-any


# ### serial-all

# 	serial-all :: (x -> CB Boolean) -> [x] -> CB Boolean
serial-all = make-all-by-any serial-any


# ### parallel-limited-all

# 	parallel-limited-all :: Int -> (x -> CB Boolean) -> [x] -> CB Boolean
parallel-limited-all = limit serial-all, parallel-all, id


# ### parallel-find

#	paralel-find :: (x -> CB Boolean) -> [x] -> CB x
parallel-find = (f, xs, callback) !-->
	(parallel-find-any f, xs) `ffmapA` snd <| callback


# ### serial-find

#	serial-find :: (x -> CB Boolean) -> [x] -> CB x
serial-find = (f, xs, callback) !-->
	(serial-find-any f, xs) `ffmapA` snd <| callback


# -----

# ### Sort

# ## parallel-sort-by
# Sorts a list using the inputted function for making the comparison between the items.

# 	parallel-sort-by :: (a -> CB b) -> [a] -> CB [a]
parallel-sort-by = (f, xs, callback)  !-->
	g = (x, cb) -> 
		(returnA x) `bindA` f `ffmapA` ((fx) -> [fx, x]) <| cb

	(returnA xs) 
		|> fbindA (parallel-map g) 
		|> fmapA (sort-by fst) >> (map snd) <| callback


# #### subsets-of-size

# 	subsets-of-size :: [b] -> Int -> [[b]]
subsets-of-size = ([x, ...xs]:set, k) ->
	| k == 0    => [[]]
	| empty set => []
	| otherwise => ([x] ++) `map` (xs `subsets-of-size` (k - 1)) ++ xs `subsets-of-size` k


# ### parallel-sort-with
# Takes a binary function which compares two items and returns either
# a positive number, 0, or a negative number, and sorts the inputted list
# using that function. 

# 	parallel-sort-with :: (a -> a -> CB i) -> [a] -> CB [a]
parallel-sort-with = (f, xs, callback) !-->
	compareA = ([[a,ia],[b, ib]], cb) !-->
		(err, c) <- f a, b
		return cb err, null if !!err
		cb null, [ia, ib, c]

	ilist = xs `zip` [0 to xs.length - 1]

	returnA (ilist `subsets-of-size` 2) # [[[o, i]]]
		|> fbindA parallel-map compareA
		|> fmapA (cs) -> 
			compare = ([a,ia],[b,ib]) ->
				[_,_,c] = find (([x,y,_]) -> x == ia and y == ib), cs
				c
			ilist.concat!.sort compare .map ([i,_]) -> i
		<| callback

#
#

# ## Control Flow

# 	serial-sequence :: [CB x] -> CB [x]
serial-sequence = (..., callback) !-> sequenceA ... <| callback


# ### parallel-sequence
# Run its sole input (a tasks array of functions) in parallel, 
# without waiting until the previous function has completed. 
# If any of the functions pass an error to its callback, 
# the main callback is immediately called with the value of the error. 
# Once the tasks have completed, the results are passed to the final callback as an array.

# 	parallel-sequence :: [CB x] -> CB [x]
parallel-sequence = (fs, callback) !-> parallel-map ((f, cb) -> f cb), fs <| callback


# ### parallel-limited-sequence

# 	parallel-limited-sequence :: Int -> [CB x] -> CB [x]
parallel-limited-sequence = limit serial-map, sequenceA, concat


# ### parallel-apply-each

# 	parallel-apply-each :: x -> [x -> CB y] -> CB [y]
parallel-apply-each = (x, fs, callback) !--> parallel-sequence (map (<| x), fs), callback


# ### serial-apply-each

# 	serial-apply-each :: x -> [x -> CB y] -> CB [y]
serial-apply-each = (x, fs, callback) !--> serial-sequence (map (<| x), fs), callback


# ### parallel-limited-apply-each

# 	parallel-limited-apply-each :: x -> [x -> CB y] -> CB [y]
parallel-limited-apply-each = limit serial-map, parallel-apply-each, concat


# ### Waterfall

# 	waterfall :: x -> (x -> CB x) -> CB x

waterfall = (x, fs, callback) -->
	g = (a, y, cb) --> y a, cb
	foldA g, x, fs <| callback


# ### serial-fold

# 	serial-fold :: (a -> b -> m a) -> a -> [b] -> m a
serial-fold = (..., callback) -> foldA ... <| callback




exports = exports or this

exports.partition-in-n-parts = partition-in-n-parts

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

exports.parallel-find = parallel-find
exports.serial-find = serial-find

exports.parallel-sort-by = parallel-sort-by
exports.parallel-sort-with = parallel-sort-with

exports.serial-sequence = serial-sequence
exports.parallel-sequence = parallel-sequence
exports.parallel-limited-sequence = parallel-limited-sequence

exports.parallel-apply-each = parallel-apply-each
exports.serial-apply-each = serial-apply-each
exports.parallel-limited-apply-each = parallel-limited-apply-each

exports.waterfall = waterfall
