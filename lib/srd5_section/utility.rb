# My PDF::Reader::ColumnarPageLayout defines a #run_groups method which groups the
# runs of <https://github.com/yob/pdf-reader/blob/v2.4.2/lib/pdf/reader/page_layout.rb#L20>
# into arrays. Each run_group is an array of runs that all have the same font size.

module Srd5Section
  module Utility
    def self.get_sections(run_groups)

      section_list = Srd5SectionList.new_from_run_groups(run_groups)
      current = nil
      category = nil
      monsters_index = nil

        # TODO move this logic into the class hierarchy
        if current == "Monsters"
          if run_group[0].font_size == 18 && run_group[0].text.match?(/Monsters \([A-Z]\)/)
            current = "Monsters, Each"
            puts "current: #{current}"
          end
          # skip appending "Monsters (Z)" anywhere, it doesn't make sense for a website
        elsif monsters_index && current == "Monsters, Each" && run_group[0].font_size < 25
          case run_group[0].font_size
          when 13
            # e.g. "Angels", a monster descriptor
            category = run_group[0].text
            puts "category: #{category}"
            sections[monsters_index].concat(run_group)
          when 12
            # e.g. "Aboleth", an actual monster
            # First put the name of the monster onto the Monsters page (we'll figure
            # out what to do with these later)
            sections[monsters_index].concat(run_group)
            # If it's in a category, maybe like append the category name to the first
            # run_group of this monster's section, and find a way to work it into
            # its text later
            # Anyway, now we create a new section for this monster, into which this
            # run_group and the following run_groups will be applied.
            sections << []
            # If it's the first monster NOT in the previous category, now's a good time
            # to set category back to nil. I guess hard-code the list of "first monsters
            # not in the previous category" :/
            if %w[
              Ankheg
              Doppelganger
              Drider
              Elf,.*Drow
              Gargoyle
              Ghost
              Gibbering.*Mouther
              Gorgon
              Harpy
              Magmin
              Merfolk
              Ogre
              Orc
              Specter
              Sprite
              Wight
            ].any? { |monster| run_group[0].text.match? monster }
              category = nil
            end
          end
        elsif run_group[0].font_size == 25
          if current == "Monsters"
            # time to move on to the appendixes, right? I think this is working, but need to check
            # byebug
          end
          current = run_group[0].text
          category = nil
          monsters_index = nil
          sections << []
          if current == "Monsters"
            monsters_index = sections.count - 1
          end
        end
      end

      sections
    end
  end
end
