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
	titles = page.xpath("//td[@class='title']")

	row = 4
	titles.each do |t|
		#puts t.text.to_s.encode("ISO-8859-1")
		Ncurses.stdscr.mvaddstr(row, 5, t.text.to_s.encode("ISO-8859-1"))
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
