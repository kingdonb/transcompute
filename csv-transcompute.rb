require 'bundler'
Bundler.setup

require 'smarter_csv'
require 'ostruct'
require 'csv'
require 'active_support'
require 'pry'
require './lib/above_csv'
require './lib/below_csv'

begin
raise StandardError, %Q{No filename, what CSV file to process?\nusage: make FILE="Below\\ South\\ Bend.csv"} \
  unless
( filename, filename2  = ARGV[0], ARGV[1];
  filename.present? && filename2.present?)

above_headers = %w{year site_no name category species order family unknown1 abundance unknown2}
above_csv = AboveCsv.new('above', filename: filename, user_headers: above_headers)

below_headers = %w{year site_no name category species order family unknown1 abundance unknown2
                          unknown3 unknown4 unknown5 unknown6}
below_csv = BelowCsv.new('below', filename: filename2, user_headers: below_headers)

junk_row = below_csv[:csv].pop

above_csv.process
below_csv.process

File.write('csv_output_above_species.csv', above_csv.species_csv)
File.write('csv_output_above_order.csv', above_csv.order_csv)
File.write('csv_output_below_species.csv', below_csv.species_csv)
File.write('csv_output_below_order.csv', below_csv.order_csv)

rescue StandardError => e
  puts e.message
 puts e.backtrace
  Kernel.exit(1)
end
