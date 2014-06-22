{
	promises: {
		from-error-value-callback
		from-error-values-callback
		from-void-callback
		left-or-right
		promise-monad
		parallel-limited-map
		serial-map
		LazyPromise
	}
	monads: {
		memorize-monad
		list-monad
	}
} = require \./../../src/index.ls
{ map, filter, values } = require \prelude-ls
request = require \request
fs = require \fs
crypto = require \crypto


# > add-cache :: String -> [String] -> Callback (Error)
add-cache = (query, links, callback) -->
	hash = crypto.createHash \md5 .update query .digest \hex
	fs.write-file do 
		"./out/#{hash}.json"
		JSON.stringify {query: query, links: links}, null, 4
		callback

# > get-cache :: String -> Callback (Error, String)
get-cache = (query, callback) ->
	hash = crypto.createHash \md5 .update query .digest \hex
	(err, data) <- fs.read-file "./out/#{hash}.json", encoding: \utf8
	return callback err if !!err
	callback null, JSON.parse data .links

# > cache :: String -> (() -> Callback(Error, String)) -> Callback (Error, String)
cache = (query, promise-maker, callback) -->
	(_, cached) <- get-cache query
	return callback null, cached if !err
	(err, val) <- promise-maker!
	return callback err, null if !!err
	(err) <- add-cache query, val
	return callback err if !!err
	callback null, val

	query |> get-cache `left-or-right` (promise-maker `promise-monad[\>=>]` add-cache query)

# > search :: String -> Promise String
search = (query) -> 
	(from-error-values-callback ((_, body) -> body), request) do 
		"http://en.wikipedia.org/w/api.php?action=query&prop=revisions&titles=#{query}&rvprop=content&format=json"

# > get-links :: String -> Promise [String]
get-links = (query) ->
	return promise-monad.pure [] if query.length < 3

	cache do 
		query 
		-> 
			search it
			|> promise-monad.fmap -> 
				JSON.parse it
				|> (.query.pages)
				|> values >> (?.0?.revisions?.0?.[\*]) 
				|> (-> it or ' ')
				|> (.match(/\[\[(.+?)\]\]/gi))
				|> (-> it or [])
				|> map (-> it.match(/^\[\[(.+?)]\]$/).1.split(/[#\|]/).0)
				|> filter (-> (it.length > 0) and (it.index-of(':') < 0))

# > calculate :: String -> Promise Number
calculate = (query) ->
	get-links query 
		|> promise-monad.fbind parallel-limited-map 4, get-links `promise-monad[\>=>]` (promise-monad.pure . (.index-of(query)>-1))
		|> promise-monad.fmap (-> filter (==true), it .length / it.length)

calculate 'common subexpression elimination' #'monad (functional programming)'
	..then -> console.log "Link back ratio is = #{Math.round(it*1000)/10}%"
	..catch -> console.log \err,  it