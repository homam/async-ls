{
	returnP
	fmapP 
	ffmapP
	bindP 
	fbindP
	foldP
	filterP

	sequenceP

	promise-monad

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
} = require \./../lib/promises
{
	liftM
	liftM2
	ap

	monadize
	writer-monad
	make-writer-monad
	memorize-monad
} = require \./../lib/monads
{each, flip} = require \prelude-ls
Promise = require \./../lib/lazypromise
assert = require 'assert'
_it = it

ensure-maximum-concurrency = (maximum-concurrency, f) -->
	invoking = 0
	(...args) ->
		new Promise (res, rej) ->
			return rej new Error "Maximum #maximum-concurrency concurrency is broken" if invoking >= maximum-concurrency
			invoking := invoking + 1 
			(f ...args)
				..then ->
					invoking := invoking - 1
					res it
				..catch ->
					invoking := invoking - 1
					rej it


ensure-minimum-concurrency = (minimum-concurrency, f) -->
	invoking = 0
	(...args) ->
		new Promise (res, rej) ->
			invoking := invoking + 1 
			(f ...args)
				..then ->
					return rej new Error "Minimum #minimum-concurrency concurrency is broken" if invoking <= minimum-concurrency
					invoking := invoking - 1
					res it
				..catch ->
					invoking := invoking - 1
					rej it


ensure-minimum-maximum-concurrency = (minimum-concurrency, maximum-concurrency, f) -->
	invoking = 0
	(...args) ->
		new Promise (res, rej) ->
			return rej new Error "Maximum #maximum-concurrency concurrency is broken" if invoking >= maximum-concurrency
			invoking := invoking + 1 
			(f ...args)
				..then ->
					return rej new Error "Minimum #minimum-concurrency concurrency is broken (#invoking)" if invoking < minimum-concurrency
					minimum-concurrency := minimum-concurrency - 1
					invoking := invoking - 1
					res it
				..catch ->
					minimum-concurrency := minimum-concurrency - 1
					invoking := invoking - 1
					rej it

ensure-zero-concurrency = ensure-maximum-concurrency 1


p-equal = (done, expected, p) -->
	p.then -> 
		try
			assert.equal expected, it
			done!
		catch error
			done error
	p.catch -> 
		done new Error "#it"
	p

p-deep-equal = (done, expected, p) -->
	p.then -> 
		try
			assert.deep-equal expected, it
			done!
		catch error
			done error
	p.catch -> 
		done new Error "#it"
	p

p-is-error = (done, p) -->
	p.then -> 
		done new Error "Expected Error, but got #it"
	p.catch ->
		done!
	p

p-is-error-in-time = (done, expected-time, p) -->
	ts = new Date!
	p.then -> 
		done new Error "Expected Error, but got #it"
	p.catch ->
		time = new Date! - ts
		whitin-time = (expected-time - 20) < time < (expected-time + 20)
		if not whitin-time
			done new Error "Expected time = #{expected-time}, actual time = #{time}"
		else
			done!
	p

p-is-error-in-time-and-more = (done, expected-time, more, p) -->
	ts = new Date!
	p.then -> 
		done new Error "Expected Error, but got #it"
	p.catch ->
		time = new Date! - ts
		whitin-time = (expected-time - 20) < time < (expected-time + 20)
		if not whitin-time
			done new Error "Expected time = #{expected-time}, actual time = #{time}"
		else
			try 
				more!
				done!
			catch error
				done error
	p

p-time = (done, expected-time, p) -->
	ts = new Date!
	p.then ->
		try
			time = new Date! - ts
			whitin-time = (expected-time - 20) < time < (expected-time + 20)
			assert whitin-time, "Expected time = #{expected-time}, actual time = #{time}"
			done!
		catch error
			done error
	p.catch -> 
		done new Error "#it"
	p

p-equal-in-time = (done, expected, expected-time, p) -->
	ts = new Date!
	p.then ->
		try
			assert.equal expected, it
			time = new Date! - ts
			whitin-time = (expected-time - 20) < time < (expected-time + 20)
			assert whitin-time, "Expected time = #{expected-time}, actual time = #{time}"
			done!
		catch error
			done error
	p.catch -> 
		done new Error "#it"
	p

