module Annotate
  def self.version
    @version ||= File.read(File.expand_path("../../../VERSION", __FILE__)).chomp
  end
end
