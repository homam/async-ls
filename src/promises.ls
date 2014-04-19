{
	id, map, zip, empty, flip, foldr, filter,
	concat, group-by, div, obj-to-pairs, last,
	sort-by, find
} = require \prelude-ls
{Promise} = require \es6-promise

# 	partition-in-n-parts :: Int -> [x] -> [[x]]
partition-in-n-parts = (n, arr) -->
	(arr `zip` [0 to arr.length - 1]) 
		|> (group-by ([_, i]) -> i `div` n) 
		|> obj-to-pairs 
		|> map (.1) >> map (.0)

# 	returnP :: x -> p x
returnP = (x) ->
	Promise.resolve x


# 	fmapP :: (x -> y) -> p x -> p y
fmapP = (f, g) -->
	g.then -> f it


# 	ffmapP :: p x -> (x -> y) -> p y
ffmapP = flip fmapP


# 	bindA :: p x -> (x -> p y) -> p y
bindP = (f, g) -->
	f.then (fx) ->
		g fx

# 	fbindP :: (x -> p y) -> p x -> p y
fbindP = flip bindP


# 	filterP :: (x -> p Boolean) -> [x] -> p [x]
# serial
filterP = (f, [x,...xs]:list) -->
	return returnP [] if empty list
	(f x) 
		|> fbindP (fx) -> 
			(filterP f, xs) 
			|> fbindP (ys) ->
				returnP if fx then [x] ++ ys else ys


# 	serial-filter :: (x -> p Boolean) -> [x] -> p [x]
serial-filter = filterP


# 	sequenceP :: [p x] -> p [x]
# This executes `mxs` in parallel in practice. Serial sequence requires lazy Promises
sequenceP = (mxs) ->
	k = (m, mp) -->
		m |> fbindP (x) ->
			mp |> fbindP (xs) ->
				returnP ([x] ++ xs)

	foldr k, (returnP []), mxs



# foldP :: (a -> b -> p a) -> a -> [b] -> p a
# serial
foldP = (f, a, [x,...xs]:list) ->
	| empty list => returnP a
	| otherwise => (f a, x) `bindP` ((fax) -> foldP f, fax, xs)


parallel-map = (f, xs) -->
	Promise.all(map f, xs)  # equivalent to sequenceP(map f, xs)

serial-map = (f, [x, ...xs]:list) -->
	return returnP [] if empty list
	(f x)
		|> fbindP (fx) ->
			(serial-map f, xs) 
			|> fbindP (fxs) ->
				returnP [fx] ++ fxs

# 	parallel-filter :: (x -> m Boolean) -> [x] -> m [x]
parallel-filter = (f, xs) -->
	g = (x) -> 
		(f x) `ffmapP` ((fx) -> [fx, x])

	(parallel-map g, xs) 
		|> fmapP ((filter (.0)) >> (map (.1))) 


# 	serial-find-any :: ((x, Boolean) -> [Boolean, _]) -> (x -> p Boolean) -> [x] -> p [Boolean, x]
# 	serial-find-any :: ((x, [Boolean, x]) -> [Boolean, x]) -> (x -> p Boolean) -> [x] -> p [Boolean, x]
serial-find-any = (selector, f, [x,...xs]:list) -->
	return returnP [false, null] if empty list
	(f x) 
		|> fmapP selector x 
		|> fbindP ([b, x]) -> 
			| b => returnP [b, x]
			| otherwise => (serial-find-any selector, f, xs)


# 	serial-any :: (x -> m Boolean) -> [x] -> m Boolean
serial-any = (f, xs) --> (serial-find-any ((_, b) --> [b, _]), f, xs) `ffmapP` (.0)


# 	mplus-promise-boolean-object :: m [Boolean, x] -> m [Boolean, x] -> m [Boolean, x]
mplus-promise-boolean-object = (pa, pb) -->
	new Promise (success, error) ->
		pa |> fbindP ([b, o]) ->
			| b => success [b, o]
			| otherwise => pb `bindP` success

# 	msum-promise-boolean-object :: [m [Boolean, x]] -> m [Boolean, x]
msum-promise-boolean-object = (mxs) -> foldr mplus-promise-boolean-object, (returnP [false, null]), mxs


# 	parallel-find-any :: (x -> Boolean) -> [x] -> [[Boolean, x]]
parallel-find-any = (f, xs) --> 
	map ((x) -> (f x) `ffmapP` (b) -> [b,x] ), xs 
		|> msum-promise-boolean-object


# 	parallel-any :: (x -> p Boolean) -> [x] -> p Boolean
parallel-any = (f, xs) --> (parallel-find-any f, xs) `ffmapP` (.0)

# 	parallel-find :: (x -> m Boolean) -> [x] -> m 
parallel-find = (f, xs) --> (parallel-find-any f, xs) `ffmapP` (.1)


# 	parallel-all :: (x -> p Boolean) -> [x] -> p Boolean
parallel-all = (f, xs) --> (parallel-find-any ((x) -> (f x) `ffmapP` (not)), xs) `ffmapP` ((not) . (.0))


# 	serial-all :: (x -> p Boolean) -> [x] -> p Boolean
serial-all = (f, xs) --> (serial-find-any ((_, b) --> [b, _]), ((x) --> (f x) `ffmapP` (not)), xs) `ffmapP` ((not) . (.0))