p-deep-equal-in-time = (done, expected, expected-time, p) -->
	ts = new Date!
	p.then ->
		try
			assert.deep-equal expected, it
			time = new Date! - ts
			whitin-time = (expected-time - 20) < time < (expected-time + 20)
			assert whitin-time, "Expected time = #{expected-time}, actual time = #{time}"
			done!
		catch error
			done error
	p.catch -> 
		done new Error "#it"
	p

p-deep-equal-in-time-and-more = (done, expected, expected-time, more, p) -->
	ts = new Date!
	p.then ->
		try
			assert.deep-equal expected, it
			time = new Date! - ts
			whitin-time = (expected-time - 20) < time < (expected-time + 20)
			assert whitin-time, "Expected time = #{expected-time}, actual time = #{time}"
			more!
			done!
		catch error
			done error
	p.catch -> 
		done new Error "#it"
	p


p-deep-equal-and-more = (done, expected, more, p) -->
	ts = new Date!
	p.then ->
		try
			assert.deep-equal expected, it
			more!
			done!
		catch error
			done error
	p.catch -> 
		done new Error "#it"
	p

p-is-error-and-more = (done, more, p) -->
	ts = new Date!
	p.then -> 
		done new Error "Expected Error, but got #it"
	p.catch ->
		try 
			more!
			done!
		catch error
			done error
	p



rejectP = (x) ->
	new Promise (res, rej) ->
		setTimeout ->
			rej 'error!'
		, 20

double = (x) ->
	new Promise (res, rej) ->
		setTimeout ->
			res x*2
		, 20

double-wait = (wait, x) -->
	new Promise (res, rej) ->
		setTimeout ->
			res x*2
		, wait

id-promise = (x) ->
	new Promise (res, rej) ->
		setTimeout ->
			res x
		, 20

add = (a, b) ->
	new Promise (res, rej) ->
		setTimeout ->
			res a+b
		, 20

double-error-at-n = (n, x) -->
	new Promise (res, rej) ->
		setTimeout ->
			if x is not n then (res x*2) else (rej 'Error at x=5')
		, 20

double-error-at-five = double-error-at-n 5

more-than-five = (x) ->
	new Promise (res, rej) ->
		setTimeout ->
			res x>5
		, 20

more-than-five-with-error = (error-at, x) -->
	new Promise (res, rej) ->
		setTimeout ->
			if x == error-at
				rej "Error at #x"
			else
				res x>5
		, 20

is-five = (x) ->
	new Promise (res, rej) ->
		setTimeout ->
			res x == 5
		, 20

less-than-ten = (x) ->
	new Promise (res, rej) ->
		setTimeout ->
			res x<10
		, 20

describe 'monads', ->
	describe 'liftM', ->
		_it 'on 2 + 8 = 10', (done) ->
			f = (x, y) -> x + y
			liftM2 promise-monad, f, (id-promise 2), (id-promise 8) |> p-equal done, 10


	describe 'memorize-monad', ->
		_it 'times-two 10 >>= times-two 10 should be [40, 10]', ->
			times-two = (x) -> (memorize-monad.pure x) |> (memorize-monad.fmap (*2))
			assert.deep-equal [40, 10], (times-two 10) `memorize-monad.bind` times-two


