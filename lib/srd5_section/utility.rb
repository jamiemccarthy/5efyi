module Srd5Section
  module Utility
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
end
