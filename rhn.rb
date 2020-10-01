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
  def initialize(front_color, back_color)
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
  end

  def restore_curses
    Ncurses.echo
    Ncurses.nocbreak
    Ncurses.nl
    Ncurses.endwin
  end

  def init_first_row
    Ncurses.init_pair(1, @front_color, @back_color)
    Ncurses.stdscr.mvaddstr(0, 2, 'No.')
    Ncurses.stdscr.mvaddstr(0, ((@num_cols - 8) / 2) - 7, 'Top stories')
    Ncurses.stdscr.mvaddstr(0, @num_cols - 10, 'Comments')
    Ncurses.mvchgat(0, 0, -1, Ncurses::A_REVERSE, 1, nil)
  end
end

begin
  g = Gui.new(Ncurses::COLOR_CYAN, Ncurses::COLOR_BLACK)
  html = URI.open("https://news.ycombinator.com/")
  page = Nokogiri::HTML(html)

  title_list = page.css('tr > td.title > a.storylink')
  subtext_list = page.css('tr > td.subtext')

  g.init_first_row()
  notizie = []

  for i in 0..(title_list.length - 1) do
    if subtext_list[i]
      if subtext_list[i].css('a')[3]
        tmp = subtext_list[i].css('a')[3].child
        n_commenti = tmp.text.split(/[[:space:]]/).first
      end
    else
      n_commenti = 0
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
    Ncurses.stdscr.mvaddstr(i + 1, Ncurses.COLS() - 8, n.n_commenti)
  end

  Ncurses.refresh
  sel_line = 1
  Ncurses.stdscr.mvaddstr(sel_line, 0, '>')
  loop do
    ch = Ncurses.stdscr.getch

    case ch
    when Ncurses::KEY_UP
      if sel_line > 1
        Ncurses.stdscr.mvaddstr(sel_line, 0, ' ')
        sel_line -= 1
        Ncurses.stdscr.mvaddstr(sel_line, 0, '>')
      end

    when Ncurses::KEY_DOWN
      if sel_line >= 1
        Ncurses.stdscr.mvaddstr(sel_line, 0, ' ')
        sel_line += 1
        Ncurses.stdscr.mvaddstr(sel_line, 0, '>')
      end

    when Ncurses::KEY_RIGHT
      Process.detach(Process.spawn("firefox #{notizie[sel_line-1].link}"))

    when 109
      # 'm' keypress
      Ncurses.stdscr.mvaddstr(sel_line, 0, ' ' * Ncurses.COLS())
      Ncurses.stdscr.mvaddstr(sel_line, 0, "      Email link #{notizie[sel_line-1].link}")
      Ncurses.refresh
      m = Mail.new do
        from    'fabio@antani.work'
        to      'wintermute@antani.work'
        subject "[bookmarks] #{notizie[sel_line-1].title}"
        body    "#{notizie[sel_line-1].link} \n sent by rhn.rb"
      end
      m.deliver!
      sleep 3
      Ncurses.stdscr.mvaddstr(sel_line, 0, ' ' * Ncurses.COLS())
      Ncurses.refresh
      Ncurses.stdscr.mvaddstr(sel_line, 2, notizie[sel_line - 1].num)
      Ncurses.stdscr.mvaddstr(sel_line, 6, notizie[sel_line - 1].title)
      Ncurses.stdscr.mvaddstr(sel_line, Ncurses.COLS() - 8, notizie[sel_line - 1].n_commenti)
      Ncurses.refresh

    when 113
      # break if user presses 'q'
      break

    when 49..57
      Ncurses.stdscr.mvaddstr(sel_line, 0, ' ')
      sel_line = ch - 48
      Ncurses.stdscr.mvaddstr(sel_line, 0, '>')

    when 97..102
      Ncurses.stdscr.mvaddstr(sel_line, 0, ' ')
      sel_line = ch - 97 + 10
      Ncurses.stdscr.mvaddstr(sel_line, 0, '>')

    end #end case
  end
ensure
  g.restore_curses()
end
