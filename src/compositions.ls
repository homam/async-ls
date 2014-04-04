{fold, flip} = require \prelude-ls

# returnA :: x -> CB x
returnA = (x) -> (callback) -> callback null, x

# fmapA :: (x -> y) -> CB x -> CB y
fmapA = (f, g) ->
	(callback) ->
		(err, gx) <- g!
		if !!err
			callback err, null
		else
			callback null, (f gx)


# ffmapA :: CB x -> (x -> y) -> CB y
ffmapA = flip fmapA


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
kcompA = (f, g) ->
	(x, callback) ->
		(err, fx) <- f x
		if !!err then 
			callback err, null
		else
			g fx, callback


# returnE :: x -> E x
returnE = (x) -> [null, x]


# fmapE :: (x -> y) -> E x -> E y
fmapE = (f, [err, x]) ->
	if !!err
		[err, null]
	else
		[null, f x]


# bindE :: E x -> (x -> E y) -> E y
bindE = ([errf, fx], g) ->
	if !!errf then [errf, null] else g fx


# Left to right Kleisli composition
# kcompE :: (x -> E y) -> (y -> E z) -> (x -> E z)
kcompE = (f, g) ->
	(x) -> 
		[errf, fx] = f x
		if !!errf
			[errf, null]
		else
			g fx


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


# returnL :: x -> [x]
returnL = (x) -> [x]

# bindA :: [x] -> (x -> [y]) -> [y]
bindL = (xs, g) ->
	fold ((acc, a) -> acc ++ g a), [], xs


# returnW :: Monoid s => s -> x -> [x, s]
returnW = (mempty, x) --> [x, mempty]

# bindW :: Monoid s => s -> [x, s] -> (x -> [y, s])
bindW = (mappend, [x, xs], f) -->
	[y, ys] = f x
	[y, xs `mappend` ys]

# tellW :: Monoid s => s -> [x, s] -> s -> [x, s]
tellW = (mappend, [x, xs], s) -->
	[x, xs `mappend` s]

# returnWl :: x -> [x, []]
returnWl = returnW []

# bindWl :: [x, [s]] -> (x -> [y, [s]]) -> [y, [s]]
bindWl = bindW (++)


exports = exports or this

exports.returnA = returnA
exports.ffmapA = ffmapA
exports.bindA = bindA
exports.kcompA = kcompA

exports.returnE = returnE
exports.bindE = bindE
exports.kcompE = kcompE

exports.transformAE = transformAE
exports.transformEA = transformEA

exports.returnL = returnL
exports.bindL = bindL

exports.returnW = returnW
exports.bindW = bindW
exports.tellW = tellW

exports.returnWl = returnWl
exports.bindWl = bindWl