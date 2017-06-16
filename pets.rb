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


    # `get_value` receives a node string and a match string. That
    # match string must be a regex pattern that contains one capture
    # group. If the node contains the match, then the captured value
    # will be returned, else nil.
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

    attr_reader :attrs


    def is_wanted?(match_all = false)
      # puts "Checking if item is wanted."
      wants_count = 0
      match_count = 0

      self.attrs.each do |attr|
        if (!attr[:want].nil?)
          # puts "Want value(s) specified on #{attr[:title]} (#{attr[:value]}): #{attr[:want]}"
          wants_count += 1

          attr[:want].each do |want_val|
            # If the value is quoted, match it exactly.
            if ((want_val[0] == '"') ||
                (want_val[0] == "'"))
              quote = want_val[0]
              if (want_val[(want_val.length - 1)] == quote)
                # puts "Value #{want_val} is quoted."
                if (attr[:value].downcase == want_val[1..(want_val.length - 2)].downcase)
                  # puts "Matches."
                  match_count += 1
                else
                  # puts "Doesn't match."
                end
              elsif (attr[:value].downcase.include?(want_val.downcase))
                # puts "Matches (loose / 1)."
                match_count += 1
              else
                # puts "Doesn't match."
              end
            elsif (attr[:value].downcase.include?(want_val.downcase))
              # puts "Matches (loose / 2)."
              match_count += 1
            end
          end
        end
      end

      # puts "Wanted? #{wants_count} & #{match_count}"
      if match_all
        return (wants_count == match_count)
      else
        return ((wants_count == 0) || (match_count > 0))
      end
    end


    def describe
      parts = [ ]

      self.attrs.each do |attr|
        parts.push("#{attr[:title]}: #{attr[:value]}")
      end

      return parts.join("\n")
    end



    private

    def scan_attrs(node, attr_matches)
      attrs = [ ]

      attr_matches.each do |rule|
        attr = {
          :want => nil
        }

        rule.each_pair do |key,val|
          # "want" is a reserved word used to specify desired values.
          if (key.downcase == 'want')
            attr[:want] = val
          else
            attr[:title] = key
            attr[:value] = PetFinder::Scanner.get_value(node, val)
          end
        end

        attrs.push(attr)
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
    # item = PetFinder::Item.new(items[0], source['item_attributes'])
    # puts "Sample item:"
    # puts item.attrs.to_s
    items.each { |item|
      i = PetFinder::Item.new(item, source['item_attributes'])
      if (i.is_wanted?((source.has_key?('wants') && (source['wants'].downcase == 'all'))))
        puts "\nFound match:\n#{i.describe}"
      end
    }
  }

end




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
