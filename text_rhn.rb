#!/usr/bin/env ruby
# frozen_string_literal: true

require 'rubygems'
require 'nokogiri'
require 'open-uri'

class Notizia
  attr_reader :num, :title, :link, :n_commenti
  def initialize(num, title, link, n_commenti)
    @num = num
    @title = title
    @link = link
    @n_commenti = n_commenti
  end
end

begin
  html = URI.open('https://news.ycombinator.com/')
  page = Nokogiri::HTML(html)
  # page = Nokogiri::HTML(open('./index.html'))

  title_list = page.css('tr > td.title > a.storylink')
  subtext_list = page.css('tr > td.subtext')
  notizie = []

  (0...title_list.length).each do |i|
    if subtext_list[i]
      if subtext_list[i].css('a')[3]
        tmp = subtext_list[i].css('a')[3].child
        print(tmp)
        n_commenti = tmp.text.split(/[[:space:]]/).first
      else
        n_commenti = '0'
      end
    else
      n_commenti = '0'
    end
    n = Notizia.new((i + 1).to_s,
                    title_list[i].text.encode('ISO-8859-1'),
                    title_list[i]['href'].encode('ISO-8859-1'),
                    n_commenti)
    notizie << n
  end

  notizie.each_with_index do |n, i|
    print("num #{n.num} : #{n.title}  #{n.n_commenti}\n")
  end
end
