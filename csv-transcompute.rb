require 'bundler'
Bundler.setup

require 'smarter_csv'
require 'ostruct'
require 'csv'

require 'pry'

headers = %w{year site_no name category species order family unknown1 abundance unknown2
                          unknown3 unknown4 unknown5 unknown6}
count = headers.count

csv = SmarterCSV.process('Below South Bend.csv',
                         {headers_in_file: false,
                          user_provided_headers: headers})
junk_row = csv.pop

fixed_headers = [ 'site_name', 'year' ]
all_species =
  csv.map { |l| l[:species] }

m = abundances = csv.map do |l|
  category = l.delete(:category)

  site_name   = l.delete(:name)
  year        = l.delete(:year)
  species     = l.delete(:species)
  header = {species => [site_name, year]}
  abundance = l[:abundance]
  { header => abundance }
end

sample = []

first_flattened_rows =
abundances.map do |n|

  species = n.keys.first.keys.first
  header_slug = n.keys.first[species]
  name = header_slug[0]
  year = header_slug[1]
  key = [name, year]
  sample << key
  abundance = n[{species => [name, year]}]

  {species: species, name: name, year: year, abundance: abundance}
end

final_output = {}

first_flattened_rows.map do |p|
  slice = [p[:name], p[:year], p[:species]]
  final_output[slice] = p[:abundance]
end

sample.map do |name_year|
  all_species.map do |species|
    name = name_year[0]
    year = name_year[1]
    slice = [name, year, species]
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
  species = n[2]
  abundance = value
  row_slice = csv_output[[name, year]] ||= {}
  row_slice[species] = abundance
end

final_csv_really = csv_output.map do |csv_row|
  name = csv_row[0][0]
  year = csv_row[0][1]
  rhs = csv_row[1]
  keys = rhs.keys.sort # sorted all_species
  values = keys.map {|k| rhs[k]}
  [name, year, *values]
end

sorted_all_species = all_species.uniq.sort
final_csv_really.unshift ['name', 'year', *sorted_all_species]

output = [final_csv_really, sorted_all_species]
csv_output_txt = CSV.generate do |csv| final_csv_really.each {|row| csv << row}; end

File.write('csv_output.csv', csv_output_txt)