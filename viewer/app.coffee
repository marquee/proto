express = require 'express'

app = express()

app.get '/', (request, response) ->
  response.send('Hello World!')


port = process.env.PORT or 5000
app.listen port, ->
  console.log("Listening on " + port)

# Extract rendering/serving portion to own module shared by viewer and cli