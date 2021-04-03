#!/usr/bin/env ruby

# 10 and 8 are sidebar title and sidebar text
# 9 is ordinary text
# 11 is a typo for 12
# 12 is a section header, like "Proficiencies" or a spell name
# 13 is a bigger section header, like a class feature ("Spellcasting" or "Wild Shape"),
#    "Spell Slots," "Wizard Spells," "Outer Planes"
# 18 is an even bigger section header, like "Class Features", "Armor", "Making an Attack"
# 25 is the title of a "chapter" (not a book chapter), like "Feats", "Fighter", "Equipment"

require 'pdf-reader'
require 'byebug'

class PDF::Reader::ColumnarPageLayout < PDF::Reader::PageLayout
  # Return the runs in the order generally used by the SRD,
  # excluding the footer generally used by the SRD. Basically
  # we sort the left column "above" the right column. This
  # ignores the order defined by TextRun#<=>
  def run_sort_val(run)
    run.y + (run.x < 180 ? 10000 : 0)
  end
  
  def runs_in_columnar_order
    @runs.
      select { |r| r.y >= 90 }. # exclude page footer ("Not for resale" thru page number)
      sort { |a,b| run_sort_val(a) <=> run_sort_val(b) }.
      reverse # In a PDF, the y column extends from 0 up
  end

  def run_groups
    runs_in_columnar_order.slice_when { |run_a, run_b| run_a.font_size != run_b.font_size }
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
  def two_column_run_groups
    PDF::Reader::ColumnarPageLayout.new(@characters, @device_mediabox).run_groups.to_a
  end
end

class TextRunWriter
  def self.run_text_clean(run)
    run_text = run.text.dup
    run_text.gsub!(/[\s\u00a0]+/, " ") # if new_font_size < 10 ??
    run_text.gsub!(/\s*-\u00ad\u2010\u2011?\s*/, "-")
    run_text.strip!
    run_text
    ###TODO
    run_text.chomp!
    "#{run.font_size} #{run_text}\n"
  end

  def self.run_break?(run)
    # Should we break to a new page starting with this run?
    run.font_size >= 25
  end

  def self.break_into_sections(run_groups)
    sections = [[]]
    run_groups.each do |run_group|
      next if run_group.count < 1
      sections << [] if run_group[0].font_size == 25
      sections[-1].concat(run_group)
    end
    sections
  end

  def self.subdir
    "public"
  end

  def self.title_to_filename(title, dir)
    filename = title.downcase.gsub(/[\s_:-]+/m, "-")
    filename.gsub!(/^-+/, "")
    filename.gsub!(/-+$/, "")
    File.join(dir, subdir, filename)
  end

  def self.write_section_file(filename, title, sections)
    sections_by_size = sections.slice_when { |run_a, run_b| run_a.font_size != run_b.font_size }
    File.open(filename, "w", 0644) do |io|
      io.write(sections.map { |run| run_text_clean(run) })
    end
  end

  def self.write(sections, dir = Dir.pwd)
    Dir.mkdir(dir, 0755) unless Dir.exist?(dir)
    sections.each do |section_runs|
      section_title_runs = section_runs.select { |run| run_break?(run) }
      # Skip any initial section that lacks a title ("If you note any errors...")
      next unless section_title_runs.count > 0

      section_title = section_title_runs.map { |run| run_text_clean(run) }.join(" ")
      section_filename = title_to_filename(section_title, dir)
      write_section_file(section_filename, section_title, section_runs)
    end
  end
end

def get_reader
  PDF::Reader.new(File.open("SRD-OGL_V5.1.pdf", "rb"))
end

def emit_stuff(reader)
  pages = reader.pages
  run_groups = []
  pages.each_index do |page_num|
    next if page_num < 2
    receiver = PDF::Reader::ColumnarReceiver.new
    pages[page_num].walk(receiver)
    run_groups.concat(receiver.two_column_run_groups)
  end
  sections = TextRunWriter.break_into_sections(run_groups)
  TextRunWriter.write(sections)
end

reader = get_reader
emit_stuff(reader)

