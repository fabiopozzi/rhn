#!/usr/bin/env ruby

require "ncursesw"

begin
  # initialize ncurses
  Ncurses.initscr
  Ncurses.cbreak						# provide unbuffered input
	Ncurses.noecho						# turn off input echo
	Ncurses.nonl							# turn off newline translation
	Ncurses.stdscr.intrflush(false)	# turn off flush-on-interrupt
	Ncurses.stdscr.keypad(true)			# turn on keypad mode

	Ncurses.stdscr.addstr("Press a key to continue")
	Ncurses.stdscr.getch

ensure
	Ncurses.echo
	Ncurses.nocbreak
	Ncurses.nl
	Ncurses.endwin
end

