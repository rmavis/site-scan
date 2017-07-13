require 'yaml'


# A Source is an object representation of the source specified in a
# YAML file. A source contains information and rules and pulling
# and culling the wanted information, along with, e.g., a title (for
# the logs, etc). After pulling the information from the source's
# URL, a Source will also contain an areay of Items.
module SiteScan
  class Source

    # These keys contain a Source's minimum required information.
    def self.required_keys
      [
        'title',
        'url',
        'match_set',
        'match_item',
        'item_attributes',
      ]
    end


    # These keys are also allowed.
    def self.valid_keys
      self.required_keys + [
        'wants',
        'email',
      ]
    end


    # is_ok? receives a (source) hash and checks if it contains
    # the required/valid keys.
    def self.is_ok?(src)
      if (src.is_a?(Hash))
        valid_keys = self.valid_keys
        src.keys.each do |key|
          if (!valid_keys.include?(key))
            return false
          end
        end
        return true
      else
        return false
      end
    end


    # from_files receives an array of file paths and returns a hash:
    #   :sources, being an array of Source objects
    #   :email, being an email address or nil if not specified
    def self.from_files(files)
      sources = [ ]
      hashes = [ ]
      email = nil

      files.each do |file|
        yaml_file = File.new(file)
        YAML.load(yaml_file.read).each do |item|
          # If the YAML file contains a line like
          #   - email: what@ev.er
          # that will be used as the global receiver.
          if ((item.length == 1) &&
              (item.has_key?('email')))
            email = item['email']
          else
            hashes.push(item)
          end
        end
      end

      hashes.each do |src|
        sources.push(SiteScan::Source.new(src))
      end

      return {
        :sources => sources,
        :email => email
      }
    end



    def initialize(src = { }, items = [ ])
      if (SiteScan::Source.is_ok?(src))
        @attrs = src
        @items = items
        @new_items = [ ]
      else
        raise ArgumentError.new("Ill-formed source (#{src.to_s})")
      end
    end

    attr_accessor :attrs, :items, :new_items


    # This creates a string suitable for the name of the source's
    # log file.
    def log_name
      return self.attrs['title'].gsub(/[^-A-Z0-9a-z_]/, '')
    end


    # This creates a string describing the state of the source. This
    # will be called at the end of the scan and included in the log,
    # emailed, etc.
    def digest
      if (self.new_items.length == 0)
        return "There are 0 new items for #{self.attrs['title']}."
      end

      parts = [
        "There are #{self.new_items.length} new items for #{self.attrs['title']}:"
      ]

      self.new_items.each do |item|
        parts.push("\n#{item.describe}")
      end

      return parts.join("\n")
    end

  end
end
