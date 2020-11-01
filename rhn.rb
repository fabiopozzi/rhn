#!/usr/bin/env ruby
# frozen_string_literal: true

require 'rubygems'
require 'feedjira'
require 'httparty'
require 'json'
require 'ncursesw'
require 'nokogiri'
require 'open-uri'

class Feed
  attr_reader :name, :news_num
  def initialize(name)
    @notizie = []
    @news_num = 0
    @name = name
  end

  def add_news(index, title, url, n_commenti)
    @notizie << Notizia.new(index.to_s,
                    title,
                    url,
                    n_commenti.to_s)
    @news_num += 1
  end

  def get_news(pos)
    # TODO: aggiungi check range
    @notizie[pos]
  end
end

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
  NUM_COLOR_PAIR = 2
  NEWS_COLOR_PAIR = 3
  TITLE_COLOR_PAIR = 4

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

    # init color pairs
    Ncurses.init_pair(CYAN_COLOR_PAIR, Ncurses::COLOR_CYAN, Ncurses::COLOR_BLACK)
    Ncurses.init_pair(NEWS_COLOR_PAIR, Ncurses::COLOR_WHITE, Ncurses::COLOR_BLACK)
    Ncurses.init_pair(TITLE_COLOR_PAIR, Ncurses::COLOR_BLUE, Ncurses::COLOR_BLACK)

    @num_cols = Ncurses.COLS()
    @sel_line = 0
    @page = 0
  end

  def get_news_index
    (@page * @max_rows) + @sel_line
  end

  def restore_curses
    Ncurses.echo
    Ncurses.nocbreak
    Ncurses.nl
    Ncurses.endwin
  end

  def next_page
    @page += 1
    @sel_line = @sel_line + @max_rows
  end

  def prev_page
    @page = [@page - 1, 0].max
    @sel_line = [@sel_line - @max_rows, 0].max
  end

  def first_page
    @page = 0
    @sel_line = 0
  end

  def write_news(feed)

    Ncurses.stdscr.clrtobot
    init_first_row(feed.name)

    @max_rows = [30, feed.news_num].min

    (0..@max_rows).each do |i|
      pos = (@page * @max_rows) + i
      n = feed.get_news(pos)
      next if n.nil?

      current_row = i + STARTING_ROW
      Ncurses.stdscr.mvaddstr(current_row, 2, pos.to_s)
      # activate color attribute
      #Ncurses.stdscr.attron(Ncurses.COLOR_PAIR(TITLE_COLOR_PAIR))
      Ncurses.stdscr.mvaddstr(current_row, 6, n.title)
      #Ncurses.stdscr.attroff(Ncurses.COLOR_PAIR(TITLE_COLOR_PAIR))
      Ncurses.clrtoeol
      Ncurses.stdscr.mvaddstr(current_row, Ncurses.COLS() - 8, n.n_commenti)
    end

    # highlight first news content
    Ncurses.mvchgat(STARTING_ROW, 0, -1, Ncurses::A_REVERSE, NEWS_COLOR_PAIR, nil)

    @sel_line = 0

    Ncurses.refresh
  end

  def init_first_row(feed_name)
    Ncurses.stdscr.mvaddstr(0, ((@num_cols - 8) / 2) - 7, feed_name)
    Ncurses.clrtoeol
    Ncurses.mvchgat(0, 0, -1, Ncurses::A_REVERSE, CYAN_COLOR_PAIR, nil)
  end

  def update_rows(delta)
    Ncurses.mvchgat(@sel_line + STARTING_ROW, 0, -1, Ncurses::A_NORMAL, NEWS_COLOR_PAIR, nil)

    # wrap around if you reach the last news
    @sel_line = (@sel_line + delta) % (@max_rows)
    @sel_line = @max_rows if @sel_line < 0

    Ncurses.mvchgat(@sel_line + STARTING_ROW, 0, -1, Ncurses::A_REVERSE, NEWS_COLOR_PAIR, nil)
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
  f = Feed.new("Hacker News")

  # get news list count
  (0...title_list.length).each do |i|
    if subtext_list[i] and subtext_list[i].css('a')[3]
        tmp = subtext_list[i].css('a')[3].child
        n_commenti = tmp.text.split(/[[:space:]]/).first
    else
      n_commenti = '0'
    end
    f.add_news(i+1,
               title_list[i].text.encode('ISO-8859-1'),
               title_list[i]['href'].encode('ISO-8859-1'),
               n_commenti)
  end
  f
end

# Esegui il parsing del feed XML ultime notizie ANSA.
def parse_feed(title, url)
  xml = HTTParty.get(url).body
  feed = Feedjira.parse(xml)

  f = Feed.new(title)
  feed.entries.each_with_index do |e, i|
    f.add_news(i+1,
               e.title.to_s,
               e.url.to_s,
               ' ')
    # print("num #{i} : #{e.title}  #{e.url}\n")
  end
  f
end

begin
  if File.exists?('./config.json')
    config_file = File.read('./config.json')
    rss_sources = JSON.parse(config_file)
  end
  feeds = {}
  threads = []
  threads << Thread.new { feeds[:hn] = parse_hn }
  rss_sources.each do |source|
    threads << Thread.new { feeds[source['nome'].to_sym] = parse_feed(source['nome'], source['url']) }
  end

  threads.each(&:join)

  cur_feed = feeds[:hn]
  g = Gui.new()

  g.write_news(cur_feed)
  loop do
    ch = Ncurses.stdscr.getch

    case ch
    when Ncurses::KEY_PPAGE
      g.update_rows(-5)

    when Ncurses::KEY_NPAGE
      g.update_rows(+5)

    when Ncurses::KEY_DOWN
      g.update_rows(+1)

    when Ncurses::KEY_UP
      g.update_rows(-1)

    when Ncurses::KEY_RIGHT
      l = cur_feed.get_news(g.get_news_index).link
      if RUBY_PLATFORM.include? "darwin"
        Process.detach(Process.spawn("open -a Firefox '#{l}'"))
      else
        Process.detach(Process.spawn("firefox #{l}"))
      end

    when 110
      # next page if user presses 'n'
      g.next_page
      g.write_news(cur_feed)

    when 112
      # previous page if user presses 'p'
      g.prev_page
      g.write_news(cur_feed)

    when 113
      # break if user presses 'q'
      break

    when 48
      # when user press 0 switch to HN
      cur_feed = feeds[:hn]
      g.first_page
      g.write_news(cur_feed)

    when 49
      # when user press 1 switch to Ansa
      cur_feed = feeds[:ansa]
      g.first_page
      g.write_news(cur_feed)

    when 50
      # when user press 2 switch to 'il Post'
      cur_feed = feeds[:post]
      g.first_page
      g.write_news(cur_feed)
    end
  end
ensure
  g.restore_curses()
end

# TODO: aggiungere visualizzazione tab?
# TODO: leggere sorgenti RSS da file
