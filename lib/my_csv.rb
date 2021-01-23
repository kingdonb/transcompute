# frozen_string_literal: true
require 'forwardable'
class MyCsv
  def initialize(filename:, headers:, user_headers:)
    SmarterCSV.process(filename
                       {headers_in_file: headers,
                        user_provided_headers: user_headers})
  end
end
