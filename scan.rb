#!/usr/bin/env ruby


module SiteScan
  class Scan

    def self.default_source_file
      "#{File.dirname(__FILE__)}/sources.yaml"
    end


    def self.load_lib
      [
        'lib/alert.rb',
        'lib/html.rb',
        'lib/item.rb',
        'lib/source.rb',
      ].each do |file|
        require_relative file
      end
    end



    def initialize(args)
      SiteScan::Scan.load_lib

      conf = (args.length > 0) ? SiteScan::Source.from_files(args) : SiteScan::Source.from_files([SiteScan::Scan.default_source_file])
puts conf.to_s
      conf[:sources].each do |source|
        # puts source.to_s
        puts "Starting scan for #{source.title}."

        # For testing only.
        # Also, is the result set even necessary?
        result_sets = SiteScan::HTML.get_nodes(
          SiteScan::HTML.fetch_file("ohs.html"),
          source.match_set
        )
        puts "Got #{result_sets.length} result sets."

        result_sets.each { |set|
          items = SiteScan::HTML.get_nodes(set, source.match_item)
          puts "Got #{items.length} items."
          # items.each { |item| puts "\n\n\nResult item:\n#{item}" }
          # puts "\nItem 1:\n#{items[0]}\n"
          # puts "\nItem 2:\n#{items[1]}\n"
          # item = SiteScan::Item.new(items[0], source.item_attributes)
          # puts "Sample item:"
          # puts item.attrs.to_s
          items.each { |item|
            i = SiteScan::Item.new(item, source.item_attributes)
            if (i.is_wanted?((source.respond_to?(:wants) && (source.wants.downcase == 'all'))))
              puts "\nFound match:\n#{i.describe}"
            end
          }
        }

      end
    end

  end
end

# This runs it.
SiteScan::Scan.new(ARGV)




# Steps:
# X Fetch (via curl?) page data
#   Get a big string
# X Find result set (specify rules in site-specific conf?)
#   Find occurrence of results wrapper, start and end, get a chunk of the previous string
# X Parse result items (also in rules)
#   Separate that result string into chunks, into an array of objects?
# X Scan pertinent fields (maybe a schema specified per site?) for each result item
# - If a match is found, collect relevant information and send an email
#   Digest this per scan, one email per scan
# - Keep logs of unique matches
#   Only email unique matches
# - Other datasets
# - Pagination?
