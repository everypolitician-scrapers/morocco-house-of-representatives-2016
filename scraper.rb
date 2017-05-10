#!/bin/env ruby
# encoding: utf-8
# frozen_string_literal: true

require 'csv'
require 'pry'
require 'scraped'
require 'scraperwiki'

# require 'open-uri/cached'
# OpenURI::Cache.cache_path = '.cache'
require 'scraped_page_archive/open-uri'

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

    party, party_id = row[5].match(/(.*?) \((.*?)\)/).captures

    data = {
      id:           row[0],
      name:         '%s %s' % [row[2], row[1]],
      sort_name:    '%s %s' % [row[1], row[2]],
      given_name:   row[2],
      family_name:  row[1],
      name__ar:     '%s %s' % [row[4], row[3]],
      party:        party,
      party_id:     party_id,
      party__ar:    row[6],
      constituency: row[7],
      province:     row[9],
      start_date:   date_from(row[15]),
      end_date:     date_from(row[16]),
    }

    (arabic[row[7]] ||= Set.new) << row[8]
    (arabic[row[9]] ||= Set.new) << row[10]

    if data[:constituency] == 'Jeunes'
      data[:constituency] = 'National'
      data[:legislative_membership_type] == 'Youth Representative'
    end

    if data[:constituency] == 'Femmes'
      data[:constituency] = 'National'
      data[:legislative_membership_type] == "Women's Representative"
      data[:gender] = 'female'
    end

    ScraperWiki.save_sqlite(%i[id start_date], data)
  end

  pp arabic.select { |_k, v| v.size > 1 }
end

ScraperWiki.sqliteexecute('DELETE FROM data') rescue nil
reprocess_csv('https://docs.google.com/spreadsheets/d/e/2PACX-1vS6XNnW4aIo9zjc_jNzufLziYsRsMF1Kx-YMStKVmBOOakJ_bP7InqVHbDK55_W2eRHhUx-jWO5Hmz-/pub?output=csv')
