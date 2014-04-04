{returnA, returnE, bindA, bindE, kcompA, kcompE, transformAE, transformEA} = require \./compositions

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