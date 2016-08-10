#!/usr/bin/env ruby
require 'rubygems'
require "ncursesw"
require 'nokogiri'
require 'open-uri'

begin
  # initialize ncurses
  Ncurses.initscr
	Ncurses.start_color
  Ncurses.cbreak						# provide unbuffered input
	Ncurses.noecho						# turn off input echo
	Ncurses.nonl							# turn off newline translation
	Ncurses.stdscr.intrflush(false)	# turn off flush-on-interrupt
	Ncurses.stdscr.keypad(true)			# turn on keypad mode

	num_cols = Ncurses.COLS()

	page = Nokogiri::HTML(open('/Users/fabio/Desktop/index.html'))
	#page = Nokogiri::HTML(open("https://news.ycombinator.com/"))
	num_list = page.css("tr > td.title > span.rank")
	titles_list = page.css("tr > td.title > a.storylink")

	Ncurses.init_pair(1, Ncurses::COLOR_CYAN, Ncurses::COLOR_BLACK)
	Ncurses.stdscr.mvaddstr(0, 1, "No.")
	Ncurses.stdscr.mvaddstr(0, (num_cols / 2) - 7, "Top stories")
	Ncurses.mvchgat(0, 0, -1, Ncurses::A_REVERSE, 1, nil)

	row = 1
	num_list.each do |num|
		Ncurses.stdscr.mvaddstr(row, 1, num.text.encode("ISO-8859-1"))
		row += 1
	end

	row = 1
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
