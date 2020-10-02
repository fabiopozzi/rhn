#!/usr/bin/env ruby

require 'rubygems'
require 'ncursesw'
require 'nokogiri'
require 'open-uri'
require 'mail'

class Notizia
  attr_reader :num, :title, :link, :n_commenti
  def initialize(num, title, link, n_commenti)
    @num = num
    @title = title
    @link = link
    @n_commenti = n_commenti
  end
end

class Gui
  attr_reader :sel_line
  def initialize(front_color, back_color, max_rows)
    # initialize ncurses
    Ncurses.initscr
    Ncurses.start_color
    Ncurses.cbreak                    # provide unbuffered input
    Ncurses.noecho                    # turn off input echo
    Ncurses.nonl                      # turn off newline translation
    Ncurses.stdscr.intrflush(false)   # turn off flush-on-interrupt
    Ncurses.stdscr.keypad(true)       # turn on keypad mode

    @num_cols = Ncurses.COLS()
    @front_color = front_color
    @back_color = back_color
    @max_rows = max_rows
    @sel_line = 1
  end

  def restore_curses
    Ncurses.echo
    Ncurses.nocbreak
    Ncurses.nl
    Ncurses.endwin
  end

  def init_first_row
    Ncurses.init_pair(1, @front_color, @back_color)
    Ncurses.stdscr.mvaddstr(0, 2, '#')
    Ncurses.stdscr.mvaddstr(0, ((@num_cols - 8) / 2) - 7, 'Top stories')
    Ncurses.stdscr.mvaddstr(0, @num_cols - 10, 'Comments')
    Ncurses.mvchgat(0, 0, -1, Ncurses::A_REVERSE, 1, nil)
  end

  def update_rows(delta)
    Ncurses.stdscr.mvaddstr(@sel_line, 0, ' ')
    @sel_line += delta
    @sel_line = 1 if @sel_line == 0
    @sel_line = @max_rows if @sel_line > @max_rows
    Ncurses.stdscr.mvaddstr(@sel_line, 0, '>')
  end
end

begin
  html = URI.open('https://news.ycombinator.com/')
  page = Nokogiri::HTML(html)
  # page = Nokogiri::HTML(open('./index.html'))

  title_list = page.css('tr > td.title > a.storylink')
  subtext_list = page.css('tr > td.subtext')

  g = Gui.new(Ncurses::COLOR_CYAN, Ncurses::COLOR_BLACK, title_list.length)
  g.init_first_row()
  notizie = []

  (0...title_list.length).each do |i|
    if subtext_list[i]
      if subtext_list[i].css('a')[3]
        tmp = subtext_list[i].css('a')[3].child
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
     Ncurses.stdscr.mvaddstr(i + 1, 2, n.num)
     Ncurses.stdscr.mvaddstr(i + 1, 6, n.title)
     Ncurses.stdscr.mvaddstr(i + 1, Ncurses.COLS() - 8, n.n_commenti.to_s)
  end

  Ncurses.refresh
  Ncurses.stdscr.mvaddstr(1, 0, '>')
  loop do
    ch = Ncurses.stdscr.getch

    case ch
    when Ncurses::KEY_UP
      g.update_rows(-1)

    when Ncurses::KEY_DOWN
      g.update_rows(+1)

    when Ncurses::KEY_RIGHT
      Process.detach(Process.spawn("open -a Firefox '#{notizie[g.sel_line - 1].link}'"))

    when 113
      # break if user presses 'q'
      break

    # when '1'..'9'
    #   Ncurses.stdscr.mvaddstr(sel_line, 0, ' ')
    #   sel_line = ch - 48
    #   Ncurses.stdscr.mvaddstr(sel_line, 0, '>')

    # when 'a'..'f'
    #   Ncurses.stdscr.mvaddstr(sel_line, 0, ' ')
    #   sel_line = ch - 97 + 10
    #   Ncurses.stdscr.mvaddstr(sel_line, 0, '>')

    end #end case
  end
ensure
  g.restore_curses()
end