describe 'find', ->

	describe 'parallel-find', ->

		_it 'on [] should be null', (done) ->
			parallel-find is-five, [] |> p-equal-in-time done, null, 0

		_it 'on [1 to 10] should be 5 in 20 milliseconds', (done) ->
			parallel-find is-five, [1 to 10] |> p-equal-in-time done, 5, 20

		_it 'on [1 to 10] should be rejected', (done) ->
			count = 0
			more-than-five-with-error-c = (...) ->
				count := ++count
				(more-than-five-with-error 4) ...

			parallel-find more-than-five-with-error-c, [1 to 10] |> p-is-error-in-time-and-more done, 20, (-> assert.equal 10, count)

	describe 'serial-find', ->

		_it 'on [] should be null', (done) ->
			serial-find is-five, [] |> p-equal-in-time done, null, 0

		_it 'on [1 to 10] should be 5 in 120 milliseconds', (done) ->
			count = 0
			is-five-c = (...) ->
				count := ++count
				is-five ...

			serial-find (ensure-zero-concurrency is-five-c), [1 to 10] |> p-deep-equal-and-more done, 5, (-> assert.equal 5, count)

		_it 'on [1 to 10] should be 6 in 120 milliseconds with 6 calls', (done) ->
			count = 0
			more-than-five-c = (...) ->
				count := ++count
				more-than-five ...

			serial-find (ensure-zero-concurrency more-than-five-c), [1 to 10] |> p-deep-equal-and-more done, 6, (-> assert.equal 6, count)

		_it 'on [1 to 10] should be rejected', (done) ->
			count = 0
			more-than-five-with-error-c = (...) ->
				count := ++count
				(more-than-five-with-error 4) ...

			serial-find (ensure-zero-concurrency more-than-five-with-error-c), [1 to 10] |> p-is-error-and-more done, (-> assert.equal 4, count)

	describe 'parallel-limited-find', ->

		_it 'on [] should be null in 0 milliseconds', (done) ->
			parallel-limited-find 3, more-than-five, [] |> p-deep-equal-in-time done, null, 0

		_it 'on [1 to 10] should be 6 in 40 milliseconds', (done) ->
			parallel-limited-find 3, more-than-five, [1 to 10] |> p-equal-in-time done, 6, 40

		_it 'on [0 to 10] should be 6 in 60 milliseconds', (done) ->
			parallel-limited-find 3, more-than-five, [1 to 10] |> p-equal-in-time done, 6, 60

		_it 'on [1 to 20] should be 6 in 20 milliseconds', (done) ->
			parallel-limited-find 7, more-than-five, [1 to 20] |> p-equal-in-time done, 6, 20

		_it 'on [-20 to -1] should be null in 100 milliseconds', (done) ->
			parallel-limited-find 4, (ensure-minimum-maximum-concurrency 4, 4, more-than-five), [-20 to -1] |> p-equal done, null

describe 'any', ->
	describe 'serial-any', ->

		count = 0
		more-than-five-c = (...) ->
			count := ++count
			more-than-five ...

		_it 'on [] should be false', (done) ->
			serial-any more-than-five, [] |> p-deep-equal-in-time done, false, 0

		_it 'on [1 to 10] should be true in 120 milliseconds and with 6 calls', (done) ->
			serial-any (ensure-zero-concurrency more-than-five-c), [1 to 10] |> p-deep-equal-and-more done, true, (-> assert.equal 6, count)


	describe 'parallel-any', ->

		_it 'on [] should be false', (done) ->
			parallel-any more-than-five, [] |> p-deep-equal-in-time done, false, 0

		_it 'on [1 to 10] should be true in 20 milliseconds', (done) ->
			parallel-any more-than-five, [1 to 10] |> p-deep-equal-in-time done, true, 20

	describe 'parallel-limited-any', ->

		_it 'on [1 to 10] should be true in 40 milliseconds', (done) ->
			parallel-limited-any 3, more-than-five, [1 to 10] |> p-equal-in-time done, true, 40

describe 'all', ->

	describe 'parallel-all', ->

		_it 'on [] should be true', (done) ->
			parallel-all more-than-five, [] |> p-deep-equal-in-time done, true, 0

		_it 'on [10 to 1] should be false in 20 milliseconds', (done) ->
			parallel-all more-than-five, [10 to 1] |> p-deep-equal-in-time done, false, 20

	describe 'parallel-limited-all', ->

		_it 'on [10 to 1] should be true in 40 milliseconds', (done) ->
			parallel-limited-all 3, more-than-five, [10 to 1] |> p-equal-in-time done, false, 40

		_it 'on [0 to 9] should be true in 80 milliseconds', (done) ->
			parallel-limited-all 3, less-than-ten, [0 to 9] |> p-equal-in-time done, true, 80

