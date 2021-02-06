# frozen_string_literal: true
require './lib/my_csv2'
require 'forwardable'
class GammaCsv < MyCsv2
  def initialize(name, filename: 'FFG_analysis020521.csv',
                 headers: true,
                 user_headers:)
    super(name, filename: filename, headers: headers, user_headers: user_headers)
  end
end
