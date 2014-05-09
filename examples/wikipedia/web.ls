{
	promises: {
		from-named-callbacks, 
		fmapP, ffmapP, parallel-map,
		promise-monad
		returnP
		sequenceP
		serial-map
		parallel-limited-map
		LazyPromise
	}
	monads: {
		memorize-monad
		list-monad
	}
} = require \async-ls
{
	join, values, id, map, unique, filter, all, any, all,
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
		

wait = (n, x) -->
	new LazyPromise (res, _) ->  
		setTimeout (-> res x), n


search = (query) -> 
	get "http://en.wikipedia.org/w/api.php?action=query&prop=revisions&titles=#{query}&rvprop=content&format=json"

get-links = (query) ->
	return wait 500, JSON.parse(localStorage.get-item query) if !!(localStorage.get-item query)
	return returnP [] if query.length < 3
	search query
		|> fmapP (-> 
			it.query.pages 
			|> values >> (?.0?.revisions?.0?.[\*]) 
			|> (-> it or ' ')
			|> (.match(/\[\[(.+?)\]\]/gi))
			|> (-> it or [])
			|> map (-> it.match(/^\[\[(.+?)]\]$/).1.split(/[#\|]/).0)
			|> filter (-> (it.length > 3) and (it.indexOf(':') < 0))
		)
		|> fmapP (->
			localStorage.set-item query, JSON.stringify(it)
			it
		)




queried-before = {}

crawl = (depth, query) -->
	# console.log depth, query, !!queried-before[query], (query.indexOf\: > -1)
	return promise-monad.pure [] if depth > 1
	return promise-monad.pure queried-before[query] if !!queried-before[query]
	return promise-monad.pure [] if query.indexOf(':') > -1
	

	get-links query |> promise-monad.fbind (ls) ->
		queried-before[query] = {name: query, links: ls}
		serial-map (crawl depth+1), ls |> promise-monad.fbind (res) ->
			queried-before[query].children = res
			$ window .trigger \crawlstep, queried-before
			{name: query, links: ls, children: res}



window.start = ->
	promis = crawl 0, 'Lazy_evaluation' #'Monad (functional programming)'
	promis.then(->
		console.log 'DONE!'
		#console.log it
		draw queried-before
	)
	promis.catch(->
		console.log 'ERROR!'
		console.log it
	)


width = 900
height = 900
$svg = d3.select \body .append \svg
	.attr \width, width
	.attr \height, height

$links-g = $svg.append \g .attr \class, \links
$nodes-g = $svg.append \g .attr \class, \nodes

$node = $nodes-g.selectAll \.node
$link = $links-g.selectAll \.link

force = d3.layout.force!
	.size [width, height]
	.on \tick, (->
		$link.attr \x1, -> it.source.x
		.attr \y1, -> it.source.y
		.attr \x2, -> it.target.x
		.attr \y2, -> it.target.y

		$node.attr \cx, -> it.x
		.attr \cy, -> it.y
	)


$ window .on \crawlstep, (_, results) ->
	draw results

rendered-nodes = []
draw = (results) ->
	nodes = values results |> map (-> {name: it.name, links: it.links}) |> (take 700)
	nodes = filter ((n) -> all ((r) -> n.name != r.name), rendered-nodes), nodes
	rendered-nodes := rendered-nodes ++ nodes

	each (([n, i])-> 
		results[n.name].index = i
	), (rendered-nodes `zip` [0 to rendered-nodes.length - 1])
	links = rendered-nodes |> list-monad.fbind (n) ->
		n.links |> list-monad.fbind (l) ->
			| !!results[n.name] and !!results[l] => [{ source: results[n.name].index, target: results[l].index }]
			| otherwise => []
			
	$link := $link.data links
		..enter!.append \line
			..attr \class, \link

	$node := $node.data rendered-nodes
		..enter!.append \circle
			..attr \class, \node
		..attr \r, (-> (filter ((l) -> any ((n) -> l == n.name), rendered-nodes), it.links).length |> (-> if it < 2 then 2 else it) |> Math.log |> (*2))
		..append \title .text (.name)

	k = Math.sqrt(rendered-nodes.length / (width * height))

	force
		.nodes rendered-nodes
		.links links
		.charge(-10 / k)
		.gravity(50 * k)
		.linkDistance(30)
		.start!




start!