describe 'Compositions', ->

	describe 'returnP', ->
		_it 'returnP 2 is 2', (done) ->
			(returnP 2) |> p-equal done, 2

		_it 'rejectP 2 is an error', (done) ->
			(rejectP 2) |> p-is-error done

	describe 'fmapP', ->
		_it 'fmapP and bindP should work together', (done) ->
			(returnP 10)
				|> fmapP (* 3) 
				|> fbindP double |> p-equal done, 60

		_it 'ffmapP and bindP should work together', (done) ->
			(returnP 10) `ffmapP` (* 3) `bindP` double |> p-equal done, 60

	[[filterP, 'filterP'], [serial-filter, 'serial-filter']].forEach ([func, name]) ->
		describe "#name", ->
			_it "#name on [] should be [] on 0 milliseconds", (done) ->
				func more-than-five, [] |> p-deep-equal-in-time done, [], 0

			_it "#name more-than-five on [1 to 10] should be [6 to 10] in 200 milliseconds", (done) ->
				func (ensure-zero-concurrency more-than-five), [1 to 10] |> p-deep-equal done, [6 to 10]

	describe "foldP", ->
		_it "on add, 1, [] should be 0 in 0 milliseconds", (done) ->
			foldP add, 1, [] |> p-equal-in-time done, 1, 0

		_it "on add, 0, [1 to 10] should be 55 in 20 milliseconds", (done) ->
			a = ensure-zero-concurrency add
			foldP a, 1, [1 to 10] |> p-equal done, 56

	describe 'sequenceP', ->
		_it 'on [(double 1) .. (double 10)] should be [2, 4, ..., 20] in 20 milliseconds', (done) ->
			sequenceP [(double i) for i in [1 to 10]] |> p-deep-equal-in-time done, [i*2 for i in [1 to 10]], 20

	describe 'serial-sequence', ->
		_it 'on [(double 1) .. (double 10)] should be [2, 4, ..., 20] in 200 milliseconds', (done) ->
			d = ensure-zero-concurrency double
			serial-sequence [(d i) for i in [1 to 10]] |> p-deep-equal done, [i*2 for i in [1 to 10]]

	describe 'parallel-limited-sequence', ->

		_it 'on 2, [(double 1) .. (double 10)] should be [2, 4, ..., 20] in 100 milliseconds', (done) ->
			d = ensure-minimum-maximum-concurrency 2, 2, double
			parallel-limited-sequence 2, [(d i) for i in [1 to 10]] |> p-deep-equal done, [i*2 for i in [1 to 10]]

describe 'map', ->

	describe 'parallel-map', ->
		_it 'on [] should be [] in 0 milliseconds', (done) ->
			parallel-map double, [] |> p-deep-equal-in-time done, [], 0

		_it 'on double [1 to 10] should be [2 to 20] in 20 milliseconds', (done) ->
			parallel-map (ensure-minimum-maximum-concurrency 10, 10, double), [1 to 10] |> p-deep-equal-in-time done, [i*2 for i in [1 to 10]], 20

		_it 'on double-error-at-five [1 to 10] should be an error', (done) ->
			parallel-map double-error-at-five, [1 to 10] |> p-is-error-in-time done, 20

	describe 'serial-map', ->
		_it 'on [] should be [] in 0 milliseconds', (done) ->
			serial-map double, [] |> p-deep-equal-in-time done, [], 0

		_it 'on double [1 to 10] should be [2 to 20] in 20 milliseconds', (done) ->
			d = ensure-zero-concurrency double
			serial-map d, [1 to 10] |> p-deep-equal done, [i*2 for i in [1 to 10]]

		_it 'on double-error-at-five [1 to 10] should be an error', (done) ->
			d = ensure-zero-concurrency double-error-at-five
			serial-map d, [1 to 10] |> p-is-error done

	describe 'parallel-limited-map', ->
		_it 'on [] should be [] in 0 milliseconds', (done) ->
			d = ensure-minimum-maximum-concurrency 2, 2, double
			parallel-limited-map 2, d, [] |> p-deep-equal done, []

		_it 'on double [1 to 10] should be [2 to 20] in 20 milliseconds', (done) ->
			d = ensure-minimum-maximum-concurrency 2, 2, double
			parallel-limited-map 2, d, [1 to 10] |> p-deep-equal done, [i*2 for i in [1 to 10]]

