#!/usr/bin/env ruby

require 'csv'
require 'money'
require 'thor'

class Money
  class Currency
    attr_writer :decimal_mark
  end

  # Override: does NOT display a deprecation warning message.
  #
  # @param [String] message The message to display.
  #
  # @return [nil]
  def self.deprecate(message)
    #warn "DEPRECATION WARNING: #{message}"
  end
end

module Argenta
  ##
  # Parses a single CSV file from Argenta
  class Parser

    def initialize(opts = {}, row_map = {})
      @options = {
          :col_sep => ';',
          :headers => :first_row,
          :write_headers => true,
          :return_headers => true,
          :skip_blanks => true,
          :force_quotes => true
      }.merge(opts)

      @header_map_inverted = {
          'Valutadatum' => 'value_date',
          'Ref. v/d verrichting' => 'reference',
          'Beschrijving' => 'transction_type',
          'Bedrag v/d verrichting' => 'amount',
          'Munt' => 'currency',
          'Datum v. verrichting' => 'date',
          'Rekening tegenpartij' => 'beneficiary_account',
          'Naam v/d tegenpartij' => 'beneficiary_name',
          'Mededeling 1' => 'memo_1',
          'Mededeling 2' => 'memo_2'
      }.merge(row_map)

      @header_map = @header_map_inverted.invert
    end

    ##
    # Parses CSV input
    def parse(input)
      output = ''
      CSV.parse(input.join(''), @options) do |row|
        output += CSV.generate_line(row.header_row? ? row : parse_row(row), @options.merge({:col_sep => ','}))
      end
      output
    end

    protected

    def parse_row(row)
      amount_col = @header_map['amount']
      value_date_col = @header_map['value_date']
      date_col = @header_map['date']
      row[amount_col] = parse_amount(row[amount_col], row[@header_map['currency']])
      row[value_date_col] = parse_date(row[value_date_col])
      row[date_col] = parse_date(row[date_col])

      row
    end

    def parse_amount(amount, currency)
      Money.parse(amount, currency).to_s.gsub(/,/, '.')
    end

    def parse_date(date)
      d = Date.strptime(date, '%d-%m-%Y')
      d ? d.strftime('%m/%d/%Y') : nil
    end

  end # class Parser


  class Argenta < Thor
    desc 'parse', 'Parses Argenta CSV input. By default, it uses STDIN to read the input. If the --files option is specified, it will read and merge the specified files.'
    method_option :header, :type => :boolean, :default => true, :desc => 'Whether to include the first header in the output or not.'
    method_option :files, :type => :array, :desc => 'One or more Argenta CSV files to be merged and parsed. Specify a folder to merge all files within the folder.'
    def parse
      if options.has_key?('files') && options['files'].length > 0
        input = read_files(options['files'], options['header'])
      else
        input = STDIN.readlines
      end
      puts Parser.new.parse(input)
    end

    protected

    ##
    # Reads all files in the input param. If a directory is specified, it loads all of the *.csv files in it as well.
    #
    # @param files array One or more files or directories to read from
    # @param include_header boolean Whether to include the first line of the first file or not
    def read_files(files, include_header = true)
      merged_input = []
      first = true
      [*files].each do |file|
        file = File.realpath(file)
        if File.directory?(file)
          dir_files = Dir.glob(File.join(file, '*.csv'))
          lines = read_files(dir_files)
        else
          file_object = File.open(file)
          lines = file_object.readlines
          if first && include_header #do not remove the headers line if --header is true
            first = false
            lines.shift
          else
            #remove the first two lines
            2.times { lines.shift }
          end
          file_object.close
        end
        merged_input << lines
      end
      merged_input.flatten
    end

  end #class Argenta
end

Argenta::Argenta.start