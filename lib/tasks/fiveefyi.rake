require "http"
require "pdf-reader"

SRD_OGL_NUM_PAGES = 403
SRD_OGL_SOURCE_URL = "https://media.wizards.com/2016/downloads/DND/SRD-OGL_V5.1.pdf".freeze
SRD_OGL_FILE_NAME = Rails.root.join("tmp", "SRD-OGL_V5.1.pdf")
SRD_OGL_FILE_SIZE = 4_857_826
SRD_OGL_FILE_SHA256 = "d3f94417d2532f42a5abaec07e71a59007bf6cc46992c6458be6667f7a9f1e34".freeze

namespace :fiveefyi do
  desc "Emit a formatted version of the SRD PDF into the public/srd folder"
  task :srd_write, [:pages] => :environment do |_, args|
    # 10 and 8 are sidebar title and sidebar text
    # 9 is ordinary text
    # 11 is a typo for 12
    # 12 is a section header, like "Proficiencies" or a spell name
    # 13 is a bigger section header, like a class feature ("Spellcasting" or "Wild Shape"),
    #    "Spell Slots," "Wizard Spells," "Outer Planes"
    # 18 is an even bigger section header, like "Class Features", "Armor", "Making an Attack"
    # 25 is the title of a "chapter" (not a book chapter), like "Feats", "Fighter", "Equipment"

    def srd_ogl_file_present?
      File.exist?(SRD_OGL_FILE_NAME) &&
        File.size(SRD_OGL_FILE_NAME) == SRD_OGL_FILE_SIZE &&
        Digest::SHA256.file(SRD_OGL_FILE_NAME) == SRD_OGL_FILE_SHA256
    end

    def reader
      if !srd_ogl_file_present?
        puts "Downloading the SRD OGL file..."
        begin
          File.delete(SRD_OGL_FILE_NAME)
        rescue Errno::ENOENT
          # file was not there
        end
        File.open(SRD_OGL_FILE_NAME, "wb") do |file|
          response = HTTP.get(SRD_OGL_SOURCE_URL)
          while (partial = response.readpartial)
            file.write partial
          end
        end
        raise ArgumentError, "SRD OGL File was not successfully downloaded" if !srd_ogl_file_present?

        puts "Downloaded."
      end
      PDF::Reader.new(File.open(SRD_OGL_FILE_NAME, "rb"))
    end

    def get_page_list(args)
      return (1..SRD_OGL_NUM_PAGES).to_a if args.pages.nil?

      [args.pages, args.extras].flatten
        .map { |p| /^(\d+)-(\d+)/ =~ p ? (Regexp.last_match(1)..Regexp.last_match(2)).to_a : p }.flatten.compact
        .map(&:to_i).sort.uniq
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
      byebug
      Srd5SectionList.new_from_run_groups(run_groups).write
    end

    emit_stuff(reader, args)
  end
end