describe 'filter', ->

	describe "parallel-filter", ->
		_it "on [] should be [] on 0 milliseconds", (done) ->
			parallel-filter more-than-five, [] |> p-deep-equal-in-time done, [], 0

		_it "more-than-five on [1 to 10] should be [6 to 10] in 200 milliseconds", (done) ->
			parallel-filter more-than-five, [1 to 10] |> p-deep-equal-in-time done, [6 to 10], 20

	describe "parallel-limited-filter", ->
		_it "on [] should be [] on 0 milliseconds", (done) ->
			parallel-limited-filter 2, more-than-five, [] |> p-deep-equal-in-time done, [], 0

		_it "more-than-five on [1 to 10] should be [6 to 10] in 200 milliseconds", (done) ->
			m = ensure-minimum-maximum-concurrency 2, 2, more-than-five
			parallel-limited-filter 2, m, [1 to 10] |> p-deep-equal done, [6 to 10]

		_it "more-than-five on [1 to 10] ++ [1 to 5] ++ [6 to 10] should be [6 to 10] in 200 milliseconds", (done) ->
			m = ensure-minimum-maximum-concurrency 2, 2, more-than-five
			parallel-limited-filter 2, m, [1 to 10] ++ [1 to 5] ++ [6 to 10] |> p-deep-equal done, [6 to 10] ++ [6 to 10]
		
describe 'sort', ->

	describe 'parallel-sort-by', ->

		_it 'on [4, 6, 2, 3, 10, 2, 4, 5] should be [2, 2, 3, 4, 4, 5, 6, 10]', (done) ->
			parallel-sort-by id-promise, [4, 6, 2, 3, 10, 2, 4, 5] |> p-deep-equal-in-time done, [2, 2, 3, 4, 4, 5, 6, 10], 20


	describe 'parallel-sort-with', ->

		f = (a, b) ->
			c =
				| a>b => 1
				| a<b => -1
				| otherwise => 0
			id-promise c

		_it 'on [] should be []', (done) ->
			parallel-sort-with f, [] |> p-deep-equal-in-time done,[] , 0

		_it 'on [2, 1, 3, 2, 4, 8, 5, 12, -2] should be [ -2, 1, 2, 2, 3, 4, 5, 8, 12 ]', (done) ->
			parallel-sort-with f, [2, 1, 3, 2, 4, 8, 5, 12, -2] |> p-deep-equal-in-time done, [ -2, 1, 2, 2, 3, 4, 5, 8, 12 ] , 20

		_it 'on [2, 1, 3, 2, 4, 8, 5, 12, -2] should be rejected', (done) ->
			f = (a, b, callback) ->
				c =
					| a>b => 1
					| a<b => -1
					| otherwise => 0

				if a == 3 then 
					rejectP c 
				else 
					id-promise c

			parallel-sort-with f, [2, 1, 3, 2, 4, 8, 5, 12, -2] |> p-is-error done


describe 'apply-each', ->

	describe 'parallel-apply-each', ->

		_it 'on [] should be []', (done) ->
			parallel-apply-each 5, [] |>p-deep-equal-in-time done, [], 0

		_it 'on 10, [double, double, double] should be [20, 20] in 20 milliseconds', (done) ->
			parallel-apply-each 10, [double, double, double] |> p-deep-equal-in-time done, [20, 20, 20], 20

	describe 'serial-apply-each', ->

		_it 'on [] should be []', (done) ->
			serial-apply-each 5, [] |>p-deep-equal-in-time done, [], 0

		_it 'on 10, [double, double, double] should be [20, 20] in 60 milliseconds', (done) ->
			serial-apply-each 10, [double, double, double] |> p-deep-equal-in-time done, [20, 20, 20], 60

	describe 'parallel-limited-apply-each' , ->

		_it 'on 2, [] should be [] in 0 milliseconds', (done) ->
			parallel-limited-apply-each 2, 5, [] |>p-deep-equal-in-time done, [], 0

		_it 'on 10, [double, double, double, double, double] should be [20, 20, 20, 20, 20] in 60 milliseconds', (done) ->
			parallel-limited-apply-each 2, 10, [double, double, double, double, double] |> p-deep-equal-in-time done, [20, 20, 20, 20, 20], 60


describe 'waterfall', ->
	_it 'on 30 [] should be 30', (done) ->
		waterfall 30, [] |> p-deep-equal-in-time done, 30, 0

	_it 'on 30 [double, double, double] should be 240 in 60 milliseconds', (done) ->
		waterfall 30, [double, double, double] |> p-equal-in-time done, 240, 60

	_it 'on 30 [double, double-err, double] should be error in 40 milliseconds', (done) ->
		waterfall 30, [double, (double-error-at-n 60), double] |> p-is-error-in-time done, 40
