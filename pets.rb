require 'net/http'
require 'uri'
require 'yaml'


module PetFinder

  class Scanner

    def self.fetch_url(url)
      return Net::HTTP.get(URI(url))
    end


    def self.fetch_file(path)
      f = File.new(path)
      return f.read
    end


    # match_str can be like 'class="animal-results"'
    def self.get_html_nodes(doc, match_str)
      # This will contain the matching nodes.
      nodes = [ ]
      # This pattern will match the node's open tag.
      node_match = Regexp.new("([A-Za-z]+) [^>]*#{match_str}[^>]*", true)
      # This will become a regexp containing the matching open tag.
      open_match = false
      # This will become a regexp containing the matching close tag.
      close_match = false
      # This will count the number of tags of the type that matches
      # the `match_str`. It will increment with open tags, decrement
      # with close tags, and the node will end when it reaches 0.
      open_nodes = 0
      # This will become the index marking the start of the node.
      node_start = nil
      # The current index.
      o = 0
      # Set here because it's also used in the inner loop.
      doc_end = doc.length

      while (o < doc_end)
        char = doc[o]
        # puts "Checking char '#{char}'"

        if (char == '<')
          # puts "Checking tag"

          tag_body = ''
          i = o
          while (o < doc_end)
            o += 1
            break if (doc[o] == '>')
          end
          tag_body = doc[i..o]
          # puts "Tag body: #{tag_body}"

          if (!node_start.nil?)
            if (m = tag_body.match(open_match))
              # puts "Incrementing open nodes (#{open_nodes})"
              open_nodes += 1
            elsif (m = tag_body.match(close_match))
              # puts "Decrementing open nodes (#{open_nodes})"
              open_nodes -= 1
              if (open_nodes == 0)
                # puts "Pushing node and clearing body"
                nodes.push(doc[node_start..o])
                node_start = nil
              end
            end
          elsif (m = tag_body.match(node_match))
            # puts "Found matching node"
            open_match = Regexp.new("^<#{m[1]}[^>]*", true)
            close_match = Regexp.new("^</#{m[1]}[^>]*", true)
            node_start = i
            open_nodes += 1
          end

          tag_body = nil
        end
        # puts "Next"

        o += 1
      end

      return nodes
    end

    # But what if the HTML is not well-formed?
    # if (open_nodes < 0)
    #   puts "HTML appears not to be well-formed (#{open_nodes} : #{tag_chars.join})"
    #   puts body_chars.join
    #   exit
    # end


    def self.get_value(doc, match_str)
      re = Regexp.new(match_str, Regexp::IGNORECASE | Regexp::MULTILINE)
      if (m = doc.match(re))
        return m[1]
      end
      return nil
    end

  end





  class Item

    def initialize(node, attr_matches)
      @attrs = scan_attrs(node, attr_matches)
    end

    attr_accessor :attrs


    private

    def scan_attrs(node, attr_matches)
      attrs = { }
      attr_matches.each do |attr|
        attr.each_pair do |key,val|
          attrs[key] = PetFinder::Scanner.get_value(node, val)
        end
      end
      return attrs
    end

  end

end


yaml_file = File.new('sources.yaml')
yaml_body = yaml_file.read
sources = YAML.load(yaml_body)
sources.each do |source|
  # puts source.to_s
  puts "Starting scan for #{source['title']}."

  # For testing only.
  # Also, is the result set even necessary?
  result_sets = PetFinder::Scanner.get_html_nodes(
    PetFinder::Scanner.fetch_file("ohs.html"),
    source['match_set']
  )
  puts "Got #{result_sets.length} result sets."

  result_sets.each { |set|
    items = PetFinder::Scanner.get_html_nodes(set, source['match_item'])
    puts "Got #{items.length} items."
    # items.each { |item| puts "\n\n\nResult item:\n#{item}" }
    # puts "\nItem 1:\n#{items[0]}\n"
    # puts "\nItem 2:\n#{items[1]}\n"
    item = PetFinder::Item.new(items[0], source['item_attributes'])
    puts "Sample item:"
    puts item.attrs.to_s
  }

end




# Steps:
# X Fetch (via curl?) page data
#   Get a big string
# X Find result set (specify rules in site-specific conf?)
#   Find occurrence of results wrapper, start and end, get a chunk of the previous string
# - Parse result items (also in rules)
#   Separate that result string into chunks, into an array of objects?
# - Scan pertinent fields (maybe a schema specified per site?) for each result item
# - If a match is found, collect relevant information and send an email
#   Digest this per scan, one email per scan
