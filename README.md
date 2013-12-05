Miny - A simple URL shortener
=============================

[![Build Status](https://travis-ci.org/trevorparker/miny.png?branch=master)](https://travis-ci.org/trevorparker/miny)

Miny is a simple URL shortener built on [Sinatra](http://www.sinatrarb.com/) and
[Redis](http://redis.io/), using [Grape](http://intridea.github.io/grape/) for
a RESTful API implementation.

The Sinatra web frontend uses the API anonymously when shortening a URL. While
the API can provide information about a short URL ID (sid), the Sinatra
frontend is responsible for 301 redirects for those URLs.

Configuration
-------------

Miny obeys the `RACK_ENV` environment variable, mostly to determine which Redis
DB to use. These are configurable within
`config/environments/{development,production,test}.rb`.

The site name, URL, and description can be set in `config.rb`. These are solely
used on the Sinatra frontend for page titles, headings, and URLs.

API specification
-----------------

The API is self-documenting, and can be inspected at `/v1/spec`.

Unregistered API requests are throttled to 10 requests per minute, up to 100 per
hour. API requests that pass a valid key are throttled to 50 requests per
minute, up to 500 per hour. Currently, all throttling is IP-based.
