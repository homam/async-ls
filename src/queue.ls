{find} = require \prelude-ls
{memorize-monad} = require \./monads
SuperLazyPromise = require \./superlazypromise

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
		return false if @runningTasks.length >= @concurrency
		self = this
		task._index = (@runningTasks.push task.go!) - 1
		task.then ->
			self.runningTasks.splice task._index, 1
			self._tryRunNext!
		task.catch ->
			self.runningTasks.splice task._index, 1
			self._tryRunNext!
		true

				
	add: (task) ~>
		if not @_tryRun task
			@queuedTasks.push task
		this


double = (x) ->
	new SuperLazyPromise (res, rej) !->
		setTimeout !->
			if x == 30 
				rej 'err at 30'
			else
				res x*2
		, 500

logP = (p) ->
	p.then !-> console.log \=, it
	p.catch !-> console.log \^, it
	p


queue = new Queue 2

# doubles = [(
# 	(double n).catch(-> console.log "double #n^", it)
# 		|> SuperLazyPromise.monad.fmap (-> console.log "double #n=", it)
# 	) for n in [15 to 35]]
# for d in doubles
# 	queue.add d



doubles = [(
	(memorize-monad.pure n) 
		|> memorize-monad.fmap double
		|> ([y,x]) ->
			y.catch(-> console.log "double #x^", it)
			y.then (-> console.log "double #x=", it)
	) for n in [15 to 35]]
for d in doubles
	queue.add d



