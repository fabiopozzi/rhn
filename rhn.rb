#!/usr/bin/env ruby
require 'rubygems'
require "ncursesw"
require 'httparty'

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
		Ncurses.stdscr.mvaddstr(0, (@num_cols / 2) - 7, "Top stories")
		Ncurses.mvchgat(0, 0, -1, Ncurses::A_REVERSE, 1, nil)
	end
end

begin
	g = Gui.new(Ncurses::COLOR_CYAN, Ncurses::COLOR_BLACK)
	base_url = "https://hacker-news.firebaseio.com/v0/"
	top_stories = HTTParty.get(base_url + "topstories.json")

	g.init_first_row()
	row = 1
	(0..15).each do |i|
		news = HTTParty.get(base_url + "item/#{top_stories[i]}.json")
		Ncurses.stdscr.mvaddstr(row, 2, row.to_s)
		Ncurses.stdscr.mvaddstr(row, 6, news["title"])
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
