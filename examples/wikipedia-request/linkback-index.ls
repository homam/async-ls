{
	promises: {
		from-error-value-callback
		from-error-values-callback
		to-callback
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


add-cache = (query, links) -->
	hash = crypto.createHash('md5').update(query).digest('hex')
	(from-error-value-callback fs.write-file) "./out/#{hash}.json", JSON.stringify {query: query, links: links}, null, 4
		|> promise-monad.fmap -> links

get-cache = (query) ->
	hash = crypto.createHash('md5').update(query).digest('hex')
	(from-error-value-callback fs.read-file) "./out/#{hash}.json", encoding: \utf8
		|> promise-monad.fmap (-> JSON.parse it .links)

cache = (query, promise-maker) ->
	new LazyPromise (res, rej) ->
		get-cache query # eat any error that get-cache might throw
			..then -> if !!it then res it else (promise-maker! `promise-monad.bind` add-cache query).then res, rej
			..catch -> (promise-maker! `promise-monad.bind` add-cache query).then res, rej

search = (query) -> 
	(from-error-values-callback ((_, body) -> body), request) "http://en.wikipedia.org/w/api.php?action=query&prop=revisions&titles=#{query}&rvprop=content&format=json"

get-links = (query) ->
	return promise-monad.pure [] if query.length < 3

	cache query, -> (search query
		|> promise-monad.fmap -> 
			JSON.parse it
			|> (.query.pages)
			|> values >> (?.0?.revisions?.0?.[\*]) 
			|> (-> it or ' ')
			|> (.match(/\[\[(.+?)\]\]/gi))
			|> (-> it or [])
			|> map (-> it.match(/^\[\[(.+?)]\]$/).1.split(/[#\|]/).0)
			|> filter (-> (it.length > 0) and (it.indexOf(':') < 0))
	)

calculate = (query) ->
	get-links query 
		|> promise-monad.fbind (links)-> 
			links |> parallel-limited-map 4, ((link) ->  (get-links link) |> promise-monad.fmap (.indexOf(query)>-1))
		|> promise-monad.fmap (-> filter (==true), it .length / it.length)

calculate 'common subexpression elimination' #'monad (functional programming)'
	..then -> console.log "Link back ratio is = #{Math.round(it*1000)/10}%"
	..catch -> console.log \err,  it