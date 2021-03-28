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
  def two_column_content
    PDF::Reader::ColumnarPageLayout.new(@characters, @device_mediabox).to_s
  end
end

def get_reader
  PDF::Reader.new(File.open("SRD-OGL_V5.1.pdf", "rb"))
end

def emit_stuff(reader)
  pages = reader.pages
  pages.each_index do |page_num|
    next if page_num == 0
    receiver = PDF::Reader::ColumnarReceiver.new
    pages[page_num].walk(receiver)
    puts receiver.two_column_content
  end
end

reader = get_reader
emit_stuff(reader)

