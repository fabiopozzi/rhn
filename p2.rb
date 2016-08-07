#!/usr/bin/env ruby
require 'rubygems'
require "ncursesw"
require 'nokogiri'
require 'open-uri'

begin
  # initialize ncurses
  Ncurses.initscr
  Ncurses.cbreak						# provide unbuffered input
	Ncurses.noecho						# turn off input echo
	Ncurses.nonl							# turn off newline translation
	Ncurses.stdscr.intrflush(false)	# turn off flush-on-interrupt
	Ncurses.stdscr.keypad(true)			# turn on keypad mode


	page = Nokogiri::HTML(open('/Users/fabio/Desktop/index.html'))
	#page = Nokogiri::HTML(open("https://news.ycombinator.com/"))
	num_list = page.css("tr > td.title > span.rank")
	titles_list = page.css("tr > td.title > a.storylink")

	row = 4
	# print link numbers
	num_list.each do |num|
		Ncurses.stdscr.mvaddstr(row, 1, num.text.encode("ISO-8859-1"))
		row += 1
	end
	row = 4
	titles_list.each do |title|
		Ncurses.stdscr.mvaddstr(row, 5, title.text.encode("ISO-8859-1"))
		row += 1
	end
	Ncurses.refresh
	Ncurses.stdscr.getch

ensure
	Ncurses.echo
	Ncurses.nocbreak
	Ncurses.nl
	Ncurses.endwin
end
