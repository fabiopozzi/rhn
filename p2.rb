#!/usr/bin/env ruby
require 'rubygems'
require 'nokogiri'
require 'open-uri'

#page = Nokogiri::HTML(open('/Users/fabio/Desktop/index.html'))
page = Nokogiri::HTML(open("https://news.ycombinator.com/"))
puts page.class
