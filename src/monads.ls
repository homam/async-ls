# # Monads

# ## Imports
{
	id, map, zip, empty, flip, fold, foldr, filter,
	concat, group-by, div, obj-to-pairs, last,
	sort-by, find, flatten
} = require \prelude-ls

# ### monadize
# Monads work best in statically typed languages. To make monadic functions
# work in LiveScript, we need to pass the type of the monad to many of the monadic opertions.
# `monadize` encapsulates the monad's type: `return` aka `pure`, `fmap` and `bind` functions.
# > monadize :: (a -> m a) ->
# > 			((a -> b) -> m a -> m b) ->
# > 			(m a -> (a -> m b) -> m b) ->
# > 			Monad
monadize = (pure, fmap, bind) ->
	pure: pure
	fmap: fmap
	bind: bind
	ffmap: flip fmap
	fbind: flip bind


# ### kcompM
# Left-to-right Kleisli composition of monads.
# kcompM :: (Monad m) => (a -> m b) -> (b -> m c) -> (a -> m c)
kcompM = (monad, f, g) --> 
	(x) -> (f x) `monad.bind` g


# ### joinM
# Remove one level of monadic structure, projecting its bound argument into the outer level.
# > (Monad m) => m m x -> m x
joinM = (monad, mx) -->
	mx `monad.bind` id


# ### filterM
# Filter the list by applying the predicate function to 
# each of its element one-by-one in serial order.
# > filterM :: (Monad x) => (x -> m Boolean) -> [x] -> m [x]
filterM = (monad, f, [x,...xs]:list) -->
	return monad.pure [] if empty list
	(f x) 
		|> monad.fbind (fx) -> 
			(filterM monad, f, xs) 
			|> monad.fbind (ys) ->
				monad.pure if fx then [x] ++ ys else ys


# ### foldM
# The `foldM` function is analogous to `foldl`, except that its result is
# encapsulated in a monad.
# > foldM :: (Monad a) => (a -> b -> m a) -> a -> [b] -> m a
foldM = (monad, f, a, [x,...xs]:list) -->
	| empty list => monad.pure a
	| otherwise => (f a, x) `monad.bind` ((fax) -> foldM monad, f, fax, xs)


# ### sequenceM
# Evaluate each action in the sequence from left to right,
# and collect the results.
# > sequenceM :: (Monad x) => [m x] -> m [x]
sequenceM = (monad, mxs) -->
	k = (m, mp) -->
		m |> monad.fbind (x) ->
			mp |> monad.fbind (xs) ->
				monad.pure ([x] ++ xs)

	foldr k, (monad.pure []), mxs

# ### mapM
# It is equivalent to `sequenceM . (map f)`.
# > (Monad m) => (x -> m x) -> [x] -> m [x]
mapM = (monad, f, xs) -->
	sequenceM monad, (map f, xs)


# ### liftM
# Promote a function to a monad.
# > liftM  :: (Monad m) => (a -> r) -> m a -> m r
liftM = (monad, f, mx) ->
	mx |> monad.fbind (x) ->
		monad.pure f x


# ### liftM2
# Promote a function to a monad, scanning the monadic arguments from
# left to right.
# > liftM2 :: (Monad m) => (a1 -> a2 -> r) -> m a1 -> m a2 -> m r
liftM2 = (monad, f, m1, m2) --> 
	m1 |> monad.fbind (x1) ->
		m2 |> monad.fbind (x2) ->
			monad.pure (f x1, x2)


# ### ap
# ``return f `ap` x1 `ap` ... `ap` `` is equivalent to `liftMn f x1 x2 ... xn`
# > ap :: (Monad m) => m (a -> b) -> m a -> m b
ap = (monad) ->  liftM2 monad, id



# ## Lists
# ### list-monad
list-monad = monadize (-> [it]), map, flip (concat . map)



# ## Either

# > pure-either :: x -> Either x
pure-either = (x) -> [null, x]

# > fmap-either :: (x -> y) -> Either x -> Either y
fmap-either = (f, [err, x]) ->
	if !!err
		[err, null]
	else
		[null, f x]

# > bind-either :: Either x -> (x -> Either y) -> Either y
bind-either = ([errf, fx], g) ->
	if !!errf then [errf, null] else g fx

# ### either-monad
either-monad = monadize pure-either, fmap-either, bind-either 


# ### Writer

# > pure-writer :: Monoid s => s -> x -> [x, s]
pure-writer = (mempty, x) --> [x, mempty]


# > fmap-writer :: (x -> y) -> [x, s] -> [y, s]
fmap-writer = (f, [x, s]) -->
	[(f x), s]

# > bind-writer :: Monoid s => s -> [x, s] -> (x -> [y, s])
bind-writer = (mappend, [x, xs], f) -->
	[y, ys] = f x
	[y, xs `mappend` ys]

# > tell-writer :: Monoid s => s -> [x, s] -> s -> [x, s]
tell-writer = (mappend, [x, xs], s) -->
	[x, xs `mappend` s]


writer-monad = (monadize pure-writer, fmap-writer, bind-writer) <<< tell: tell-writer


make-writer-monad = (mempty, mappend) ->
	(monadize (pure-writer mempty), fmap-writer, (bind-writer mappend)) <<< tell: (tell-writer mappend)


list-writer-monad = make-writer-monad [], (++)


# ### memorize-monad
# Memorize monad remembers its initial argument forever.
memorize-monad = monadize do
	((x) -> [x, x]) 
	((f, [x, s]) --> [(f x), s])
	(([x, s], f) --> [y, _] = f x; [y, s])

# exports
exports = exports or this
exports <<< {
	monadize
	filterM
	foldM
	sequenceM
	mapM
	joinM
	liftM
	liftM2
	ap

	list-monad
	either-monad
	writer-monad
	make-writer-monad
	list-writer-monad
	memorize-monad
}