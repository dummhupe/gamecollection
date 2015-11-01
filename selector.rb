#!/usr/bin/ruby

require 'gtk2'

class Parser
  DB = 'metadata.csv'
  HEADERS = [:group, :title, :cmd]

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
    @data.sort! {|a,b| a[:group] <=> b[:group] }
  end
end

class Ui
  def initialize
    left = Gtk::VBox.new
    right = Gtk::VBox.new

    data_raw = Parser.new.data
    data = data_raw.group_by {|i| i[:group]}
    data.keys.each do |group|
      label = Gtk::Label.new(group)
      if do_place_group_left(group, data_raw)
        container = left
      else
        container = right
      end
      container.pack_start(Gtk::Label.new(""), false, false)
      container.pack_start(label, false, false)

      data[group].each do |entry|
        button = Gtk::Button.new(entry[:title])
        button.signal_connect("clicked") do 
          system(entry[:cmd] + "&")
        end
        container.pack_start(button, false, false)
      end
    end

    hbox = Gtk::HBox.new
    hbox.pack_start(left, true, true)
    hbox.pack_start(right, true, true)

    window = Gtk::Window.new("Game Collection")
    window.set_default_size(600,600)
    window.add(hbox)
    window.signal_connect("destroy") do
      Gtk.main_quit
    end

    window.show_all
  end

  def do_place_group_left(group, data)
    if @left_groups
      return @left_groups.include? group
    end

    @left_groups = []
    frequencies = data.group_by {|i| i[:group] }.map{|i| {i.first => i.last.count + 1}} # add one for group caption
    frequencies = frequencies.inject(:merge)
    item_count = 0
    max = ((data.count + frequencies.count)/2.0).ceil
    frequencies.each do |group, freq|
      item_count += freq
      @left_groups << group

      puts "item_count: #{item_count}, freq: #{freq}, group: #{group}, max: #{max}"
      if item_count >= max
        break
      end
    end

    return do_place_group_left(group, data)
  end
end

Ui.new
Gtk.main
