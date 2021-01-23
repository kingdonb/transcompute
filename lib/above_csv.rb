# frozen_string_literal: true
require './lib/my_csv'
require 'forwardable'
class AboveCsv < MyCsv
  def initialize(name, filename: 'Above-South-Bend.csv',
                 headers: true,
                 user_headers:)
    super(name, filename: filename, headers: headers, user_headers: user_headers)
  end
end
