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

end
