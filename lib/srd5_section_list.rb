# Srd5SectionList:
# [
#   Srd5Section::Monsters (subclass of Srd5Section::Base)
#     section_runs: [
#       PDF::Reader::SRD5TextRun: [25: Monsters],
#       PDF::Reader::SRD5TextRun: [12: Monsters are bad and mean, 12: and not fun],
#       PDF::Reader::SRD5TextRun: [8: Also stinky]
#     ],
#   Srd5Section::Monsters::Kobold (subclass of SrdSection::Base)
#     section_runs: [
#       PDF::Reader::SRD5TextRun: [12: Kobold],
#       PDF::Reader::SRD5TextRun: [8: Kobolds are really, 8: okay once you, 8: get to know them]
#     ],
#   Srd5Section::Base
#     section_runs: [
#       PDF::Reader::SRD5TextRun,
#       PDF::Reader::SRD5TextRun
#     ],
# ]

class Srd5SectionList < Array
  attr_accessor :current_category

  def self.new_from_run_groups(run_groups)
    object = Srd5SectionList.new
    while run_group = run_groups.shift
      object.append( Srd5Section::Base.new ) if !object.current_section&.want_this_run_group?(run_group)
      object.current_section.append_run_group(run_group)
    end
    object
  end

  def current_section
    self.blank? ? nil : self[-1]
  end

  def inspect
    "{#{self.count}}: #{self.map(&:inspect)}"
  end

  def short_inspect
    "{#{self.count}}: #{self.first(10).map(&:short_inspect)}"
  end

  def write
    byebug
    while section = shift
      section.write_file
    end
  end
end
