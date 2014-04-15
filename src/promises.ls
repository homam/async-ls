{id, map, zip, empty, flip, foldr, filter, concat, group-by, div, obj-to-pairs} = require \prelude-ls
{Promise} = require \es6-promise

# 	partition-in-n-parts :: Int -> [x] -> [[x]]
partition-in-n-parts = (n, arr) -->
	(arr `zip` [0 to arr.length - 1]) 
		|> (group-by ([a, i]) -> i `div` n) 
		|> obj-to-pairs 
		|> map (([_, ar]) -> (map (([a, _]) -> a), ar))


returnP = (x) ->
	Promise.resolve x

# 	fmapA :: (x -> y) -> P x -> P y
fmapP = (f, g) -->
	g.then -> f it


# 	bindA :: CB x -> (x -> CB y) -> CB y
bindP = (f, g) -->
	f.then (fx) ->
		g fx

fbindP = flip bindP

ffmapP = flip fmapP

# serial
filterP = (f, [x,...xs]:list) -->
	return returnP [] if empty list
	(f x) 
		|> fbindP (fx) -> 
			(filterP f, xs) 
			|> fbindP (ys) ->
				returnP if fx then [x] ++ ys else ys

serial-filter = filterP

# sequenceP :: [P x] -> P [x]
sequenceP = (mxs) ->
	k = (m, mp) -->
		m |> fbindP (x) ->
			mp |> fbindP (xs) ->
				returnP ([x] ++ xs)

	foldr k, (returnP []), mxs


# foldP :: (a -> b -> E a) -> a -> [b] -> E a
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

# 	parallel-filter :: (x -> P Boolean) -> [x] -> P [x]
parallel-filter = (f, xs) -->
	g = (x) -> 
		(f x) `ffmapP` ((fx) -> [fx, x])

	(parallel-map g, xs) 
		|> fmapP ((filter (.0)) >> (map (.1))) 


serial-any = (f, [x,...xs]:list) -->
	return returnP false if empty list
	(f x) 
		|> fbindP (fx) -> 
			| fx => returnP fx
			| otherwise =>
				(serial-any f, xs) 
				|> fbindP (ys) ->
					returnP ys


mplus-promise-boolean-object = (pa, pb) -->
	new Promise (success, error) ->
		pa |> fbindP ([b, o]) ->
			| b => success [b, o]
			| otherwise =>
				pb `bindP` success


msum-promise-boolean-object = (mxs) -> foldr mplus-promise-boolean-object, (returnP [false, null]), mxs


# mplus-promise-boolean = (pa, pb) -->
# 	new Promise (success, error) ->
# 		pa |> fbindP (pax) ->
# 			| pax => success true
# 			| otherwise =>
# 				pb `bindP` success

# msum-promise-boolean = (mxs) -> foldr mplus-promise-boolean, (returnP false), mxs

# parallel-any = (f, xs) --> msum-promise-boolean <| map f, xs


parallel-find-any = (f, xs) --> 
	map ((x) -> (f x) `ffmapP` (b) -> [b,x] ), xs 
		|> msum-promise-boolean-object

parallel-any = (f, xs) --> (parallel-find-any f, xs) `ffmapP` (.0)


parallel-find = (f, xs) --> (parallel-find-any f, xs) `ffmapP` (.1)




limit = (serial, parallel, projection, n, f, xs) -->
	parts = partition-in-n-parts n, xs
	(returnP parts) `bindP` (serial (parallel f)) `ffmapP` projection

parallel-map-limited = limit serial-map, parallel-map, concat

# 	parallel-limited-filter :: Int -> (x -> CB Boolean) -> [x] -> CB x
parallel-limited-filter = limit serial-map, parallel-filter, concat



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
parallel-map-limited 2, double, [1 to 10] |> logP "parallel-map-limited" |> fmapP -> console.log "parallel-map-limited #{new Date! - tl}"


do ->
	tl = new Date!
	serial-any is-five, [1 to 10] |> logP "serial-any" |> fmapP -> console.log "serial-any #{new Date! - tl}"

do ->
	tl = new Date!
	parallel-any is-five, [1 to 10] |> logP "parallel-any" |> fmapP -> console.log "parallel-any #{new Date! - tl}"

