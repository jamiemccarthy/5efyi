#!/usr/bin/env ruby

require 'pdf-reader'
require 'byebug'

class PDF::Reader::ColumnarPageLayout < PDF::Reader::PageLayout
  # Return the runs in the order generally used by the SRD,
  # excluding the footer generally used by the SRD. This
  # ignores the order defined by TextRun#<=>
  def runs_in_columnar_order
    @runs.
      select { |r| r.y >= 90 }. # exclude page footer ("Not for resale" thru page number)
      sort { |a,b| (a.x < 180 ? 10000 : 0) + a.y <=> (b.x < 180 ? 10000 : 0) + b.y }. # sort left column above right column
      reverse # PDF y column extends from 0 up
  end

  def to_s
    text = ""
    last_font_size = nil
    runs_in_columnar_order.each do |run|
      run_text = run.text.dup
      new_font_size = run.font_size
      run_text.gsub!(/[\s\u00a0]+/, " ") # if new_font_size < 10 ??
      run_text.gsub!(/\s*-\u00ad\u2010\u2011?\s*/, "-")
      run_text.strip!
      separator = last_font_size == new_font_size ? " " : "\n"
      separator = "" if text.empty?
      text = text + separator + run_text
      last_font_size = new_font_size
    end
    text
  end
end

class PDF::Reader::ColumnarReceiver < PDF::Reader::PageTextReceiver
  def two_column_runs
    PDF::Reader::ColumnarPageLayout.new(@characters, @device_mediabox).runs_in_columnar_order
  end
end

class TextRunWriter
  def self.run_text_clean(run)
    run_text = run.text.dup
    run_text.gsub!(/[\s\u00a0]+/, " ") # if new_font_size < 10 ??
    run_text.gsub!(/\s*-\u00ad\u2010\u2011?\s*/, "-")
    run_text.strip!
    run_text
  end

  def self.run_break?(run)
    # Should we break to a new page starting with this run?
    run.font_size >= 25
  end

  def self.break_into_sections(runs)
    pages = [[]]
    runs.each do |run|
      pages << [] if run_break?(run)
      pages[-1] << run
    end
    pages
  end

  def self.subdir
    "public"
  end

  def self.title_to_filename(title, dir)
    File.join(dir, subdir, title.downcase.gsub(/\s+/, "-"))
  end

  def self.write_section_file(sections, filename)
    File.open(filename, "w", 0644) do |io|
      io.write(sections.map { |run| run_text_clean(run) }.join("\n"))
    end
  end

  def self.write(sections, dir = Dir.pwd)
    Dir.mkdir(dir, 0755) unless Dir.exist?(dir)
    sections.each do |section|
      section_run = section.find { |run| run_break?(run) }
      next unless section_run

      section_title = run_text_clean(section_run)
      section_filename = title_to_filename(section_title, dir)
      write_section_file( section.reject { |run| run == section_run }, section_filename)
    end
  end
end

def get_reader
  PDF::Reader.new(File.open("SRD-OGL_V5.1.pdf", "rb"))
end

def emit_stuff(reader)
  pages = reader.pages
  runs = []
  pages.each_index do |page_num|
    next if page_num < 2
    receiver = PDF::Reader::ColumnarReceiver.new
    pages[page_num].walk(receiver)
    runs.concat(receiver.two_column_runs)
  end
  sections = TextRunWriter.break_into_sections(runs)
  TextRunWriter.write(sections)
end

reader = get_reader
emit_stuff(reader)

