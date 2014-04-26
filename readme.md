# async-ls

This library provides powerful higher-order functions and other utilities
for working with asynchronous functions with callbacks or ES6 promises.

Callback utility functions are in 

	{callbacks} = require \async-ls
	
and promise based functions are in 

	{promises} = require \async-ls
	
There's also a monad library accessible by:

    {monads} = require \async-ls
	
Callback and promise functions are similar in their input arguments and their result. Callback functions return a callback function with the signature of `(error, result) -> void` and promise functions return a `Promise` object.

To get the individual functions use LiveScript pattern matching syntax:

    {
    	promises: {
    		LazyPromise, parallel-map, parallel-limited-filter
    	},
    	monads: {
    	    filterM, liftM
    	}
    } = require \async-ls

To build:

    make build
    
Build for browsers (using Browserify):

    async-browser.js
    
Build for browsers (callbacks library only):

    make callbacks-browser.js 
    
Build for browsers (promises library only):

    make promises-browser.js

To test:

    ./test.sh


# Monads

    {monads} = require \async-ls

### monadize
Monads work best in statically typed languages. To make monadic functions
work in LiveScript, we need to pass the type of the monad to many of the monadic operations.
`monadize` encapsulates the monad's type: `return` aka `pure`, `fmap` and `bind` functions.

    monadize :: 
        (a -> m a) ->                   # pure
        ((a -> b) -> m a -> m b) ->     # fmap
        (m a -> (a -> m b) -> m b) ->   # bind
        Monad



### kcompM
Left-to-right Kleisli composition of monads.

	kcompM :: (Monad m) => (a -> m b) -> (b -> m c) -> (a -> m c)



### joinM
Remove one level of monadic structure, projecting its bound argument into the outer level.
	
	(Monad m) => m m x -> m x



### filterM
Filter the list by applying the predicate function to 
each of its element one-by-one in serial order.
	
	filterM :: (Monad x) => (x -> m Boolean) -> [x] -> m [x]



### foldM
The `foldM` function is analogous to `foldl`, except that its result is
encapsulated in a monad.
	
	foldM :: (Monad a) => (a -> b -> m a) -> a -> [b] -> m a



### sequenceM
Evaluate each action in the sequence from left to right,
and collect the results.
	
	sequenceM :: (Monad x) => [m x] -> m [x]



### mapM
It is equivalent to `sequenceM . (map f)`.
	
	(Monad m) => (x -> m x) -> [x] -> m [x]



### liftM
Promote a function to a monad.
	
	liftM  :: (Monad m) => (a -> r) -> m a -> m r



### liftM2
Promote a function to a monad, scanning the monadic arguments from
left to right.
	
	liftM2 :: (Monad m) => (a1 -> a2 -> r) -> m a1 -> m a2 -> m r



### ap
``monad.pureM f `ap` x1 `ap` ... `ap` `` is equivalent to `(liftMn monad) f x1 x2 ... xn`
	
	ap :: (Monad m) => m (a -> b) -> m a -> m b



### Some Monad Instances:

    list-monad :: Monad     # []
	
	either-monad :: Monad   # [error, right]
	
	writer-monad :: Monad   # [value, monoid]
	



# Promises

    {promises} = require \async-ls


## Lazy Promise
`LazyPromise` only starts getting evaluated after `then` is called.

    LazyPromise : Promise


## Compositions

    promise-monad :: Monad

### returnP
Inject a value into a promise.

	returnP :: x -> Promise x



### fmapP
Map a normal function over a promise.

	fmapP :: (x -> y) -> Promise x -> Promise y



### ffmapP
`fmapP` with its arguments flipped.

	ffmapP :: Promise x -> (x -> y) -> Promise y



### bindP
Sequentially compose two promises, passing the value produced
by the first as an argument to the second.

	bindP :: Promise x -> (x -> Promise y) -> Promise y



### fbindP
`bindP` with its arguments flipped.

	fbindP :: (x -> Promise y) -> Promise x -> Promise y



### filterP
Filter the list by applying the promise predicate function to 
each of its element one-by-one in serial order.

	filterP :: (x -> Promise Boolean) -> [x] -> Promise [x]



### foldP
The `foldP` function is analogous to `foldl`, except that its result is
encapsulated in a promise.

	foldP :: (a -> b -> Promise a) -> a -> [b] -> Promise a



### sequenceP
Run its input (an array of `Promise` s) in parallel
(without waiting for the previous promise to fulfill),
and return the results encapsulated in a promise.

The returned promise immidiately gets rejected,
if any of the promises in the input list fail.

	sequenceP :: [Promise x] -> Promise [x]



## Lists


### parallel-map

	parallel-map :: (a -> Promise b) -> [a] -> Promise [b]



### serial-map

	serial-map :: (a -> Promise b) -> [a] -> Promise [b]



### parallel-limited-map

	parallel-limited-map :: Int -> (x -> Promise y) -> [x] -> Promise [y]



### parallel-filter

	parallel-filter :: (x -> m Boolean) -> [x] -> m [x]



