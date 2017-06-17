#!/usr/bin/env ruby


module SiteScan
  class Scan

    def self.default_source_file
      "#{File.dirname(__FILE__)}/sources.yaml"
    end


    def self.load_lib!
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
      SiteScan::Scan.load_lib!

      conf = (args.length > 0) ? SiteScan::Source.from_files(args) : SiteScan::Source.from_files([SiteScan::Scan.default_source_file])
      self.gather!(conf[:sources])
      SiteScan::Log.items(conf[:sources])
    end



    def gather!(sources)
      sources.each do |source|
        puts "Starting scan for #{source.attrs['title']}."

        # For testing only.
        # Also, is the result set even necessary?
        result_sets = SiteScan::HTML.get_nodes(
          SiteScan::HTML.fetch_file("ohs.html"),
          source.attrs['match_set']
        )
        puts "Got #{result_sets.length} result sets."

        want_all = (source.attrs.has_key?('wants') &&
                    (source.attrs['wants'].downcase == 'all'))

        result_sets.each do |set|
          nodes = SiteScan::HTML.get_nodes(set, source.attrs['match_item'])
          puts "Got #{nodes.length} nodes."
          nodes.each do |node|
            item = SiteScan::Item.new(node, source.attrs['item_attributes'])
            if (item.is_wanted?(want_all))
              source.items.push(item)
            end
          end
          puts "Matched #{source.items.length} items."
        end
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
