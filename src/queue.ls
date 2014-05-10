{find} = require \prelude-ls
{memorize-monad} = require \./monads
SuperLazyPromise = require \./superlazypromise

# TODO: convert a special version of queue to a SuperLazyPromise.
# This promise resolves at _tryRunNext when both runningTasks and
# queuedTasks are empty.
class Queue
	(@concurrency = 4) ->
	runningTasks: []
	queuedTasks: []
	_tryRunNext:  ~>
		if @queuedTasks.length > 0
			return false if not @_tryRun @queuedTasks[0]
			@queuedTasks.splice 0, 1
		true
	_tryRun: (task) ~>
		#console.log \_tryRun, @runningTasks.length, @concurrency
		return false if @runningTasks.length >= @concurrency
		self = this
		task._index = (@runningTasks.push task.go!) - 1
		task.then ->
			#console.log \tthen, it
			self.runningTasks.splice task._index, 1
			self._tryRunNext!
		task.catch ->
			self.runningTasks.splice task._index, 1
			self._tryRunNext!
		true

				
	add: (task) ~>
		if not @_tryRun task
			#console.log \add-full, @queuedTasks.length+1
			@queuedTasks.push task
		task


module.exports = Queue



logP = (p) ->
	p.then !-> console.log \=, it
	p.catch !-> console.log \^, it
	p


double = (x) ->
	new SuperLazyPromise (res, rej) !->
		setTimeout !->
			if x == 30 
				rej 'err at 30'
			else
				res x*2
		, 500

double-ls = (x) ->
	new SuperLazyPromise (res, rej) !->
		setTimeout !->
			res [i*2 for i in [1 to x]]
		, 500


queue = new Queue 5


# all-doubles = (i) ->
# 	return SuperLazyPromise.monad.pure [] if i > 5
# 	(double i) 
# 		|> SuperLazyPromise.monad.fbind (di) -> 
# 			(all-doubles i+1) |> SuperLazyPromise.monad.fbind (dis) ->
# 				SuperLazyPromise.monad.pure([di] ++ dis)

all-doubles = (i) ->
	return SuperLazyPromise.monad.pure [] if i > 5
	queue.add(double i) 
		|> SuperLazyPromise.monad.fbind (di) -> 
			console.log \di, di
			queue.add(all-doubles i+1) |> SuperLazyPromise.monad.fbind (dis) ->
				SuperLazyPromise.monad.pure([di] ++ dis)

super-lazy-promise-serial-map = (f,xs) --> sequenceSLP(map f, xs)
super-lazy-promise-parallel-map = (f,xs) --> sequenceSLP(map (-> f it .go!), xs)


all-doubles-ls = (i) ->
	return SuperLazyPromise.monad.pure [] if i > 5
	(double-ls i) 
		|> SuperLazyPromise.monad.fbind (dis) -> 
			console.log \dis, i, dis
			(super-lazy-promise-parallel-map (-> (all-doubles-ls it+1).go!), dis).go! |> SuperLazyPromise.monad.fbind (diss) ->
				console.log \end, [dis] ++ diss
				SuperLazyPromise.monad.pure([dis] ++ diss)

(all-doubles-ls 1).go! |> logP 



doubles = [(
	(memorize-monad.pure n) 
		|> memorize-monad.fmap double
		|> ([y,x]) ->
			y.catch(-> console.log "double #x^", it)
			y.then (-> console.log "double #x=", it)
	) for n in [15 to 29]]
for d in doubles
	queue.add d



