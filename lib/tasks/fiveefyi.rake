require 'pdf-reader'
require 'srd5_section/base'
require 'srd5_section/races'
require 'srd5_section/utility'

namespace :fiveefyi do
  desc "Emit a formatted version of the SRD PDF into the public/srd folder"
  task srd_write: :environment do

    # 10 and 8 are sidebar title and sidebar text
    # 9 is ordinary text
    # 11 is a typo for 12
    # 12 is a section header, like "Proficiencies" or a spell name
    # 13 is a bigger section header, like a class feature ("Spellcasting" or "Wild Shape"),
    #    "Spell Slots," "Wizard Spells," "Outer Planes"
    # 18 is an even bigger section header, like "Class Features", "Armor", "Making an Attack"
    # 25 is the title of a "chapter" (not a book chapter), like "Feats", "Fighter", "Equipment"

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
      sections = Srd5Section::Utility.break_into_sections(run_groups)
      sections.each do |section_runs|
        obj = Srd5Section::Base.create(section_runs)
        obj.write_file if obj
      end
    end

    reader = get_reader
    emit_stuff(reader)

  end

end
