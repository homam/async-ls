{
	promises: {
		from-named-callbacks
		promise-monad
		serial-map
		LazyPromise
	}
	monads: {
		memorize-monad
		list-monad
	}
} = require \async-ls
{
	join, values, id, map, unique, filter, all, any,
	obj-to-pairs, zip, each, take
} = require \prelude-ls


get = (url) ->
	options = 
		url: url
		dataType: 'jsonp'
		jsonp: 'callback'
		cache: true
	promise = from-named-callbacks \success, \error, options
	jQuery.ajax options
	promise
		



search = (query) -> 
	get "http://en.wikipedia.org/w/api.php?action=query&prop=revisions&titles=#{query}&rvprop=content&format=json"

get-links = (query) ->
	return wait 500, JSON.parse(localStorage.get-item query) if !!(localStorage.get-item query)
	return promise-monad.pure [] if query.length < 3
	search query
		|> promise-monad.fmap (-> 
			it.query.pages 
			|> values >> (?.0?.revisions?.0?.[\*]) 
			|> (-> it or ' ')
			|> (.match(/\[\[(.+?)\]\]/gi))
			|> (-> it or [])
			|> map (-> it.match(/^\[\[(.+?)]\]$/).1.split(/[#\|]/).0)
			|> filter (-> (it.length > 0) and (it.indexOf(':') < 0))
		)
		|> promise-monad.fmap (->
			localStorage.set-item query, JSON.stringify(it)
			it
		)




_get-links = (query) ->
	match query
	| 'A' => returnP <[ B C D E F ]>
	| 'B' => returnP <[ C D F G ]>
	| 'C' => returnP <[ A B C ]>
	| 'D' => returnP <[ B F G E ]>
	| 'E' => returnP <[ F G A B ]>
	| 'F' => returnP <[ A B C D E G ]>
	| 'G' => returnP <[ B E ]>

queried-before = {}

crawl = (depth, query) -->
	# console.log depth, query, !!queried-before[query], (query.indexOf\: > -1)
	return promise-monad.pure [] if depth > 2
	return promise-monad.pure queried-before[query] if !!queried-before[query]
	return promise-monad.pure [] if query.indexOf(':') > -1
	

	get-links query |> promise-monad.fbind (ls) ->
		queried-before[query] = {name: query, links: ls}
		parallel-limited-map 5, (crawl depth+1), ls |> promise-monad.fbind (res) ->
			queried-before[query].children = res
			{name: query, links: ls, children: res}



window.start = ->
	promis = crawl 0, 'Monad (functional programming)'
	promis.then(->
		console.log 'DONE!'
		#console.log it
		draw queried-before
	)
	promis.catch(->
		console.log 'ERROR!'
		console.log it
	)


draw = (results) ->
	nodes = values results |> map (-> {name: it.name, links: it.links}) |> (take 700)
	each (([n, i])-> 
		results[n.name].index = i
	), (nodes `zip` [0 to nodes.length - 1])
	links = nodes |> list-monad.fbind (n) ->
		n.links |> list-monad.fbind (l) ->
			| !!results[n.name] and !!results[l] => [{ source: results[n.name].index, target: results[l].index }]
			| otherwise => []
			

	width = 900
	height = 900
	$svg = d3.select \body .append \svg
		.attr \width, width
		.attr \height, height


	$link = $svg.selectAll \.link
		.data links
		.enter!.append \line
		.attr \class, \link

	$node = $svg.selectAll \.node
		.data nodes
		.enter!.append \circle
		.attr \class, \node
		.attr \r, (-> (filter ((l) -> any ((n) -> l == n.name), nodes), it.links).length |> (-> if it < 2 then 2 else it) |> Math.log |> (*2))
	$node.append \title .text (.name)

	k = Math.sqrt(nodes.length / (width * height))

	force = d3.layout.force!
		.nodes nodes
		.links links
		.size [width, height]
		.charge(-10 / k)
		.gravity(50 * k)
		.on \tick, (->
			$link.attr \x1, -> it.source.x
			.attr \y1, -> it.source.y
			.attr \x2, -> it.target.x
			.attr \y2, -> it.target.y

			$node.attr \cx, -> it.x
			.attr \cy, -> it.y
		)
		.start!




start!