### serial-filter
Synonym for `filterP`

	serial-filter :: (x -> Promise Boolean) -> [x] -> Promise [x]



### parallel-limited-filter

	parallel-limited-filter :: Int -> (x -> Promise Boolean) -> [x] -> Promise x



### parallel-any
Run the boolean predicate (that is encapsulated in a promise) on the list in parallel.
The returned promise fulfills as soon as a matching item is found with `true`,
otherwise `false` if no match was found.

	parallel-any :: (x -> Promise Boolean) -> [x] -> Promise Boolean



### serial-any

	serial-any :: (x -> m Boolean) -> [x] -> m Boolean



### parallel-limited-any

	parallel-limited-any :: Int -> (x -> Promise Boolean) -> [x] -> Promise Boolean



### parallel-all

	parallel-all :: (x -> Promise Boolean) -> [x] -> Promise Boolean



### serial-all

	serial-all :: (x -> Promise Boolean) -> [x] -> Promise Boolean



### parallel-limited-all

	parallel-limited-all :: Int -> (x -> Promise Boolean) -> [x] -> Promise Boolean



### parallel-find
Run the boolean predicate (that is encapsulated in a promise) on the list in parallel.
The returned promisefulfills as soon as a matching item is found with the
matching value, otherwise with `null` if no match was found. 

	parallel-find :: (x -> Promise Boolean) -> [x] -> m 



### serial-find

	serial-find :: (x -> Promise Boolean) -> [x] -> m x



### parallel-limited-find

	parallel-limited-find :: Int -> (x -> Promise Boolean) -> [x] -> Promise x



### parallel-sequence
Synonym for `sequenceP`

	parallel-sequence :: [Promise x] -> Promise [x]



### serial-sequence
The serial version of `sequenceP`.

To run the list one by one in a serial order, its items
must be instances of `LazyPromise` type.
This function runs the list in parallel, if it is a list 
of normal `Promise` s.

	serial-sequence :: [LazyPromise x] -> LazyPromise [x]



### parallel-limited-sequence

	parallel-limited-sequence :: Int -> [LazyPromise x] -> LazyPromise [x]



### parallel-apply-each

	parallel-apply-each :: x -> [x -> Promise y] -> Promise [y]



### serial-apply-each

	serial-apply-each :: x -> [x -> Promise y] -> Promise [y]



### parallel-limited-apply-each

	parallel-limited-apply-each :: x -> [x -> Promise y] -> Promise [y]



### parallel-sort-by
Sort the list using the given function for making the comparison between the items.

	parallel-sort-by :: (a -> Promise b) -> [a] -> Promise [a]



### parallel-sort-with
`parallel-sort-with` takes a binary function which compares two items and returns either
a positive number, 0, or a negative number, and sorts the inputted list
using that function. 

	parallel-sort-with :: (a -> a -> Promise i) -> [a] -> Promise [a]



### waterfall

	waterfall :: x -> (x -> Promise x) -> Promise x



### transform-promise-either
Bind a promise monad to an either monad. The result is a promise monad. 
Since we can think of promise as a superset of either in the way it handles errors.

	transform-promise-either :: Promise x -> (x -> Either y) -> Promise y



### ftransform-promise-either
`transform-promise-either` with its arguments flipped.

	ftransform-promise-either :: (x -> Either y) -> Promise x -> Promise y



### transform-either-promise
Bind an either monad to a promise monad.

	transform-either-promise :: Either x -> (x -> Promise y) -> Promise y



### ftransform-either-promise
`transform-either-promise` with its arguments flipped.

	ftransform-either-promise :: (x -> Promise y) -> Either x -> Promise y



### to-callback
Convert the promise object to a callback with the signature of `(error, result) -> void`

	Promise x -> CB x



### from-value-callback
Make a promise object from a callback with the signature of `(result) -> void`, like `fs.exist`

	Cb x -> Promise x



### from-error-value-callback
Make a promise object from a callback with the signature of `(error, result) -> void`, like `fs.stat`

	CB x -> Promise x



### from-named-callbacks
Make a promise object from `obj`.

	String -> String -> obj -> Promise x

---

---

---

# Callbacks
These functions are analogous to their promise-based counterparts that are documented above.
But instead of a `Promise` their last argument is a callback. You can think of curried version of these functions as functions that return a function that takes `callback`.

    {callbacks} = require \prelude-ls

## Convention

This would be our definition of asynchronous functions:
> If function `f` returns function `g` and `g` takes a `callback` as its only argument; then `f` is an asynchronous function.

Our callbacks will always receive two parameters: `(error, result)`.

Here `CB a` stands for a callback function with signature: `(err, a) -> void`
You can get the result of an asynchronous function (with a `callback` of type of `CB a`) by:

	(err, a) <- f

## Composition of Asynchronous Actions

### returnA
Inject a value into an asynchronous action.

	returnA :: x -> CB x


### fmapA
Map a normal function over an asynchronous action.

	fmapA :: (x -> y) -> CB x -> CB y


### ffmapA
fmapA with its arguments flipped

	ffmapA :: CB x -> (x -> y) -> CB y


