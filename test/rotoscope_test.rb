$:.unshift File.expand_path('../../lib', __FILE__)
require 'rotoscope'
require 'minitest/autorun'
require 'zlib'
require 'fileutils'
require 'csv'

module Foo
  def bar; true end
end

class Example
  def normal_method; true end
  def module_method; bar end
  def bar; false end

  def exception_method
    oops
  rescue
    nil
  end

  private
  def oops; raise "I've made a terrible mistake" end
end

Example.prepend(Foo)

class RotoscopeTest < MiniTest::Test
  def setup
    @logfile = File.expand_path('tmp/test.csv.gz')
  end

  def teardown
    # FileUtils.remove_file(@logfile)
  end

  # def test_basic
  #   contents = rotoscope_trace { (Example.new).normal_method }
  #   assert_equal contents.scan(/\Acall/).size, contents.scan(/\Areturn/).size
  #   csv_rows = contents.split("\n")
  #   row = CSV.parse_line(csv_rows[1], headers: csv_rows[0])
  #   assert_equal "Example", row.fetch("entity")
  #   assert_equal "new", row.fetch("method_name")
  #   assert_equal "singleton", row.fetch("method_level")
  # end

  # def test_exception
  #   contents = rotoscope_trace { (Example.new).exception_method }
  #   assert_equal contents.scan(/\Acall/).size, contents.scan(/\Areturn/).size
  # end

  def test_module
    contents = rotoscope_trace { (Example.new).module_method }
    assert_equal contents.scan(/\Acall/).size, contents.scan(/\Areturn/).size

    csv_rows = contents.split("\n")
    row = CSV.parse_line(csv_rows[1], headers: csv_rows[0])
    assert_equal "Example", row.fetch("entity")
    assert_equal "new", row.fetch("method_name")
    assert_equal "singleton", row.fetch("method_level")
  end

  private

  def rotoscope_trace
    Rotoscope.trace(@logfile, %w(.gem /ruby/)) { yield }
    unzip(@logfile)
  end

  def unzip(path)
    File.open(path) { |f| Zlib::GzipReader.new(f).read }
  end
end
