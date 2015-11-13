# Description:
#   hubot is querying to dc/vertigo search engine
#
# Dependencies:
#   "string-format": "<module version>"
#   "cheerio":
#   "moment":
#
# Commands:
#   hubot current dc releases <search-key> - queries for key at dc/vertigo search engine (date +- 2 months)
#
# Author:
#   FKoehn

format = require 'string-format'
format.extend String.prototype
cheerio = require 'cheerio'
moment = require 'moment'

url_source=
  dc: 'http://www.dccomics.com'
  vertigo: 'http://www.vertigocomics.com'
  search: '/browse?content_type={type}&date={date_from}&date_end={date_to}&keyword={key}'

get_url = (publisher, obj) ->
  url = url_source[publisher]+url_source.search
  return url.format obj

prepare_key = (key) ->
  key.replace ' ', '+'
  return '"'+key+'"'

get_results = (robot, puplisher, search_options, cb) ->
  robot.http(get_url(puplisher, search_options)).get() (err, res, body) ->
    result=[]
    $ = cheerio.load body
    lis = $ 'div.browse-results-wrapper > ul > li > div.title'
    for item in lis
      elem = (($ item).find "a")
      title = elem.text()
      rel_link = elem.attr 'href'
      result.push {title: title, link: url_source[puplisher]+rel_link}
    cb result


module.exports = (robot) ->

  robot.respond /current dc releases (.*)/i, (response) ->
    search_options = {type: 'graphic_novel', date_from: moment().subtract(2, 'months').format('MM/DD/YYYY'), date_to: moment().add(2, 'months').format('MM/DD/YYYY'), key: prepare_key response.match[1]}
    handle_results = (results) ->
      for item in results
        response.send '{title} ({link})'.format item
    for publisher in ['dc', 'vertigo']
      get_results robot, publisher, search_options, handle_results
