require 'http'
require 'pdf-reader'
require 'srd5_section/base'
require 'srd5_section/races'
require 'srd5_section/utility'

SRD_OGL_NUM_PAGES = 403
SRD_OGL_SOURCE_URL = "https://media.wizards.com/2016/downloads/DND/SRD-OGL_V5.1.pdf"
SRD_OGL_FILE_NAME = Rails.root.join("tmp", "SRD-OGL_V5.1.pdf")
SRD_OGL_FILE_SIZE = 4857826
SRD_OGL_FILE_SHA256 = "d3f94417d2532f42a5abaec07e71a59007bf6cc46992c6458be6667f7a9f1e34"

namespace :fiveefyi do
  desc "Emit a formatted version of the SRD PDF into the public/srd folder"
  task :srd_write, [:pages] => :environment do |task_name, args|

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

    def srd_ogl_file_present?
      File.exist?(SRD_OGL_FILE_NAME) &&
        File.size(SRD_OGL_FILE_NAME) == SRD_OGL_FILE_SIZE &&
        Digest::SHA256.file(SRD_OGL_FILE_NAME) == SRD_OGL_FILE_SHA256
    end

    def get_reader
      if !srd_ogl_file_present?
        puts "Downloading the SRD OGL file..."
        File.delete(SRD_OGL_FILE_NAME) rescue Errno::ENOENT
        File.open(SRD_OGL_FILE_NAME, "wb") do |file|
          response = HTTP.get(SRD_OGL_SOURCE_URL)
          while partial = response.readpartial
            file.write partial
          end
        end
        if !srd_ogl_file_present?
          raise ArgumentError, "SRD OGL File was not successfully downloaded"
        end
        puts "Downloaded."
      end
      PDF::Reader.new(File.open(SRD_OGL_FILE_NAME, "rb"))
    end

    def get_page_list(args)
      return (1..SRD_OGL_NUM_PAGES).to_a if args.pages.nil?
      [args.pages, args.extras].flatten.
        map { |p| /^(\d+)-(\d+)/ =~ p ? ($1..$2).to_a : p }.flatten.compact.
        map(&:to_i).sort.uniq
    end

    def emit_stuff(reader, args)
      pages = reader.pages
      page_list = get_page_list(args)
      run_groups = []
      pages.each_index do |page_num|
        next if page_num < 2
        next unless page_list.include? page_num
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
    emit_stuff(reader, args)

  end

end
