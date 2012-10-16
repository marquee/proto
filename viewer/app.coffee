cli = require 'cli'

handleIndex = (request, response, next) ->
    console.dir(response)
    response.writeHead 200,
        'Content-Type': 'text/html'
    response.end('Hello World!')


port = process.env.PORT or 5000

cli.createServer([
    handleIndex
]).listen(port)

# Extract rendering/serving portion to own module shared by viewer and cli

# Drop express for just Stack.
# https://github.com/chriso/cli
# https://github.com/creationix/creationix/blob/master/indexer.js
# https://github.com/creationix/stack/wiki/Community-Modules
