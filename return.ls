
# returnA :: x -> CB x
returnA = (x) -> (callback) -> callback null, x


# bindA :: CB x -> (x -> CB y) -> CB y
bindA = (f, g) ->
	(callback) ->
		(err, fx) <- f!
		if !!err 
			callback err, null
		else
			g fx, callback

# Left to right Kleisli composition
# kcompA :: (x -> CB y) -> (y -> CB z) -> (x -> CB z)
kcompA = (f, g) -->
	(x, callback) ->
		(err, fx) <- f x
		if !!err then 
			callback err, null
		else
			g fx, callback


# returnE :: x -> E x
returnE = (x) -> [null, x]


# bindE :: E x -> (x -> E y) -> E y
bindE = ([errf, fx], g) ->
	if !!errf then [errf, null] else g fx


# transformAE :: CB x -> (x -> E y) -> CB y
transformAE = (f, g) ->
	(callback) ->
		(errf, fx) <- f!
		if !!errf
			callback errf, null
		else
			[errg, gfx] = g fx
			if !!errg
				callback errg, null
			else
				callback null, gfx


# transformEA :: E x -> (x -> CB y) -> CB y
transformEA = ([errf, fx], g) ->
	(callback) ->
		if !!errf
			callback errf, null
		else
			g fx, callback


# that's it!

add1A = (x, callback) ->
	setTimeout ->
		callback null, x+1
	, 100

mult2A = (x, callback) ->
	setTimeout ->
		callback null, x*2
	, 100

divE = (y, x) --> 
	if x == 0 then ['Div by Zero', null] else [null, y/x]


logA = (err, x) !-> console.log err, x
logE = ([err, x]) !-> console.log err, x



# test E
logE <| (returnE 4) `bindE` (divE 100)


# test A
h = add1A `kcompA` mult2A
(returnA 100) `bindA` h <| logA

(returnA 10) `bindA` add1A `bindA` mult2A <| logA


# test transformAE
(returnA 3) `bindA` add1A `transformAE` (divE 4) `bindA` mult2A <| logA
h = (returnA -1) `bindA` add1A `transformAE` (divE 4) `bindA` mult2A
h logA

# test transformEA
(returnE 4) `bindE` (divE 16) `transformEA` mult2A `bindA` add1A <| logA