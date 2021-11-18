# An Srd5Section ("section") corresponds to a webpage in the srd5 dir of the website.
# Some sections are subclasses of this base class and behave differently.
# A section knows how to write out its static webpage.
# A section is built by appending run_groups to it, TKTK

module Srd5Section
  class Base

    # section_runs is an Array of PDF::Reader::TextRun's, specifically of
    # PDF::Reader::Srd5TextRun's.
    attr_accessor :section_runs, :section_title, :section_filename

    def initialize(old_obj = nil)
      if old_obj
        @section_runs = old_obj.section_runs
        @section_title = old_obj.section_title
        @section_filename = old_obj.section_filename
      else
        @section_runs = []
        @section_title = nil
        @section_filename = nil
      end
    end

    def inspect
      "[#{section_runs.count}]: #{section_runs.map(&:short_inspect).join(' ')}"
    end

    def short_inspect
      "[#{section_runs.count}]: #{section_runs.first(10).map(&:short_inspect).join(' ')}"
    end

    # TODO hm maybe make this return symbols depending on size
    def is_title_run?(run)
      run.font_size >= 25
    end

    def want_this_run_group?(run_group)
      # Does this section want to append this run group or should it go
      # elsewhere?
      run_group[0].font_size < 25
    end

    def should_write?
      section_filename.present? && section_runs.present?
    end

    def get_proper_class
      # TODO: nope, this is wrong, many runs will have multiple section_title runs,
      # and we shouldn't reclass as soon as we have the first one, not without
      # adding some "business" logic to this.
      self.class if section_title_runs.blank?

      # TODO: fix this, it doesn't work for e.g. "Beyond 1st level" or "Using abilityScores"
      # or "Appendix ph-b:Fantasy-historicalPantheons" haha
      if self.section_runs[0]&.text&.match?(/If.{3,5}you.{3,5}note.{3,5}any.{3,5}errors.{3,5}in.{3,5}this/)
        subclass = Srd5Section::Null
      else
        subclass = section_title_runs.map { |run| run.text_clean.downcase.capitalize }.join
      end

      begin
        Object.const_get("Srd5Section::#{subclass}")
      rescue NameError
        self.class
      end
    end

    def update_class!
      # TODO optimize this, don't call it for every run group
      new_class = get_proper_class
      if new_class == self.class
        self
      else
        new_class.new(self)
      end
    end

    def append_run_group(run_group)
      run_group.shift while run_group.count > 0 && run_group[0].text.match?(/\A[\s\u00a0]*\z/)
      self.section_runs += run_group

      update_class!
    end

    # def self.create(section_runs)
    #   section_title_runs = get_section_title_runs(section_runs)
    #   return nil unless section_title_runs
    # 
    #   get_subclass(section_title_runs).new(section_runs)
    # end

    def section_title_runs
      # puts "section_title_runs with: #{self.inspect}"
      runs = self.section_runs.select { |run| is_title_run?(run) }
      runs = [self.section_runs[0]] if runs.blank?
      # Skip the introduction <- TODO I think I handled this elsewhere now

      runs
    end

    # def initialize(section_runs)
    #   @section_runs = section_runs
    #   @section_title = self.class.get_section_title(self.class.get_section_title_runs(section_runs))
    #   @section_filename = self.class.get_section_filename(section_title)
    # end

    def self.get_section_title
      section_title_runs.map { |run| run.text_clean }.join(" ")
    end

    def self.section_dir
      Dir.pwd
    end

    def self.get_section_filename(section_title)
      title_to_filename(section_title, section_dir)
    end

    def self.title_to_filename(title, dir)
      filename = title.downcase.gsub(/[[[:space:]][[:punct:]]]+/m, "-")
      filename.gsub!(/^-+/, "")
      filename.gsub!(/-+$/, "")
      filename.squeeze!("-")
      return nil if filename.blank?

      File.join(dir, subdirs, filename)
    end

    def self.subdirs
      ["public", "srd"]
    end

    def self.section_runs_tag(runs)
      # 10 and 8 are sidebar title and sidebar text
      # 9 is ordinary text
      # 11 is a typo for 12
      # 12 is a section header, like "Proficiencies" or a spell name
      # 13 is a bigger section header, like a class feature ("Spellcasting" or "Wild Shape"),
      #    "Spell Slots," "Wizard Spells," "Outer Planes"
      # 18 is an even bigger section header, like "Class Features", "Armor", "Making an Attack"
      # 25 is the title of a "chapter" (not a book chapter), like "Feats", "Fighter", "Equipment"
      case runs[0].font_size
      when 11, 12 then "h4"
      when 13 then "h3"
      when 18 then "h2"
      when 25 then "h1"
      else "p"
      end
    end

    def section_runs_by_size
      @section_runs.slice_when { |run_a, run_b| run_a.font_size != run_b.font_size }
    end

    def self.mkdirs
      Dir.mkdir(section_dir, 0o755) unless Dir.exist?(section_dir)
      abs_subdir = section_dir
      subdirs.each do |subdir|
        abs_subdir = File.join(abs_subdir, subdir)
        Dir.mkdir(abs_subdir, 0o755) unless Dir.exist?(abs_subdir)
      end
    end

    def write_file
      return nil unless should_write?

      self.class.mkdirs
      File.open(section_filename, "w", 0o644) do |io|
        io.write(
          section_runs_by_size.map do |runs|
            tag = self.class.section_runs_tag(runs)
            "<#{tag}>" +
              runs.map { |run| run.text_html }.join("\n") +
              "</#{tag}>"
          end.join("\n")
        )
      end
    end
  end
end
