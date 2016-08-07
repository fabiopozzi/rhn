#!/usr/bin/env ruby
require 'rubygems'
require 'nokogiri'
require 'open-uri'

page = Nokogiri::HTML(open('/Users/fabio/Desktop/index.html'))
#page = Nokogiri::HTML(open("https://news.ycombinator.com/"))
titles = page.xpath("//td[@class='title']")

titles.each do |t|
	puts t.text.to_s.encode("ISO-8859-1")
end
