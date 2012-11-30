CoffeeScript    = require 'coffee-script'
Jade            = require 'jade'
Nib             = require 'nib'
Stylus          = require 'stylus'

VERSION         = require './VERSION'



compileScriptFile = (script_source) ->
    return CoffeeScript.compile(script_source.toString())

compileMarkupFile = (markup_source) ->
    template = Jade.compile(markup_source.toString())
    return template()

compileStyleFile = (style_source) ->
    compiled_style = ''
    # This isn't actually async, just bonkers.
    Stylus(style_source.toString()).use(Nib()).render (err, data) ->
        compiled_style = data
    return compiled_style

compileScriptLibraries = (script_libraries) ->
    script_libs = ''
    for lib in script_libraries
        script_libs += "<script src='#{ lib }'></script>"
    return script_libs

compileStyleLibraries = (style_libraries) ->
    style_libs = ''
    for lib in style_libraries
        style_libs += "<link rel='stylesheet' href='#{ lib }' type='text/css'>"
    return style_libs

compileExtraHeadMarkup = (markup) ->
    if not markup
        return ''
    else
        return markup

compositePage = (ctx) ->
    page = """
    <!-- Generated by https://github.com/droptype/proto v#{ VERSION } -->
    <!doctype html>
    <html>
    <head>
        <title>(Proto) #{ ctx.title }</title>
        <meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
        #{ ctx.script_libraries }
        #{ ctx.style_libraries }
        #{ ctx.extra_head_markup }
        <style>
            #{ ctx.style }
        </style>
    </head>
    <body>
        #{ ctx.markup }
        <script>
            #{ ctx.script }
        </script>
        #{ ctx.extra_body_markup }
    </body>
    </html>
    """
    return page

doCompilation = (sources) ->
    output = compositePage
        title               : sources.settings.name
        style               : compileStyleFile(sources.style)
        script              : compileScriptFile(sources.script)
        markup              : compileMarkupFile(sources.markup)
        script_libraries    : compileScriptLibraries(sources.settings.script_libraries)
        style_libraries     : compileStyleLibraries(sources.settings.style_libraries)
        extra_head_markup   : compileExtraHeadMarkup(sources.settings.extra_head_markup)
        extra_body_markup   : sources.extra_body or ''
    return output


module.exports = (sources) ->
    return doCompilation(sources)