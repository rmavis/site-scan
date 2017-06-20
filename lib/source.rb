require 'yaml'


module SiteScan
  class Source

    def self.required_keys
      [
        'title',
        'url',
        'match_set',
        'match_item',
        'item_attributes',
      ]
    end



    def self.valid_keys
      self.required_keys + [
        'wants',
        'email',
      ]
    end



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



    def self.from_files(files)
      email = nil
      hashes = [ ]
      sources = [ ]

      files.each do |file|
        yaml_file = File.new(file)
        YAML.load(yaml_file.read).each do |item|
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



    def log_name
      return self.attrs['title'].gsub(/[^-A-Z0-9a-z_]/, '')
    end

  end
end
