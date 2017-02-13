# frozen_string_literal: true
require 'rotoscope/rotoscope'

class Rotoscope
  def self.trace(output_path, blacklist = [])
    rs = new(output_path, blacklist, 'w')
    rs.trace { yield rs }
    rs.close
    rs
  end
end
