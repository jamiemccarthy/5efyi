module Srd5Section

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
      # or "Appendix ph-b:Fantasy-historicalPantheons" haha
      subclass = section_title_runs.map { |run| run_text_clean(run).downcase.capitalize }.join("")
      puts "subclass: #{subclass}"
      Object.const_get("Srd5Section::#{subclass}") rescue nil || Srd5Section::Base
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
      File.join(dir, subdirs, filename)
    end

    def self.subdirs
      ["public", "srd"]
    end

    def self.run_text_clean(run)
      run_text = run.text.dup
      run_text.gsub!(/[\s\u00a0]+/, " ") # if new_font_size < 10 ??
      run_text.gsub!(/\s*-\u00ad\u2010\u2011?\s*/, "-")
      run_text.strip!
      run_text
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
      when 11, 12; "h4"
      when 13; "h3"
      when 18; "h2"
      when 25; "h1"
      else "p"
      end
    end

    def self.run_text_html(run)
      run_text = nil
      run_text_clean = run_text_clean(run)
      run_text_cap_sentence = nil
      if matches = run_text_clean.match(/^(?<capsentence>(?:[A-Z][\w-]+)(?: [A-Z][\w-]+)*)(?<rest>\..*)$/)
        run_text = "</p><p><b>#{matches[:capsentence]}</b>#{matches[:rest]}"
      else
        run_text = run_text_clean
      end
      # TODO check for "\t" leading run.text followed by a short sentence
      # with capitalized words ending in a period. If so, bold it and add
      # a paragraph break
      run_text
    end

    def section_runs_by_size
      @section_runs.slice_when { |run_a, run_b| run_a.font_size != run_b.font_size }
    end

    def self.mkdirs
      Dir.mkdir(get_section_dir, 0755) unless Dir.exist?(get_section_dir)
      abs_subdir = get_section_dir
      subdirs.each do |subdir|
        abs_subdir = File.join(abs_subdir, subdir)
        Dir.mkdir(abs_subdir, 0755) unless Dir.exist?(abs_subdir)
      end
    end

    def write_file
      self.class.mkdirs
      File.open(section_filename, "w", 0644) do |io|
        io.write(
          section_runs_by_size.map do |runs|
            tag = self.class.section_runs_tag(runs)
            "<#{tag}>" +
              runs.map { |run| self.class.run_text_html(run) }.join("\n") +
              "</#{tag}>"
          end.join("\n")
        )
      end
    end

    def self.run_break?(run)
      # Should we break to a new page starting with this run?
      run.font_size >= 25
    end
  end

end
