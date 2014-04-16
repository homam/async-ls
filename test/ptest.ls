{
	returnP,
	fmapP, 
	ffmapP,
	bindP, 
	fbindP,
	filterP,

	serial-filter,
	parallel-filter,

	serial-map
	parallel-map

	parallel-limited-map
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

describe 'Map', ->

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


describe 'parallel-filter', ->

	describe "parallel-filter", ->
		_it "on [] should be [] on 0 milliseconds", (done) ->
			parallel-filter more-than-five, [] |> p-deep-equal-in-time done, [], 0

		_it "more-than-five on [1 to 10] should be [6 to 10] in 200 milliseconds", (done) ->
			parallel-filter more-than-five, [1 to 10] |> p-deep-equal-in-time done, [6 to 10], 20