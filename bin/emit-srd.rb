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
    run.y + (run.x < 325 ? 10000 : 0)
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
end

class PDF::Reader::ColumnarReceiver < PDF::Reader::PageTextReceiver
  def two_column_run_groups
    PDF::Reader::ColumnarPageLayout.new(@characters, @device_mediabox).run_groups.to_a
  end
end

module SRD5Section
  class Utility
    def self.break_into_sections(run_groups)
      sections = [[]]
      run_groups.each do |run_group|
        next if run_group.count < 1
        sections << [] if run_group[0].font_size == 25
        sections[-1].concat(run_group)
      end
      sections
    end
  end

  class Base
    attr_accessor :section_runs, :section_title, :section_filename

    def self.create(section_runs)
      section_title_runs = get_section_title_runs(section_runs)
      # Skip any initial section that lacks a title ("If you note any errors...")
      return nil unless section_title_runs.count > 0

      self.get_subclass(section_title_runs).new(section_runs)
    end

    def self.get_subclass(section_title_runs)
      # TODO: fix this, it doesn't work for e.g. "Beyond 1st level" or "Using abilityScores"
      subclass = section_title_runs.map { |run| run_text_clean(run).downcase.capitalize }.join("")
      puts "subclass: #{subclass}"
      Object.const_get("SRD5Section::#{subclass}") rescue nil || SRD5Section::Base
    end

    def self.get_section_title_runs(section_runs)
      section_runs.select { |run| run_break?(run) }
    end

    def initialize(section_runs)
      @section_runs = section_runs
      @section_title = self.class.get_section_title(self.class.get_section_title_runs(section_runs))
      @section_filename = self.class.get_section_filename(section_title)
    end

    def self.get_section_title(section_title_runs)
      section_title_runs.map { |run| run_text_clean(run) }.join(" ")
    end

    def self.get_section_dir
      Dir.pwd
    end

    def self.get_section_filename(section_title)
      title_to_filename(section_title, get_section_dir)
    end

    def self.title_to_filename(title, dir)
      filename = title.downcase.gsub(/[\s_:-]+/m, "-")
      filename.gsub!(/^-+/, "")
      filename.gsub!(/-+$/, "")
      File.join(dir, subdir, filename)
    end

    def self.subdir
      "public"
    end

    def self.run_text_clean(run)
      run_text = run.text.dup
      run_text.gsub!(/[\s\u00a0]+/, " ") # if new_font_size < 10 ??
      run_text.gsub!(/\s*-\u00ad\u2010\u2011?\s*/, "-")
      run_text.strip!
      run_text
    end

    def section_runs_by_size
      @section_runs.slice_when { |run_a, run_b| run_a.font_size != run_b.font_size }
    end

    def self.mkdirs
      Dir.mkdir(get_section_dir, 0755) unless Dir.exist?(get_section_dir)
      abs_subdir = File.join(get_section_dir, subdir)
      Dir.mkdir(abs_subdir, 0755) unless Dir.exist?(abs_subdir)
    end

    def write_file
      self.class.mkdirs
      File.open(section_filename, "w", 0644) do |io|
        section_runs_by_size.each do |runs|
          io.write(runs.map { |run| self.class.run_text_clean(run) }.join(" "), "\n")
        end
      end
    end

    def self.run_break?(run)
      # Should we break to a new page starting with this run?
      run.font_size >= 25
    end
  end

  class Races < Base
    # define a class that doesn't change anything just to make sure subclassing works
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
  sections = SRD5Section::Utility.break_into_sections(run_groups)
  sections.each do |section_runs|
    obj = SRD5Section::Base.create(section_runs)
    obj.write_file if obj
  end
end

reader = get_reader
emit_stuff(reader)

