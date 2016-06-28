crypto  = require 'crypto'
fs      = require 'fs'
rest    = require 'restler'
util    = require 'util'

{ PRODUCTION, LIB_DIR } = require './SETTINGS'

_generateCacheKey = (url) ->
    url_hash = crypto.createHash('md5')
    url_hash.update(url)
    ext = url.split('.').pop()
    return url_hash.digest('hex') + '.' + ext

getCacheKey = (url) ->
    # Cache only works if running the local `proto` command.
    if not process.env.RUNNING_APP
        key = _generateCacheKey(url)
        if fs.existsSync(LIB_DIR + key)
            return key
        else
            return null
    else
        return null

cacheFileFromURL = (remote_path) ->
    if not fs.existsSync(LIB_DIR)
        fs.mkdirSync(LIB_DIR)

    key = _generateCacheKey(remote_path)
    target_path = LIB_DIR + key
    util.log("Getting: #{ remote_path }")
    get_req = rest.get(remote_path)
    get_req.on 'complete',  (data, response) ->
        if response.statusCode is 200
            fs.writeFile target_path, data, (err) ->
                if err?
                    util.log("Error saving #{ remote_path }: #{ err }")
                else
                    util.log("Saved: #{ remote_path }")
        else
            util.log("Error: #{ response.statusCode }")
            util.log(data)

loadFromCache = (key, cb=null) ->
    if cb?
        fs.readFile(LIB_DIR + key, 'utf8', cb)
    else
        return fs.readFileSync(LIB_DIR + key, 'utf8')

module.exports =
    getCacheKey         : getCacheKey
    cacheFileFromURL    : cacheFileFromURL
    loadFromCache       : loadFromCache