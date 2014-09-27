cli                 = require 'cli'
sys                 = require 'sys'

{ htmlResponse }    = require '../src/http_utils'
renderer            = require '../src/renderer'
rest                = require 'restler'
markdown            = require 'markdown'


getGist = (url, cb) ->
    GIST_API = 'https://api.github.com/gists'

    # Adding these parameters greatly increases the rate limit.
    if process.env.GITHUB_CLIENT_ID and process.env.GITHUB_CLIENT_SECRET
        params =
            client_id       : process.env.GITHUB_CLIENT_ID
            client_secret   : process.env.GITHUB_CLIENT_SECRET
    else
        params = null

    post_req = rest.get GIST_API + url,
        query: params

    post_req.on 'error', (err, response) ->
        sys.puts('getGist error:')
        sys.puts(err)
        sys.puts(response)
    post_req.on 'complete', (data, response) ->
        cb(data, response)



handleIndex = (request, response, next) ->
    if request.url is '/'
        response.writeHead 303,
            'Location': 'https://github.com/marquee/proto'
        response.end()
    else
        next()

validGist = (files) ->
    for f in ['script.coffee', 'markup.jade', 'style.styl', 'settings.json', 'notes.md']
        if not files?[f]?
            return false
    return true

protoDisplayTag = (url, gist_data) ->
    TAG_STYLE = 'font-size: 10px; padding:0 0.25em;position:fixed;bottom: 0;border: 1px solid #ccc;opacity: 0.7;background: white; font-family: Menlo, Inconsolata, Courier New, monospace;'

    tag_html = ''
    tag_html = """
        <div id="Proto-cli-tag" style="left: 0;#{ TAG_STYLE }">
            <a href="http://proto.es">proto.es</a>: <a href="https://gist.github.com#{ url }">gist.github.com#{ url }</a>
            <script>
                function _ProtoChangeVersion(select) {
                    var url = "/#{ gist_data.id }/";
                    var selected_history = select.options[select.selectedIndex];
                    window.location = url + selected_history.value;
                }
            </script>
            <select onchange="_ProtoChangeVersion(this)">
    """
    if url.split('/').length > 2
        tag_html += "<option value=''>Latest &raquo;</option>"
    else
        tag_html += "<option value='' disabled>On Latest Revision</option>"
    for entry in gist_data.history
        if '/' + gist_data.id + '/' + entry.version is url
            selected = 'selected'
        else
            selected = ''
        tag_html += "<option value='#{ entry.version }' #{ selected }>#{ entry.version.substring(0,8) }: #{ new Date(entry.committed_at) }</option>"

    tag_html += """
            </select>
        </div>
    """

    notes_content = markdown.parse(gist_data.files['notes.md'].content)


    tag_html += """
        <iframe id="Proto-notes-box" style="display: none;z-index: 9999; position: fixed; left: 0; top: 0;height: 100%;width: 100%;background:rgba(255,255,255,0.8); border: 0;"></iframe>

        <div id="Proto-frame-content" style="display:none;">
            <div style="font-family: Georgia;margin: 10px auto 0; max-width: 40em; border: 1px solid #ccc; padding: 1em; font-size: 16px; background: white;">
                <code>notes.md</code><button onclick="_ProtoHideNotes()" style="float: right;">Hide</button><br><hr>
                #{ notes_content }
            </div>
            <script>
                function _ProtoHideNotes() {
                    parent.document.getElementById('Proto-notes-box').style.display = 'none';
                }
            </script>
        </div>
        <div id="Proto-notes-tag" style="right: 0;#{ TAG_STYLE }">
            <script>
                (function(){
                    var _Proto_frame_source = document.getElementById('Proto-frame-content').innerHTML;
                    var _Proto_notes_frame = document.getElementById('Proto-notes-box').contentWindow.document;
                    _Proto_notes_frame.open();
                    _Proto_notes_frame.write(_Proto_frame_source);
                    _Proto_notes_frame.write('<style>blockquote { font-style: italic; }</style>')
                    _Proto_notes_frame.close();
                })();
                function _ProtoShowNotes() {
                    document.getElementById('Proto-notes-box').style.display = 'block'
                }
            </script>
            <button onclick="_ProtoShowNotes()">notes</button>
        </div>
    """


    # Add gaug.es tracking code
    if gist_data.public and process.env.GAUGES
        tag_html += """
            <script type="text/javascript">
              var _gauges = _gauges || [];
              (function() {
                var t   = document.createElement('script');
                t.type  = 'text/javascript';
                t.async = true;
                t.id    = 'gauges-tracker';
                t.setAttribute('data-site-id', '#{ process.env.GAUGES }');
                t.src = '//secure.gaug.es/track.js';
                var s = document.getElementsByTagName('script')[0];
                s.parentNode.insertBefore(t, s);
              })();
            </script>
        """
    return tag_html

handleRequests = (request, response, next) ->
    if request.url is '/favicon.ico'
        response.writeHead(404)
        response.end()
    else
        # The GitHub API doesn't handle trailing slashes, so trim them.
        url = request.url
        if url[url.length - 1] is '/'
            url = url.substring(0, url.length - 1)

        getGist url, (data, github_response) ->
            if github_response?.statusCode is 200 and validGist(data.files)
                content = renderer
                    style       : data.files['style.styl'].content
                    script      : data.files['script.coffee'].content
                    markup      : data.files['markup.jade'].content
                    settings    : JSON.parse(data.files['settings.json'].content)
                    extra_body  : protoDisplayTag(url, data)
                htmlResponse(request, response, content)
            else
                raw_response = github_response?.raw.toString()
                try
                    github_response_content = JSON.stringify((JSON.parse(raw_response)), null, 4)
                catch e
                    github_response_content = raw_response
                content = """
                    <style>
                        body {font-family: Menlo, Inconsolata, Courier New, monospace;}
                    </style>
                    Valid <a href="https://github.com/marquee/proto">Proto</a> Gist not found at
                    <a href="https://gist.github.com#{ url }">gist.github.com#{ url }</a>:
                    <br><br>
                    <pre style="border: 1px solid #d3d4c7;background: #fdf6e3;padding: 1em;overflow-x: scroll;"><code>
                    <a href="https://api.github.com/gists#{ url }">GET https://api.github.com/gists#{ url }</a>
                    #{ github_response?.statusCode }
                    <hr style="border: 0;border-top: 1px solid #d3d4c7;">
                    #{ github_response_content }
                    </code></pre>
                """
                htmlResponse(request, response, content, 404)


process.env.RUNNING_APP = true

port = process.env.PORT or 5000

cli.createServer([
    handleIndex
    handleRequests
]).listen(port)


