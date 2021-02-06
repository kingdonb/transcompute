require 'bundler'
Bundler.setup

require 'smarter_csv'
require 'ostruct'
require 'csv'
require 'active_support'
require 'pry'
require './lib/gamma_csv'

begin
raise StandardError, %Q{No filename, what CSV file to process?\nusage: make FILE="Below\\ South\\ Bend.csv"} \
  unless
( # filename, filename2  = ARGV[0], ARGV[1];
  filename = ARGV[0]
  filename.present? )
# && filename2.present?)

# above_headers = %w{year site_no name category species order family unknown1 abundance unknown2}
# above_csv = AboveCsv.new('above', filename: filename, user_headers: above_headers)
#
# below_headers = %w{year site_no name category species order family unknown1 abundance unknown2
#                           unknown3 unknown4 unknown5 unknown6}
# below_csv = BelowCsv.new('below', filename: filename2, user_headers: below_headers)

gamma_headers = %w{date site_name location family number feeding_guild}
gamma_csv = GammaCsv.new('gamma', filename: filename, user_headers: gamma_headers)

# junk_row = below_csv[:csv].pop

# above_csv.process
# below_csv.process

# File.write('csv_output_above_species.csv', above_csv.species_csv)
# File.write('csv_output_above_order.csv', above_csv.order_csv)
# File.write('csv_output_below_species.csv', below_csv.species_csv)
# File.write('csv_output_below_order.csv', below_csv.order_csv)

gamma_csv.process

File.write('csv_output_gamma_family.csv', gamma_csv.family_csv)
File.write('csv_output_gamma_feeding_guild.csv', gamma_csv.feeding_guild_csv)

rescue StandardError => e
  puts e.message
  puts e.backtrace
  Kernel.exit(1)
end
