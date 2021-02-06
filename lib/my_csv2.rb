# frozen_string_literal: true
require 'forwardable'
class MyCsv2
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
    @properties = {csv: csv, sample: [], family_sample: [], feeding_guild_sample: [],
                   csv_family_output: { }, csv_feeding_guild_output: { },
                   csv_output_family_txt: nil, csv_output_feeding_guild_txt: nil
    }
  end

  def csv
    self[:csv]
  end

  def sample
    self[:sample]
  end

  def family_sample
    self[:family_sample]
  end

  def feeding_guild_sample
    self[:feeding_guild_sample]
  end

  def abundances
    csv.map do |l|
      category = l.delete(:category)

      date          = l[:date]
      site_name     = l[:site_name]
      location      = l[:location]
      family        = l[:family]
      feeding_guild = l[:feeding_guild]

      header = {
        "#{family},#{feeding_guild}" => [date, site_name, location]
      }

      abundance = l[:abundance]
      { header => abundance }
    end
  end

  def first_flattened_rows!
    abundances.map do |n|

      family_and_feeding_guild = n.keys.first.keys.first
      header_slug = n.keys.first[family_and_feeding_guild]
      date = header_slug[0]
      site_name = header_slug[1]
      location = header_slug[2]
      key = [date, site_name, location]
      sample << key
      abundance = n[{family_and_feeding_guild => [date, site_name, location]}]

      {family_and_feeding_guild: family_and_feeding_guild,
       site_name: site_name, date: date, location: location,
       abundance: abundance}
    end
  end


  def zeta(input)
    output = {}

    input.map do |key, value|
      n = [*key]
      date      = n[0]
      site_name = n[1]
      location  = n[2]
      family    = n[3]
      feeding_guild   = n[5]

      abundance = value
      row_slice = output[[date, site_name, location]] ||= {}

      if feeding_guild.present?
        slug = "#{family},#{feeding_guild}"
      else
        slug = family
      end

      if row_slice[slug].present?
        row_slice[slug] += abundance
      else
        row_slice[slug] = abundance
      end
    end

    output
  end
  def all_families_and_feeding_guilds
    csv.map { |l| [ l[:family] + ',' + l[:feeding_guild] ] }
  end

  def sorted_all_families
    all_families_and_feeding_guilds.map{|k| k.first.split(',')[0]}.uniq.sort
  end
  def sorted_all_feeding_guilds
    all_families_and_feeding_guilds.map{|k| k.first.split(',')[1]}.uniq.sort
  end

  def process
    first_flattened_rows!.map do |p|
      family, feeding_guild = *p[:family_and_feeding_guild].split(',')
      family_slice = [p[:date], p[:site_name], p[:location], family]
      feeding_guild_slice = [p[:date], p[:site_name], p[:location], feeding_guild]

      if family_output[family_slice].present?
        family_output[family_slice] += p[:abundance]
      else
        family_output[family_slice] = p[:abundance]
      end

      if feeding_guild_output[feeding_guild_slice].present?
        feeding_guild_output[feeding_guild_slice] += p[:abundance]
      else
        feeding_guild_output[feeding_guild_slice] = p[:abundance]
      end
    end

    family_alpha = zeta(family_output)
    feeding_guild_alpha = zeta(feeding_guild_output)

    sample.map do |date_site_name_location|
      all_families_and_feeding_guilds.map do |family_and_feeding_guild|
        family, feeding_guild = *family_and_feeding_guild.first.split(',')
        date = date_site_name_location[0]
        site_name = date_site_name_location[1]
        location = date_site_name_location[2]
        family_slice = [date, site_name, location, family]
        feeding_guild_slice = [date, site_name, location, "#{family},#{feeding_guild}"]

        unless family_alpha[[date, site_name, location]].key? family
          family_alpha[[date, site_name, location]][family] = 0
        end
        unless feeding_guild_alpha[[date, site_name, location]].key? feeding_guild
          feeding_guild_alpha[[date, site_name, location]][feeding_guild] = 0
        end
      end
    end

    family_beta = family_alpha.map do |csv_row|
      date = csv_row[0][0]
      site_name = csv_row[0][1]
      location = csv_row[0][2]
      rhs = csv_row[1]
      keys = rhs.keys.sort # sorted all_families
      values = keys.map {|k| rhs[k]}
      [date, site_name, location, *values]
    end

    feeding_guild_beta = feeding_guild_alpha.map do |csv_row|
      date = csv_row[0][0]
      site_name = csv_row[0][1]
      location = csv_row[0][2]
      rhs = csv_row[1]
      keys = rhs.keys.sort # sorted all_feeding_guilds
      values = keys.map {|k| rhs[k]}
      [date, site_name, location, *values]
    end

    family_beta.unshift ['name', 'date', *sorted_all_families]
    feeding_guild_beta.unshift ['name', 'date', *sorted_all_feeding_guilds]

    output = [family_beta, feeding_guild_beta, sorted_all_families, sorted_all_feeding_guilds]
    self[:csv_output_family_txt] =
      CSV.generate do |csv| family_beta.each {|row| csv << row}; end
    self[:csv_output_feeding_guild_txt] =
      CSV.generate do |csv| feeding_guild_beta.each {|row| csv << row}; end
  end

  def family_output
    self[:csv_family_output]
  end

  def feeding_guild_output
    self[:csv_feeding_guild_output]
  end

  def family_csv
    self[:csv_output_family_txt]
  end

  def feeding_guild_csv
    self[:csv_output_feeding_guild_txt]
  end
end