### bindA
Sequentially compose two asynchronous actions, passing the value produced
by the first as an argument to the second.

	bindA :: CB x -> (x -> CB y) -> CB y


### fbindA
bindA with its arguments flipped

	fbindA :: (x -> CB y) -> CB x -> CB y

### kcompA
Similar to Left-to-right Kleisli composition, `kcompA` composes
two asynchronous actions passing the value produced
by the first as an argument to the second. The result is a new
asynchronous function that takes the argument of the first function.

	kcompA :: (x -> CB y) -> (y -> CB z) -> (x -> CB z)


### foldA
The `foldA` function is analogous to `foldl`, except that its result is
encapsulated in an asynchronous callback.

	foldA :: (a -> b -> m a) -> a -> [b] -> m a


### sequenceA
Evaluate each action in the sequence from left to right,  and collect the results.

	sequenceA :: [CB x] -> CB [x]


### filterA
Filter the list by applying the asynchronous predicate function.

	filterA :: (x -> CB Boolean) -> [x] -> CB [x]



## Either

### returnE
Inject a value into an either action.

	returnE :: x -> Either x

### fmapE
    fmapE :: (x -> y) -> Either x -> Either y


### fmapE
    ffmapE :: Either x -> (x -> y) -> Either y


### bindE

    bindE :: Either x -> (x -> Either y) -> Either y

### bindE

    bindE :: (x -> Either y) -> Either x -> Either y


### kcompE

Left to right Kleisli composition
    
    kcompE :: (x -> Either y) -> (y -> Either z) -> (x -> Either z)


### foldE

    foldE :: (a -> b -> Either a) -> a -> [b] -> Either a


### sequenceE

    sequenceE :: [Either x] -> Either [x]


### transformAE

    transformAE :: CB x -> (x -> Either y) -> CB y


### ftransformAE

    ftransformAE :: (x -> Either y) -> CB x -> CB y

### transformEA

    transformEA :: Either x -> (x -> CB y) -> CB y

### ftransformEA

    ftransformEA :: (x -> CB y) -> Either x -> CB y


# Lists

## Map

### parallel-map

	parallel-map :: (a -> CB b) -> [a] -> CB [b]


### serial-map
Serial Asynchronous Map

	serial-map :: (a -> CB b) -> [a] -> CB [b]


### parallel-map-limited
Similar to `parallel-map`, only no more than 
`limit` iterators will be simultaneously running at any time.

	parallel-map-limited :: Int -> (x -> CB y) -> [x] -> CB [y]


## Filter

### parallel-filter

	parallel-filter :: (x -> CB Boolean) -> [x] -> CB [x]


### serial-filter

	serial-filter :: (x -> CB Boolean) -> [x] -> CB [x]


### parallel-limited-filter

	parallel-limited-filter :: Int -> (x -> CB Boolean) -> [x] -> CB x


## Any, All, Find


### parallel-any

	parallel-any :: (x -> CB Boolean) -> [x] -> CB Boolean


### serial-any

serial-any :: (x -> CB Boolean) -> [x] -> CB Boolean


### parallel-limited-any

	parallel-limited-any :: Int -> (x -> CB Boolean) -> [x] -> CB Boolean


### parallel-all

	parallel-all :: (x -> CB Boolean) -> [x] -> CB Boolean


### serial-all

	serial-all :: (x -> CB Boolean) -> [x] -> CB Boolean


### parallel-limited-all

	parallel-limited-all :: Int -> (x -> CB Boolean) -> [x] -> CB Boolean


### parallel-find

	paralel-find :: (x -> CB Boolean) -> [x] -> CB x


### serial-find

	serial-find :: (x -> CB Boolean) -> [x] -> CB x


## Sort

### parallel-sort-by
Sorts a list using the inputted function for making the comparison between the items.

	parallel-sort-by :: (a -> CB b) -> [a] -> CB [a]


### parallel-sort-with
Takes a binary function which compares two items and returns either
a positive number, 0, or a negative number, and sorts the inputted list
using that function. 

	parallel-sort-with :: (a -> a -> CB i) -> [a] -> CB [a]


## Control Flow

### serial-sequence
	serial-sequence :: [CB x] -> CB [x]


### parallel-sequence
Run its sole input (a tasks array of functions) in parallel, 
without waiting until the previous function has completed. 
If any of the functions pass an error to its callback, 
the main callback is immediately called with the value of the error. 
Once the tasks have completed, the results are passed to the final callback as an array.

	parallel-sequence :: [CB x] -> CB [x]


### parallel-limited-sequence

	parallel-limited-sequence :: Int -> [CB x] -> CB [x]


### parallel-apply-each

	parallel-apply-each :: x -> [x -> CB y] -> CB [y]


### serial-apply-each

	serial-apply-each :: x -> [x -> CB y] -> CB [y]


### parallel-limited-apply-each

	parallel-limited-apply-each :: x -> [x -> CB y] -> CB [y]


### waterfall

	waterfall :: x -> (x -> CB x) -> CB x


### series-fold

	series-fold :: (a -> b -> m a) -> a -> [b] -> m a


