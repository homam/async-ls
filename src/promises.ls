{id, map, zip, empty, flip, foldr, filter} = require \prelude-ls

{Promise} = require \es6-promise

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

filterP = (f, [x,...xs]:list) ->
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


parallel-map = (f, xs) ->
	Promise.all(map f, xs)  # equivalent to sequenceP(map f, xs)

serial-map = (f, [x, ...xs]:list) ->
	return returnP [] if empty list
	(f x)
		|> fbindP (fx) ->
			(serial-map f, xs) 
			|> fbindP (fxs) ->
				returnP [fx] ++ fxs

# 	parallel-filter :: (x -> P Boolean) -> [x] -> P [x]
parallel-filter = (f, xs) ->
	g = (x) -> 
		(f x) `ffmapP` ((fx) -> [fx, x])

	(parallel-map g, xs) 
		|> fmapP ((filter (.0)) >> (map (.1))) 



double = (x) ->
	new Promise (res, rej) ->
		setTimeout ->
			res x*2
		, 10

more-than-five = (x) ->
	new Promise (res, rej) ->
		setTimeout ->
			res x>5
		, 1

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

filterP more-than-five, [1 to 10] |> logP 'filterP'

parallel-filter more-than-five, [1 to 10] |> logP 'parallel-filter'

sequenceP [(returnP 10), (returnP 20)] |> logP 'sequenceP'

foldP add, 0 [1 to 10] |> logP 'foldP'

tp = new Date()
parallel-map double, [1 to 10] |> logP "parallel-map" |> fmapP -> console.log "parallel-map #{new Date() - tp}"

ts = new Date()
serial-map double, [1 to 10] |> logP "serial-map" |> fmapP -> console.log "serial-map #{new Date() - ts}"