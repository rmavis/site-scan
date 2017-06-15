require 'net/http'
require 'uri'


module PetFinder
  class Scan

    def initialize(url = '')
      @url = url
    end

    attr_reader :url



    def fetch(url = self.url)
      return Net::HTTP.get(URI(url))
    end



    # match_str can be like 'class="animal-results"'
    def get_html_nodes(doc, match_str)
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

  end
end


p = PetFinder::Scan.new('https://www.oregonhumane.org/adopt/?type=cats')
# puts p.get_html_nodes(p.fetch, 'class="animal-results"')

f = File.new("ohs.html")
doc = f.read
result_sets = p.get_html_nodes(doc, 'class="animal-results"')
puts "Got #{result_sets.length} result sets"
result_sets.each { |set|
  items = p.get_html_nodes(set, 'class="result-item"')
  puts "Got #{items.length} items"
  # items.each { |item| puts "\n\n\nResult item:\n#{item}" }
  puts "\nItem 1:\n#{items[0]}\n"
  puts "\nItem 2:\n#{items[1]}\n"
}



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
