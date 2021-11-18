require "pdf-reader"

class PDF::Reader::Srd5TextRun < PDF::Reader::TextRun
#  def initialize(x, y, width, font_size, text)
#    puts "#{self.class} initializing"
#    super
#  end

  # I have to override this method because the superclass's implementation
  # hardcodes the name of its own class rather than using self.class.
  # The code is the same as of pdf-reader 0.50.
  def +(other)
    raise ArgumentError, "#{other} cannot be merged with this run" unless mergable?(other)

    if (other.x - endx) <( font_size * 0.2)
      self.class.new(x, y, other.endx - x, font_size, text + other.text)
    else
      self.class.new(x, y, other.endx - x, font_size, "#{text} #{other.text}")
    end
  end

  def text_clean
    clean_text = text.dup
    clean_text.gsub!(/[\s\u00a0]+/, " ") # if new_font_size < 10 ??
    clean_text.gsub!(/\s*-\u00ad\u2010\u2011?\s*/, "-")
    clean_text.strip!
    clean_text
  end

  def text_html
    html_text = text_clean
    if (matches = html_text.match(/^(?<capsentence>(?:[A-Z][\w-]+)(?: [A-Z][\w-]+)*)(?<rest>\..*)$/))
      # TODO wait why did I *start* this with </p>, that's not cool
      "</p><p><b>#{matches[:capsentence]}</b>#{matches[:rest]}"
    else
      html_text
    end
    # TODO check for "\t" leading run.text followed by a short sentence
    # with capitalized words ending in a period. If so, bold it and add
    # a paragraph break
  end

  # I don't like the gem's standard #inspect, in particular it doesn't play well with the \r's
  def inspect
    "#{font_size}: #{text_clean}"
  end

  def short_inspect
    text_clean_short = text_clean
    text_clean_short = text_clean_short[0..37] + "..." if text_clean_short.length >= 42
    "#{font_size}: #{text_clean_short}"
  end
end
