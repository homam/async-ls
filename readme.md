This library provides powerful higher-order functions and other utilities
for working with asynchronous functions with callbacks or ES6 promises.

The callback utility functions are available in 

	require \async-ls .callbacks
	
and promise based functions are in 

	require \async-ls .promises
	
The callbacks and promises functions are similar in their input arguments and their result. Callback functions return a callback function with the signature of `(error, result) -> void` and promise functions return a promise object.


# Promise Utilities

## Compositions
### returnP
Inject a value into a promise.
> returnP :: x -> p x



### fmapP
Map a normal function over a promise.
> fmapP :: (x -> y) -> p x -> p y



### ffmapP
`fmapA` with its arguments flipped.
> ffmapP :: p x -> (x -> y) -> p y



### bindP
Sequentially compose two promises, passing the value produced
by the first as an argument to the second.
	bindP :: p x -> (x -> p y) -> p y



### fbindP
`bindP` with its arguments flipped.
> fbindP :: (x -> p y) -> p x -> p y



### filterP
Filter the list by applying the promise predicate function to 
each of its element one-by-one in serial order.
> filterP :: (x -> p Boolean) -> [x] -> p [x]



### foldP
The `foldP` function is analogous to `foldl`, except that its result is
encapsulated in a promise.
> foldP :: (a -> b -> p a) -> a -> [b] -> p a



### sequenceP
Run its input (an array of promises) in parallel, 
without waiting until the previous promise to fulfill,
and return a the results encapsulated in a promise.

The returned promise immidiately gets rejected,
if any of the promises in the input list fail,
> sequenceP :: [p x] -> p [x]



## Lists



#### partition-in-n-parts
Private utility, Partition the input `arr` 
into smaller arrays of maximum `n` length.
> partition-in-n-parts :: Int -> [x] -> [[x]]



#### limit
Private utility, for creating parallel-limited version of `map`, `filter`, `any`, `all` and `find`.



### parallel-map
> parallel-map :: (a -> p b) -> [a] -> p [b]



### serial-map
> serial-map :: (a -> p b) -> [a] -> p [b]



### parallel-limited-map
> parallel-limited-map :: Int -> (x -> p y) -> [x] -> p [y]



### parallel-filter
> parallel-filter :: (x -> m Boolean) -> [x] -> m [x]



### serial-filter
Synonym for `filterP`
> serial-filter :: (x -> p Boolean) -> [x] -> p [x]



### parallel-limited-filter
> parallel-limited-filter :: Int -> (x -> p Boolean) -> [x] -> p x



#### mplus-promise-boolean-object
Private utility, sum two `m [Boolean, x]`, by performing logical disjunction on the first item in the tuples.
> mplus-promise-boolean-object :: m [Boolean, x] -> m [Boolean, x] -> m [Boolean, x]



#### msum-promise-boolean-object
Private utility, return the first tuple that its first item is `true`.
> msum-promise-boolean-object :: [m [Boolean, x]] -> m [Boolean, x]



#### parallel-find-any
Private utility, an abstraction for `parallel-any` and `parallel-find`.
> parallel-find-any :: (x -> Boolean) -> [x] -> [[Boolean, x]]



#### serial-find-any
Private utility, it is an abstraction of `serial-find` and `serial-any`.
> serial-find-any :: ((x, Boolean) -> [Boolean, _]) -> (x -> p Boolean) -> [x] -> p [Boolean, x]
> serial-find-any :: ((x, [Boolean, x]) -> [Boolean, x]) -> (x -> p Boolean) -> [x] -> p [Boolean, x]



### parallel-any
Run the boolean predicate (that is encapsulated in a promise) on the list in parallel.
The returned promise fulfills as soon as a matching item is found with `true`,
otherwise `false` if no match was found.
> parallel-any :: (x -> p Boolean) -> [x] -> p Boolean



### serial-any
> serial-any :: (x -> m Boolean) -> [x] -> m Boolean



### parallel-limited-any
> parallel-limited-any :: Int -> (x -> p Boolean) -> [x] -> p Boolean



### parallel-all
> parallel-all :: (x -> p Boolean) -> [x] -> p Boolean



### serial-all
> serial-all :: (x -> p Boolean) -> [x] -> p Boolean



### parallel-limited-all
> parallel-limited-all :: Int -> (x -> p Boolean) -> [x] -> p Boolean



### parallel-find
Run the boolean predicate (that is encapsulated in a promise) on the list in parallel.
The returned promisefulfills as soon as a matching item is found with the
matching value, otherwise with `null` if no match was found. 
> parallel-find :: (x -> m Boolean) -> [x] -> m 



### serial-find
> serial-find :: (x -> m Boolean) -> [x] -> m x



### parallel-limited-find
> parallel-limited-find :: Int -> (x -> p Boolean) -> [x] -> p x



### parallel-sequence
Synonym for `sequenceP`
> parallel-sequence :: [p x] -> p [x]



### serial-sequence
The serial version of `sequenceP`.

`serial-sequence` requires that its argument be a list of
`LazyPromise` instances. This function run the input list 
in parallel, if it is a list of normal promise instances.
> serial-sequence :: [p x] -> p [x]



### parallel-limited-sequence
> parallel-limited-sequence :: Int -> [p x] -> p [x]



### parallel-apply-each
> parallel-apply-each :: x -> [x -> p y] -> p [y]



### serial-apply-each
> serial-apply-each :: x -> [x -> p y] -> p [y]



### parallel-limited-apply-each
> parallel-limited-apply-each :: x -> [x -> CB y] -> CB [y]



### parallel-sort-by
Sort the list using the given function for making the comparison between the items.
> parallel-sort-by :: (a -> p b) -> [a] -> p [a]





#### subsets-of-size
Private utility, return the list of all subsets of size `k` for the given list.
> subsets-of-size :: [b] -> Int -> [[b]]



### parallel-sort-with
`parallel-sort-with` takes a binary function which compares two items and returns either
a positive number, 0, or a negative number, and sorts the inputted list
using that function. 
> parallel-sort-with :: (a -> a -> p i) -> [a] -> p [a]



### waterfall
> waterfall :: x -> (x -> p x) -> p x



### to-callback
> p x -> CB x
