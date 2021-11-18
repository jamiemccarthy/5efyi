require "pdf-reader"

class PDF::Reader::ColumnarPageLayout < PDF::Reader::PageLayout
  def initialize(runs, mediabox)
    runs = convert_runs_to_srd5(runs)
    super(runs, mediabox)
  end

  def convert_runs_to_srd5(runs)
    runs.map do |run|
      PDF::Reader::Srd5TextRun.new(
        run.x, run.y, run.width, run.font_size, run.text
      )
    end
  end

  # Return the runs in the order generally used by the SRD,
  # excluding the footer generally used by the SRD. Basically
  # we sort the left column "above" the right column. This
  # ignores the order defined by TextRun#<=>
  def run_sort_val(run)
    run.y + (run.x < 325 ? 10_000 : 0)
  end

  def runs_in_columnar_order
    # This is matz's technique for a stable sort
    i = 0
    @runs
      .select { |r| r.y >= 90 } # exclude page footer ("Not for resale" thru page number)
      .sort_by { |r| [run_sort_val(r), i += 1] }
      .reverse # In a PDF, the y column extends from 0 up
  end

  def run_groups
    runs_in_columnar_order.slice_when { |run_a, run_b| run_a.font_size != run_b.font_size }
  end
end
