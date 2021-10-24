module Srd5Section
  module Utility

    def self.break_into_sections(run_groups)
      sections = [[]]
      current = nil
      category = nil
      monsters_index = nil
      run_groups.each do |run_group|
        next if run_group.count < 1

        if current == "Monsters"
          if run_group[0].font_size == 18 && run_group[0].text.match?(/Monsters \([A-Z]\)/)
            current = "Monsters, Each"
            puts "current: #{current}"
          end
          # skip appending "Monsters (Z)" anywhere, it doesn't make sense for a website
        elsif monsters_index && current == "Monsters, Each" && run_group[0].font_size < 25
          if run_group[0].font_size == 13
            # e.g. "Angels", a monster descriptor
            category = run_group[0].text
            puts "category: #{category}"
            sections[monsters_index].concat(run_group)
          elsif run_group[0].font_size == 12
            # e.g. "Aboleth", an actual monster
            # First put the name of the monster onto the Monsters page (we'll figure
            # out what to do with these later)
            sections[monsters_index].concat(run_group)
            # If it's in a category, maybe like append the category name to the first
            # run_group of this monster's section, and find a way to work it into
            # its text later
            # If it's the first monster NOT in the previous category, now's a good time
            # to set category back to nil. I guess hard-code the list of "first monsters
            # not in the previous category" :/
            # Anyway, now we create a new section for this monster, into which this
            # run_group and the following run_groups will be applied
            sections << []
          end
        elsif run_group[0].font_size == 25
          if current == "Monsters"
            # time to move on to the appendixes, right? check what this run is
            #byebug
          end
          current = run_group[0].text
          category = nil
          monsters_index = nil
          sections << []
          if current == "Monsters"
            monsters_index = sections.count-1
          end
        end
        sections[-1].concat(run_group)
      end
      sections
    end
  end
end
