#!/usr/bin/env ruby

=begin
TODO
- Fix items marked @TODO
- Per-scan log dumps
- Other datasets
- Pagination
=end


# The Scan class runs the show. It receives the command line arguments
# and orchestrates the work.
module SiteScan
  class Scan

    # Alternative source file can be given as arguments. If none are
    # given, this is used.
    def self.default_source_file
      "#{File.dirname(__FILE__)}/sources.yaml"
    end


    def self.logs_dir
      "#{File.dirname(__FILE__)}/logs"
    end


    def self.vault_dir
      "#{self.logs_dir}/vault"
    end


    def self.dump_dir
      "#{self.logs_dir}/dump"
    end


    def self.load_lib!
      [
        'lib/alert.rb',
        'lib/html.rb',
        'lib/item.rb',
        'lib/source.rb',
        'lib/vault.rb',
      ].each do |file|
        require_relative file
      end
    end



    # Start a new Scan with an array of command line arguments. None
    # are necessary, but if given they will be assumed to be paths to
    # source files.
    def initialize(args = [ ])
      SiteScan::Scan.load_lib!

      conf = (args.length > 0) ? SiteScan::Source.from_files(args) : SiteScan::Source.from_files([SiteScan::Scan.default_source_file])
      self.get_items!(conf[:sources])
      n = self.get_new_items!(conf[:sources])
      if (n > 0)
        # Uncomment this after testing.  @TODO
        # self.log_new_items!(conf[:sources])
        digest = self.build_digest(conf[:sources])
        # puts digest
        if (!conf[:email].nil?)
          SiteScan::Alert.new(digest, conf[:email])
        end
      end
    end


    # get_items! receives an array of Source objects. For each, it
    # will pull and cull the wanted Items and set that array to the
    # Source's `items` property.
    def get_items!(sources)
      sources.each do |source|
        puts "Starting scan for #{source.attrs['title']}."

        # For testing only.  @TODO
        # Also, is the result set even necessary?
        # result_sets = SiteScan::HTML.get_nodes(
        #   SiteScan::HTML.fetch_file("ohs.html"),
        #   source.attrs['match_set']
        # )
        result_sets = SiteScan::HTML.get_nodes(
          SiteScan::HTML.fetch_url(source.attrs['url']),
          source.attrs['match_set']
        )
        puts "Got #{result_sets.length} result sets."

        want_all = ((source.attrs.has_key?('wants')) &&
                    (source.attrs['wants'].downcase == 'all'))

        result_sets.each do |set|
          nodes = SiteScan::HTML.get_nodes(set, source.attrs['match_item'])
          puts "Got #{nodes.length} nodes."
          nodes.each do |node|
            item = SiteScan::Item.new(source, node, source.attrs['item_attributes'])
            if (item.is_wanted?(want_all))
              source.items.push(item)
            end
          end
          puts "Matched #{source.items.length} items."
        end
      end
    end


    # get_new_items! receives an array of Source objects. For each,
    # it checks the `items` against the items in the Source's log
    # file and sets the source's `new_items` property to an array of
    # Items that haven't already been logged. It returns the number
    # of total new items.
    def get_new_items!(sources)
      count = 0

      sources.each do |source|
        source.new_items = SiteScan::Vault.cull_new_items(
          "#{SiteScan::Scan.vault_dir}/#{source.log_name}",
          source.items
        )
        count += source.new_items.length
        puts "Got #{source.new_items.length} new items for #{source.attrs['title']}."
      end

      return count
    end


    # log_new_items! receives an array of Source objects. For each,
    # it adds the `new_items` to the source's log file.
    def log_new_items!(sources)
      sources.each do |source|
        if (source.new_items.length > 0)
          puts "Logging #{source.new_items.length} new items for '#{source.attrs['title']}'."
          SiteScan::Vault.add_item_keys(
            "#{SiteScan::Scan.vault_dir}/#{source.log_name}",
            source.new_items
          )
        end
      end
    end


    # build_digest collects each Source's `digest` into one easily-
    # digestable message, perfect for emailing.
    def build_digest(sources)
      digests = sources.collect { |source| source.digest }
      return digests.join("\n")
    end

  end
end

# This runs it.
SiteScan::Scan.new(ARGV)
