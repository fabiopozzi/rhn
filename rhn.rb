#!/usr/bin/env ruby
# frozen_string_literal: true

require 'rubygems'
require 'ncursesw'
require 'nokogiri'
require 'open-uri'
require 'feedjira'
require 'httparty'

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
  CYAN_COLOR_PAIR = 1
  NEWS_COLOR_PAIR = 2
  STARTING_ROW = 2

  attr_reader :sel_line
  def initialize
    # initialize ncurses
    Ncurses.initscr
    Ncurses.start_color
    Ncurses.cbreak                    # provide unbuffered input
    Ncurses.noecho                    # turn off input echo
    Ncurses.nonl                      # turn off newline translation
    Ncurses.stdscr.intrflush(false)   # turn off flush-on-interrupt
    Ncurses.stdscr.keypad(true)       # turn on keypad mode

    @num_cols = Ncurses.COLS()
    @front_color = Ncurses::COLOR_CYAN
    @back_color = Ncurses::COLOR_BLACK
    @max_rows = Ncurses.LINES()
    @sel_line = STARTING_ROW
  end

  def get_news_index
    @sel_line - STARTING_ROW
  end

  def restore_curses
    Ncurses.echo
    Ncurses.nocbreak
    Ncurses.nl
    Ncurses.endwin
  end

  def write_news(notizie)
    return if notizie.nil?

    @max_rows = notizie.length
    notizie.each_with_index do |n, i|
      Ncurses.stdscr.mvaddstr(i + STARTING_ROW, 2, n.num)
      # clear the rest of the line before writing title
      Ncurses.clrtoeol
      Ncurses.stdscr.mvaddstr(i + STARTING_ROW, 6, n.title)
      Ncurses.stdscr.mvaddstr(i + STARTING_ROW, Ncurses.COLS() - 8, n.n_commenti.to_s)
    end

    # highlight first news content
    Ncurses.init_pair(NEWS_COLOR_PAIR, Ncurses::COLOR_WHITE, Ncurses::COLOR_BLACK)
    Ncurses.mvchgat(STARTING_ROW, 0, -1, Ncurses::A_REVERSE, NEWS_COLOR_PAIR, nil)

    Ncurses.refresh
  end

  def init_first_row
    Ncurses.init_pair(CYAN_COLOR_PAIR, @front_color, @back_color)
    Ncurses.stdscr.mvaddstr(0, 2, '#')
    Ncurses.stdscr.mvaddstr(0, ((@num_cols - 8) / 2) - 7, 'Top stories')
    Ncurses.stdscr.mvaddstr(0, @num_cols - 10, 'Comments')
    Ncurses.mvchgat(0, 0, -1, Ncurses::A_REVERSE, CYAN_COLOR_PAIR, nil)
  end

  def update_rows(delta)
    Ncurses.mvchgat(@sel_line, 0, -1, Ncurses::A_NORMAL, NEWS_COLOR_PAIR, nil)
    Ncurses.stdscr.mvaddstr(@sel_line, 0, ' ')

    # wrap around if you reach the last news
    @sel_line = (@sel_line + delta) % (STARTING_ROW + @max_rows)
    @sel_line = STARTING_ROW + @max_rows if @sel_line < STARTING_ROW

    Ncurses.mvchgat(@sel_line, 0, -1, Ncurses::A_REVERSE, NEWS_COLOR_PAIR, nil)
    Ncurses.stdscr.mvaddstr(@sel_line, 0, '>')
  end
end

# Esegui il parsing della pagina di HN,
# crea e restituisci un array di oggetti notizia
def parse_hn
  html = URI.open('https://news.ycombinator.com/')
  page = Nokogiri::HTML(html)
  # page = Nokogiri::HTML(open('./index.html'))

  title_list = page.css('tr > td.title > a.storylink')
  subtext_list = page.css('tr > td.subtext')
  notizie = []

  # get news list count
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
  notizie
end

# Esegui il parsing del feed XML ultime notizie ANSA.
def parse_ansa
  xml = HTTParty.get('https://www.ansa.it/sito/ansait_rss.xml').body
  feed = Feedjira.parse(xml)
  notizie = []
  feed.entries.each_with_index do |e, i|
    # print("num #{i} : #{e.title}  #{e.url}\n")
    n = Notizia.new((i + 1).to_s,
                    e.title.to_s,
                    e.url.to_s,
                    ' ')
    notizie << n
  end
  notizie
end

begin
  notizie = {}
  notizie['HN'] = parse_hn
  notizie['ansa'] = parse_ansa

  ns = 'HN' # default news source
  g = Gui.new()
  g.init_first_row()

  g.write_news(notizie[ns])
  loop do
    ch = Ncurses.stdscr.getch

    case ch
    when Ncurses::KEY_PPAGE
      g.update_rows(-5)

    when Ncurses::KEY_NPAGE
      g.update_rows(+5)

    when Ncurses::KEY_DOWN
      g.update_rows(+1)

    when Ncurses::KEY_RIGHT
      Process.detach(Process.spawn("open -a Firefox '#{notizie[ns][g.get_news_index].link}'"))

    when 113
      # break if user presses 'q'
      break

    when 49
      # when user press 1 switch to ansa
      ns = 'ansa'
      g.write_news(notizie[ns])

    when 48
      # when user press 1 switch to ansa
      ns = 'HN'
      g.write_news(notizie[ns])

    # when '1'..'9'
    #   Ncurses.stdscr.mvaddstr(sel_line, 0, ' ')
    #   sel_line = ch - 48
    #   Ncurses.stdscr.mvaddstr(sel_line, 0, '>')

    # when 'a'..'f'
    #   Ncurses.stdscr.mvaddstr(sel_line, 0, ' ')
    #   sel_line = ch - 97 + 10
    #   Ncurses.stdscr.mvaddstr(sel_line, 0, '>')

    end
  end
ensure
  g.restore_curses()
end