# 	serial-find :: (x -> m Boolean) -> [x] -> m x
serial-find = (f, xs) --> (serial-find-any ((x, [b, y]) --> 
	[b, y]), ((x) -> (f x) `ffmapP` ((fx) -> 
		[fx, x])), xs) `ffmapP` (.1)


limit = (serial, parallel, projection, n, f, xs) -->
	parts = partition-in-n-parts n, xs
	(returnP parts) `bindP` (serial (parallel f)) `ffmapP` projection


parallel-limited-map = limit serial-map, parallel-map, concat


# 	parallel-limited-filter :: Int -> (x -> CB Boolean) -> [x] -> CB x
parallel-limited-filter = limit serial-map, parallel-filter, concat


# 	parallel-limited-any :: Int -> (x -> CB Boolean) -> [x] -> CB Boolean
parallel-limited-any = limit serial-any, parallel-any, id


# 	parallel-limited-all :: Int -> (x -> CB Boolean) -> [x] -> CB Boolean
parallel-limited-all = limit serial-all, parallel-all, id
 

# 	parallel-limited-any :: Int -> (x -> CB Boolean) -> [x] -> CB Boolean
parallel-limited-find = limit (serial-find-any ((x, [b, y]) --> [b, y])), parallel-find-any, (.1)


# 	parallel-sort-by :: (a -> CB b) -> [a] -> CB [a]
parallel-sort-by = (f, xs)  -->
	g = (x) -> 
		(returnP x) `bindP` f `ffmapP` ((fx) -> [fx, x])

	(returnP xs) 
		|> fbindP (parallel-map g) 
		|> fmapP (sort-by (.0)) >> (map (.1))


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
parallel-sort-with = (f, xs) -->
	compareP = ([[a,ia],[b, ib]]) -->
		(f a, b)
			|> fbindP ((c) -> [ia, ib, c])

	ilist = xs `zip` [0 to xs.length - 1]

	returnP (ilist `subsets-of-size` 2) # [[[o, i]]]
		|> fbindP parallel-map compareP
		|> fmapP (cs) -> 
			compare = ([a,ia],[b,ib]) ->
				[_,_,c] = find (([x,y,_]) -> x == ia and y == ib), cs
				c
			ilist.concat!.sort compare .map ([i,_]) -> i



to-callback = (p, callback) !-->
		p.then ->
			callback null, it
		p.catch ->
			callback it, null


exports = exports || this
exports <<< {
	returnP
	fmapP 
	ffmapP
	bindP 
	fbindP
	foldP
	filterP
	sequenceP

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

	parallel-find-any
}

return

double = (x) ->
	new Promise (res, rej) ->
		setTimeout ->
			res x*2
		, 20

more-than-five = (x) ->
	new Promise (res, rej) ->
		setTimeout ->
			res x>5
		, 20

is-five = (x) ->
	new Promise (res, rej) ->
		setTimeout ->
			res x == 5
		, 20

add = (a, b) ->
	new Promise (res, rej) ->
		setTimeout ->
			res a+b
		, 1

logP = (msg, p) -->
	p.then -> console.log \===, msg, \=, it
	p.catch -> console.log \^==, msg, \=, it
	p



(returnP 10) `ffmapP` (* 2) `bindP` double |> logP 'simple'
(returnP 10)
	|> fmapP (* 2) 
	|> fbindP double |> logP 'simple monadic'

tf = new Date!
filterP more-than-five, [1 to 10] |> logP 'filterP' |> fmapP -> console.log "filterP #{new Date! - tf}"

tfp = new Date!
parallel-filter more-than-five, [1 to 10] |> logP 'parallel-filter' |> fmapP -> console.log "parallel-filter #{new Date! - tfp}"

tlp = new Date!
parallel-limited-filter 2, more-than-five, [1 to 10] |> logP 'parallel-limited-filter' |> fmapP -> console.log "parallel-limited-filter #{new Date! - tlp}"

sequenceP [(returnP 10), (returnP 20)] |> logP 'sequenceP'

foldP add, 0 [1 to 10] |> logP 'foldP'

tp = new Date!
parallel-map double, [1 to 10] |> logP "parallel-map" |> fmapP -> console.log "parallel-map #{new Date! - tp}"

ts = new Date!
serial-map double, [1 to 10] |> logP "serial-map" |> fmapP -> console.log "serial-map #{new Date! - ts}"

tl = new Date!
parallel-limited-map 2, double, [1 to 10] |> logP "parallel-limited-map" |> fmapP -> console.log "parallel-limited-map #{new Date! - tl}"


do ->
	tl = new Date!
	serial-any is-five, [1 to 10] |> logP "serial-any" |> fmapP -> console.log "serial-any #{new Date! - tl}"

do ->
	tl = new Date!
	parallel-any is-five, [1 to 10] |> logP "parallel-any" |> fmapP -> console.log "parallel-any #{new Date! - tl}"

do ->
	tl = new Date!
	parallel-all more-than-five, [6 to 10] |> logP "parallel-all" |> fmapP -> console.log "parallel-all #{new Date! - tl}"

