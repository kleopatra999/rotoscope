# frozen_string_literal: true
require 'rotoscope/rotoscope'
require 'fileutils'
require 'tempfile'
require 'csv'

class Rotoscope
  InvalidStateError = Class.new(StandardError)

  class << self
    def trace(dest, blacklist: [], flatten: false, &block)
      if flatten
        return flat_trace(dest, blacklist, &block)
      end
      if dest.is_a?(String)
        return event_trace(dest, blacklist, &block)
      end
      io_event_trace(dest, blacklist, &block)
    end

    private

    def with_temp_file(name)
      temp_file = Tempfile.new(name)
      yield temp_file
    ensure
      temp_file.close! if temp_file
    end

    def temp_event_trace(blacklist, block)
      with_temp_file("rotoscope_output") do |temp_file|
        rs = event_trace(temp_file.path, blacklist, &block)
        yield rs
        rs
      end
    end

    def flat_trace(dest, blacklist, &block)
      temp_event_trace(blacklist, block) do |rs|
        rs.flatten(dest)
      end
    end

    def io_event_trace(dest_io, blacklist, &block)
      temp_event_trace(blacklist, block) do |rs|
        File.open(rs.log_path) do |rs_file|
          IO.copy_stream(rs_file, dest_io)
        end
      end
    end

    def event_trace(dest_path, blacklist)
      rs = Rotoscope.new(dest_path, blacklist)
      rs.trace { yield rs }
      rs
    ensure
      rs.close if rs
    end
  end

  def flatten(dest)
    if dest.is_a?(String)
      File.open(dest, 'w') do |file|
        flatten_into(file)
      end
    else
      flatten_into(dest)
    end
  end

  def closed?
    state == :closed
  end

  def inspect
    "Rotoscope(state: #{state}, log_path: \"#{short_log_path}\", object_id: #{format('0x00%x', object_id << 1)})"
  end

  private

  Caller = Struct.new(:entity, :method_name)
  DEFAULT_CALLER = Rotoscope::Caller.new('<ROOT>', 'unknown').freeze
  CSV_HEADER_FIELDS = %w(entity method_name method_level filepath lineno caller_entity caller_method_name)

  def flatten_into(io)
    raise(Rotoscope::InvalidStateError, "#{inspect} must be closed to perform operation") unless closed?

    call_stack = []
    io.puts(CSV_HEADER_FIELDS.join(','))

    CSV.foreach(log_path, headers: true) do |line|
      case line.fetch('event')
      when '---'
        call_stack = []
      when 'call'
        caller = call_stack.last || DEFAULT_CALLER
        line << { 'caller_entity' => caller.entity, 'caller_method_name' => caller.method_name }
        call_stack << Rotoscope::Caller.new(line.fetch('entity'), line.fetch('method_name'))
        out_str = CSV_HEADER_FIELDS.map { |field| line.fetch(field) }.join(',')
        io.puts(out_str)
      when 'return'
        caller = Rotoscope::Caller.new(line.fetch('entity'), line.fetch('method_name'))
        call_stack.pop if call_stack.last == caller
      end
    end
    puts "Rotoscope#flatten_into: #{call_stack.size} unpoped frames on call_stack"
  end

  def short_log_path
    return log_path if log_path.length < 40
    chars = log_path.chars
    "#{chars.first(17).join('')}...#{chars.last(20).join('')}"
  end
end
