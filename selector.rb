#!/usr/bin/ruby

require 'gtk2'

class Parser
  DB = '/home/koenig/.gamecollection_metadata.csv'
  HEADERS = [:group, :title, :sort, :cmd]

  attr_accessor :data

  def initialize
    csv = File.readlines(DB)
    csv.shift # skip header
    csv.delete_if {|line| line.strip == ""}
    csv.map! {|line| line.strip } # skip trailing whitespace
    csv.map! {|line| line.split(';').map {|item| item.strip } }
    @data = []
    csv.each do |entry|
      @data << Hash[HEADERS.zip(entry)]
    end
    @data.sort! {|a,b| 
      if a[:group] == b[:group] 
        if a[:sort] == b[:sort]
          a[:title] <=> b[:title] 
        else
          if a[:sort].empty?
            a[:title] <=> b[:sort]
          elsif b[:sort].empty?
            a[:sort] <=> b[:title]
          else
            a[:sort] <=> b[:sort]
          end
        end
      else
        a[:group] <=> b[:group]
      end
    }
  end
end

class Ui
  COLUMNS = 4

  def initialize
    columns = []
    COLUMNS.times do
      columns << Gtk::VBox.new
    end

    data_raw = Parser.new.data
    data = data_raw.group_by {|i| i[:group]}
    data.keys.each do |group|
      label = Gtk::Label.new
      label.set_markup("<big><b>#{group}</b></big>")
      label.set_alignment(0,0)

      container = columns[get_column_index(group, data_raw)]
      container.pack_start(Gtk::Label.new, false, false)
      container.pack_start(label, false, false, 10)

      data[group].each do |entry|
        button = Gtk::Button.new("Start")
        button.signal_connect("clicked") do 
          system(entry[:cmd] + "&")
        end

        hbox = Gtk::HBox.new
        label = Gtk::Label.new(entry[:title])
        label.set_alignment(0,0)
        hbox.pack_start(label, true, true)
        hbox.pack_start(button, false, false)
        container.pack_start(hbox, false, false)
      end
    end

    hbox = Gtk::HBox.new
    columns.each do |vbox|
      hbox.pack_start(vbox, true, true, 20)
    end

    window = Gtk::Window.new("Game Collection")
    window.set_default_size(600,600)
    window.add(hbox)
    window.signal_connect("destroy") do
      Gtk.main_quit
    end

    window.show_all
  end

  private
  def get_column_index(group, data)
    if @placement
      return @placement[group]
    end

    @placement = {}
    frequencies = data.group_by {|i| i[:group] }.map{|i| {i.first => i.last.count + 1}} # add one for group caption
    frequencies = frequencies.inject(:merge)
    item_count = 0
    index = 0
    max = ((data.count + frequencies.count)/COLUMNS.to_f).ceil

    frequencies.each do |group, freq|
      if item_count + freq >= max + 10
        # if next group would result in more than ten items more than average
        # in a column, then put the group in the next column
        index += 1
        item_count = 0
      end

      item_count += freq
      @placement[group] = index

      if item_count >= max
        # group exceeds average number of items in a column
        # -> put next group in next column
        index += 1
        item_count = 0
      end
    end

    return get_column_index(group, data)
  end
end

Ui.new
Gtk.main
