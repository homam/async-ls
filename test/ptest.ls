{
	returnP,
	fmapP, 
	ffmapP,
	bindP, 
	fbindP,
	filterP,

	serial-filter,
	parallel-filter,
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

	parallel-find-any
} = require \./../build/promises
{each} = require \prelude-ls
{Promise} = require \es6-promise
assert = require 'assert'
_it = it

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

count = (f) ->
	i = 0
	f >> ((fx) -> [fx, ++i])

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

double-error-at-five = (x) ->
	new Promise (res, rej) ->
		setTimeout ->
			if x is not 5 then (res x*2) else (rej 'Error at x=5')
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

less-than-ten = (x) ->
	new Promise (res, rej) ->
		setTimeout ->
			res x<10
		, 20


describe 'parallel-find-any', ->

	_it 'on [] should be [false, null] in 0 milliseconds', (done) ->
		parallel-find-any more-than-five, [] |> p-deep-equal-in-time done, [false, null], 0

	_it 'on [1 to 10] should be [true, 6] in 20 milliseconds', (done) ->
		parallel-find-any more-than-five, [1 to 10] |> p-deep-equal-in-time done, [true, 6], 20


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
		parallel-limited-find 4, more-than-five, [-20 to -1] |> p-equal-in-time done, null, 100


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
				func more-than-five, [1 to 10] |> p-deep-equal-in-time done, [6 to 10], 200

describe 'map', ->

	describe 'parallel-map', ->
		_it 'on [] should be [] in 0 milliseconds', (done) ->
			parallel-map double, [] |> p-deep-equal-in-time done, [], 0

		_it 'on double [1 to 10] should be [2 to 20] in 20 milliseconds', (done) ->
			parallel-map double, [1 to 10] |> p-deep-equal-in-time done, [i*2 for i in [1 to 10]], 20

		_it 'on double-error-at-five [1 to 10] should be an error', (done) ->
			parallel-map double-error-at-five, [1 to 10] |> p-is-error-in-time done, 20

	describe 'serial-map', ->
		_it 'on [] should be [] in 0 milliseconds', (done) ->
			serial-map double, [] |> p-deep-equal-in-time done, [], 0

		_it 'on double [1 to 10] should be [2 to 20] in 20 milliseconds', (done) ->
			serial-map double, [1 to 10] |> p-deep-equal-in-time done, [i*2 for i in [1 to 10]], 200

		_it 'on double-error-at-five [1 to 10] should be an error', (done) ->
			serial-map double-error-at-five, [1 to 10] |> p-is-error-in-time done, 100

	describe 'parallel-limited-map', ->
		_it 'on [] should be [] in 0 milliseconds', (done) ->
			parallel-limited-map 2, double, [] |> p-deep-equal-in-time done, [], 0

		_it 'on double [1 to 10] should be [2 to 20] in 20 milliseconds', (done) ->
			parallel-limited-map 2, double, [1 to 10] |> p-deep-equal-in-time done, [i*2 for i in [1 to 10]], 100

describe 'filter', ->

	describe "parallel-filter", ->
		_it "on [] should be [] on 0 milliseconds", (done) ->
			parallel-filter more-than-five, [] |> p-deep-equal-in-time done, [], 0

		_it "more-than-five on [1 to 10] should be [6 to 10] in 200 milliseconds", (done) ->
			parallel-filter more-than-five, [1 to 10] |> p-deep-equal-in-time done, [6 to 10], 20

describe 'any', ->
	describe 'serial-any', ->

		_it 'on [] should be false', (done) ->
			serial-any more-than-five, [] |> p-deep-equal-in-time done, false, 0

		_it 'on [1 to 10] should be true in 120 milliseconds', (done) ->
			serial-any more-than-five, [1 to 10] |> p-deep-equal-in-time done, true, 120

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

describe 'find', ->

	describe 'parallel-find', ->

		_it 'on [] should be null', (done) ->
			parallel-find is-five, [] |> p-equal-in-time done, null, 0

		_it 'on [1 to 10] should be 5 in 20 milliseconds', (done) ->
			parallel-find is-five, [1 to 10] |> p-equal-in-time done, 5, 20

	describe 'serial-find', ->

		_it 'on [] should be null', (done) ->
			serial-find is-five, [] |> p-equal-in-time done, null, 0

		_it 'on [1 to 10] should be 5 in 120 milliseconds', (done) ->
			serial-find is-five, [1 to 10] |> p-equal-in-time done, 5, 120

		_it 'on [1 to 10] should be 6 in 120 milliseconds', (done) ->
			serial-find more-than-five, [1 to 10] |> p-equal-in-time done, 6, 120
