# frozen_string_literal: true
require 'forwardable'
class MyCsv
  extend Forwardable
  def_delegators :@properties, :[], :[]=

  def initialize(name, filename:, headers:, user_headers:)
    orig_txt = File.read(filename)
    unless orig_txt.valid_encoding?
      File.write(filename, orig_txt.scrub!)
    end

    csv = SmarterCSV.process(filename,
                       {headers_in_file: headers,
                        user_provided_headers: user_headers})
    @name = name
    @properties = {csv: csv, sample: [], species_sample: [], order_sample: [],
                   csv_species_output: { }, csv_order_output: { },
                   csv_output_species_txt: nil, csv_output_order_txt: nil
    }
  end

  def csv
    self[:csv]
  end

  def species_output
    self[:csv_species_output]
  end

  def order_output
    self[:csv_order_output]
  end

  def sample
    self[:sample]
  end

  def order_sample
    self[:order_sample]
  end

  def species_sample
    self[:species_sample]
  end

  def zeta(input)
    output = {}

    input.map do |key, value|
      n = [*key]
      name    = n[0]
      year    = n[1]
      species = n[2]
      order   = n[3]

      abundance = value
      row_slice = output[[name, year]] ||= {}

      if order.present?
        slug = "#{species},#{order}"
      else
        slug = species
      end

      if row_slice[slug].present?
        row_slice[slug] += abundance
      else
        row_slice[slug] = abundance
      end
    end

    output
  end

  def first_flattened_rows!
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
  end

  def all_species_and_orders
    csv.map { |l| [ l[:species] + ',' + l[:order] ] }
  end

  def sorted_all_species
    all_species_and_orders.map{|k| k.first.split(',')[0]}.uniq.sort
  end
  def sorted_all_orders
    all_species_and_orders.map{|k| k.first.split(',')[1]}.uniq.sort
  end

  def abundances
    csv.map do |l|
      category = l.delete(:category)

      site_name   = l[:name]
      year        = l[:year]
      species     = l[:species]
      order       = l[:order]
      header = {"#{species},#{order}" => [site_name, year]}
      abundance = l[:abundance]
      { header => abundance }
    end
  end

  def process
    # fixed_headers = [ 'site_name', 'year' ]

    first_flattened_rows!.map do |p|
      species, order = *p[:species_and_order].split(',')
      species_slice = [p[:name], p[:year], species]
      order_slice = [p[:name], p[:year], order]

      if species_output[species_slice].present?
        species_output[species_slice] += p[:abundance]
      else
        species_output[species_slice] = p[:abundance]
      end

      if order_output[order_slice].present?
        order_output[order_slice] += p[:abundance]
      else
        order_output[order_slice] = p[:abundance]
      end
    end

    species_alpha = zeta(species_output)
    order_alpha = zeta(order_output)

    sample.map do |name_year|
      all_species_and_orders.map do |species_and_order|
        species, order = *species_and_order.first.split(',')
        name = name_year[0]
        year = name_year[1]
        species_slice = [name, year, species]
        order_slice = [name, year, "#{species},#{order}"]
        unless species_alpha[[name, year]].key? species
          species_alpha[[name, year]][species] = 0
        end
        unless order_alpha[[name, year]].key? order
          order_alpha[[name, year]][order] = 0
        end
      end
    end

    species_beta = species_alpha.map do |csv_row|
      name = csv_row[0][0]
      year = csv_row[0][1]
      rhs = csv_row[1]
      keys = rhs.keys.sort # sorted all_species
      values = keys.map {|k| rhs[k]}
      [name, year, *values]
    end

    order_beta = order_alpha.map do |csv_row|
      name = csv_row[0][0]
      year = csv_row[0][1]
      rhs = csv_row[1]
      keys = rhs.keys.sort # sorted all_orders
      values = keys.map {|k| rhs[k]}
      [name, year, *values]
    end

    species_beta.unshift ['name', 'year', *sorted_all_species]
    order_beta.unshift ['name', 'year', *sorted_all_orders]

    output = [species_beta, order_beta, sorted_all_species, sorted_all_orders]
    self[:csv_output_species_txt] =
      CSV.generate do |csv| species_beta.each {|row| csv << row}; end
    self[:csv_output_order_txt] =
      CSV.generate do |csv| order_beta.each {|row| csv << row}; end
  end

  def species_csv
    self[:csv_output_species_txt]
  end

  def order_csv
    self[:csv_output_order_txt]
  end
end
