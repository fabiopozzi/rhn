#!/usr/bin/env ruby
#encoding: UTF-8
require 'rubygems'
require 'ncursesw'
require 'nokogiri'
require 'open-uri'

class Gui
	def initialize(front_color, back_color)
		# initialize ncurses
		Ncurses.initscr
		Ncurses.start_color
		Ncurses.cbreak						# provide unbuffered input
		Ncurses.noecho						# turn off input echo
		Ncurses.nonl							# turn off newline translation
		Ncurses.stdscr.intrflush(false)	# turn off flush-on-interrupt
		Ncurses.stdscr.keypad(true)			# turn on keypad mode

		@num_cols = Ncurses.COLS()
		@front_color = front_color
		@back_color = back_color
	end

	def restore_curses()
		Ncurses.echo
		Ncurses.nocbreak
		Ncurses.nl
		Ncurses.endwin
	end

	def init_first_row()
		Ncurses.init_pair(1, @front_color , @back_color)
		Ncurses.stdscr.mvaddstr(0, 2, "No.")
		Ncurses.stdscr.mvaddstr(0, ((@num_cols - 8) / 2) - 7, "Top stories")
		Ncurses.stdscr.mvaddstr(0, @num_cols - 10, "Comments")
		Ncurses.mvchgat(0, 0, -1, Ncurses::A_REVERSE, 1, nil)
	end
end

begin
	g = Gui.new(Ncurses::COLOR_CYAN, Ncurses::COLOR_BLACK)
	page = Nokogiri::HTML(open('/Users/fabio/Desktop/index.html'))
	num_list = page.css("tr > td.title > span.rank")
	title_list = page.css("tr > td.title > a.storylink")
	subtext_list = page.css("tr > td.subtext")

	g.init_first_row()
	row = 1
	num_list.each do |n|
		Ncurses.stdscr.mvaddstr(row, 2, n.text.encode("ISO-8859-1"))
		row += 1
	end
	row = 1
	title_list.each do |t|
		Ncurses.stdscr.mvaddstr(row, 6, t.text.encode("ISO-8859-1"))
		row += 1
	end
	row = 1
	subtext_list.each do |s|
		tmp = s.css("a")[3]
		if tmp
			cc = tmp.child.text.split(/[[:space:]]/).first
			Ncurses.stdscr.mvaddstr(row, Ncurses.COLS() - 8, cc)
		end
		row += 1
	end

	Ncurses.refresh
	sel_line=1
	Ncurses.stdscr.mvaddstr(sel_line, 0, ">")
	loop do
		ch = Ncurses.stdscr.getch

		case ch
		when Ncurses::KEY_UP
			if sel_line > 1
				Ncurses.stdscr.mvaddstr(sel_line, 0, " ")
				sel_line -= 1
				Ncurses.stdscr.mvaddstr(sel_line, 0, ">")
			end

		when Ncurses::KEY_DOWN
	  	if sel_line >= 1
				Ncurses.stdscr.mvaddstr(sel_line, 0, " ")
				sel_line += 1
				Ncurses.stdscr.mvaddstr(sel_line, 0, ">")
			end

		when 27
		# break if user presses "ESC"
		break

		when 49..57
			Ncurses.stdscr.mvaddstr(sel_line, 0, " ")
			sel_line = ch - 48
			Ncurses.stdscr.mvaddstr(sel_line, 0, ">")

		when 97..102
			Ncurses.stdscr.mvaddstr(sel_line, 0, " ")
			sel_line = ch - 97 + 10
			Ncurses.stdscr.mvaddstr(sel_line, 0, ">")

		end #end case
	end

ensure
	g.restore_curses()
end
