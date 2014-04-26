docco -o docs/html -l Linear -t docco/docco.jst -L docco/languages.json -c docco/async.css src/compositions.ls src/lists.ls
docco -o docs/markdown -l Linear -t docco/readme.jst -L docco/languages.json -c docco/async.css src/compositions.ls src/lists.ls
docco -o docs/html -l Linear -t docco/docco.jst -L docco/languages.json -c docco/async.css src/monads.ls src/lazypromise.ls src/promises.ls
docco -o docs/markdown -l Linear -t docco/readme.jst -L docco/languages.json -c docco/async.css src/monads.ls src/lazypromise.ls src/promises.ls
