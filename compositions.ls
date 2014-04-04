
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
kcompA = (f, g) ->
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


exports = exports or this

exports.returnA = returnA
exports.bindA = bindA
exports.kcompA = kcompA

exports.returnE = returnE
exports.bindE = bindE
exports.kcompE = kcompE

exports.transformAE = transformAE
exports.transformEA = transformEA