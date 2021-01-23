require 'bundler'
Bundler.setup

require 'smarter_csv'
require 'ostruct'
require 'csv'
require 'active_support'
require 'pry'

headers = %w{year site_no name category species order family unknown1 abundance unknown2}
count = headers.count

begin
raise StandardError, %Q{No filename, what CSV file to process?\nusage: make FILE="Below\\ South\\ Bend.csv"} \
  unless
( filename, missing  = ARGV[0], ARGV[1];
  filename.present?)

csv = SmarterCSV.process( filename,
                         {headers_in_file: true,
                          user_provided_headers: headers})
junk_row = csv.pop

fixed_headers = [ 'site_name', 'year' ]
all_species_and_orders =
  csv.map { |l| [ l[:species] + ',' + l[:order] ] }

m = abundances = csv.map do |l|
  category = l.delete(:category)

  site_name   = l.delete(:name)
  year        = l.delete(:year)
  species     = l.delete(:species)
  order       = l.delete(:order)
  header = {"#{species},#{order}" => [site_name, year]}
  abundance = l[:abundance]
  { header => abundance }
end

sample = []

first_flattened_rows =
abundances.map do |n|

  species_and_order = n.keys.first.keys.first
  header_slug = n.keys.first[species_and_order]
  name = header_slug[0]
  year = header_slug[1]
  key = [name, year]
  sample << key
  abundance = n[{species_and_order => [name, year]}]

  {species_and_order: species_and_order, name: name, year: year, abundance: abundance}
end

final_output = {}

first_flattened_rows.map do |p|
  species, order = *p[:species_and_order].split(',')
  slice = [p[:name], p[:year], order]
  final_output[slice] = p[:abundance]
end

sample.map do |name_year|
  all_species_and_orders.map do |species_and_order|
    species, order = *species_and_order.first.split(',')
    name = name_year[0]
    year = name_year[1]
    slice = [name, year, order]
    unless final_output.key? slice
      final_output[slice] = 0
    end
  end
end

csv_output = { }

final_output.map do |key, value|
  n = [*key, value]
  name = n[0]
  year = n[1]
  order = n[2]
  abundance = value
  row_slice = csv_output[[name, year]] ||= {}

  if row_slice[order].present?
    row_slice[order] += abundance
  else
    row_slice[order] = abundance
  end
end

final_csv_really = csv_output.map do |csv_row|
  name = csv_row[0][0]
  year = csv_row[0][1]
  rhs = csv_row[1]
  keys = rhs.keys.sort # sorted all_species
  values = keys.map {|k| rhs[k]}
  [name, year, *values]
end

sorted_all_orders = all_species_and_orders.map{|k| k.first.split(',')[1]}.uniq.sort
final_csv_really.unshift ['name', 'year', *sorted_all_orders]

output = [final_csv_really, sorted_all_orders]
csv_output_txt = CSV.generate do |csv| final_csv_really.each {|row| csv << row}; end

File.write('csv_output.csv', csv_output_txt)
rescue StandardError => e
  puts e.message
# puts e.backtrace
  Kernel.exit(1)
end
