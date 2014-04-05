SRC = $(shell find src -name "*.ls" -type f | sort)
LIB = $(SRC:src/%.ls=lib/%.js)
LSC = /usr/local/bin/lsc
BROWSERIFY = node_modules/.bin/browserify

browser:
	mkdir browser/

async-browser.js: $(LIB) browser
	{ $(BROWSERIFY) -r ./lib/index.js:async-ls -u ./node_modules/prelude-ls/lib/index.js ; } > browser/async-browser.js

lib:
	mkdir lib/

lib/%.js: src/%.ls lib
	$(LSC) --output lib --bare --compile "$<"

build: $(LIB)


clean:
	rm -rf lib
	rm -rf browser