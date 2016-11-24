#!/bin/env ruby
# encoding: utf-8
# frozen_string_literal: true

require 'csv'
require 'open-uri'
require 'pry'
require 'scraperwiki'

require 'open-uri/cached'
OpenURI::Cache.cache_path = '.cache'

class String
  def tidy
    gsub(/[[:space:]]+/, ' ').strip
  end
end

def date_from(str)
  return if str.to_s.empty?
  date = '%d-%02d-%02d' % str.split('/').reverse
  return if date == '2021-10-07'
  date
end

def reprocess_csv(file)
  arabic = {}

  raw = open(file).read.force_encoding('UTF-8')
  csv = CSV.parse(raw.lines.drop(2).join)
  csv.each do |row|
    next if row[0].to_s.empty?
    row = row.map(&:to_s).map(&:tidy)

    party, party_id = row[4].match(/(.*?) \((.*?)\)/).captures

    data = {
      name:         '%s %s' % [row[1].to_s.tidy, row[0].to_s.tidy],
      sort_name:    '%s %s' % [row[0].to_s.tidy, row[1].to_s.tidy],
      given_name:   row[1].to_s.tidy,
      family_name:  row[0].to_s.tidy,
      name__ar:     '%s %s' % [row[3].to_s, row[2].to_s],
      party:        party,
      party_id:     party_id,
      party__ar:    row[5],
      constituency: row[6],
      province:     row[8],
      start_date:   date_from(row[14]),
      end_date:     date_from(row[15]),
    }

    warn "*** #{row[6]} => #{row[7]} not #{arabic[row[6]]} " if arabic[row[6]] && arabic[row[6]] != row[7]
    arabic[row[6]] = row[7]

    warn "*** #{row[8]} => #{row[9]} not #{arabic[row[8]]}" if arabic[row[8]] && arabic[row[8]] != row[9]
    arabic[row[8]] = row[9]

    if data[:constituency] == 'Jeunes'
      data[:constituency] = 'National'
      data[:legislative_membership_type] == 'Youth Representative'
    end

    if data[:constituency] == 'Femmes'
      data[:constituency] = 'National'
      data[:legislative_membership_type] == "Women's Representative"
      data[:gender] = 'female'
    end

    # TODO: we need a better ID surrogate,
    # as there are multiple people with the same name
    ScraperWiki.save_sqlite(%i(name constituency), data)
  end
end

reprocess_csv('https://docs.google.com/spreadsheets/d/e/2PACX-1vS6XNnW4aIo9zjc_jNzufLziYsRsMF1Kx-YMStKVmBOOakJ_bP7InqVHbDK55_W2eRHhUx-jWO5Hmz-/pub?output=csv')
