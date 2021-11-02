require "pdf-reader"

class PDF::Reader::ColumnarReceiver < PDF::Reader::PageTextReceiver
  def two_column_run_groups
    PDF::Reader::ColumnarPageLayout.new(@characters, @device_mediabox).run_groups.to_a
  end
end
