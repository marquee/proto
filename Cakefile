fs              = require 'fs'
sys             = require 'sys'
CoffeeScript    = require 'coffee-script'

compileScriptFile = (from, to) ->
    sys.puts('Compiling script')
    script_source = fs.readFileSync(from)
    compiled = CoffeeScript.compile(script_source.toString())
    fs.writeFileSync(to, compiled)

task 'build', 'compile src/proto.coffee > lib/proto.js', ->
    compileScriptFile('src/proto.coffee', 'lib/proto.js')
