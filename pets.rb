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
      nodes = [ ]

      # This pattern will match the node's open tag.
      node_match = Regexp.new("([A-Za-z]+) [^>]*#{match_str}[^>]*", true)
      # This will become a regexp containing the matching open tag.
      open_match = false
      # This will become a regexp containing the matching close tag.
      close_match = false

      open_nodes = 0
      body_chars = [ ]
      collecting = false

      o = 0
      doc_end = doc.length
      while o < doc_end
        char = doc[o]
        # puts "Checking char '#{char}'"

        if (char == '<')
          # puts "Checking tag"

          tag_chars = [char]
          i = o
          while i < doc_end
            i += 1
            tag_chars.push(doc[i])
            break if (doc[i] == '>')
          end
          o = i
          # puts "Tag body: #{tag_chars.join}"

          if collecting
            if (m = tag_chars.join.match(open_match))
              # puts "Incrementing open nodes (#{open_nodes})"
              open_nodes += 1
              body_chars += tag_chars
            elsif (m = tag_chars.join.match(close_match))
              # puts "Decrementing open nodes (#{open_nodes})"
              open_nodes -= 1
              # if (open_nodes < 0)
              #   puts "HTML appears not to be well-formed (#{open_nodes} : #{tag_chars.join})"
              #   puts body_chars.join
              #   exit
              # end
              if (open_nodes == 0)
                # puts "Pushing node and clearing body"
                nodes.push(body_chars.join)
                collecting = false
                body_chars.clear
              else
                body_chars += tag_chars
              end
            else
              body_chars += tag_chars
            end
          elsif (m = tag_chars.join.match(node_match))
            # puts "Found matching node"
            open_match = Regexp.new("^<#{m[1]}[^>]*", true)
            close_match = Regexp.new("^</#{m[1]}[^>]*", true)
            collecting = true
            open_nodes += 1
          end

          tag_chars = nil

        elsif collecting
          # puts "Collecting body character"
          body_chars.push(char)
        end
        # puts "Next"

        o += 1
      end

      return nodes
    end

  end
end


p = PetFinder::Scan.new('https://www.oregonhumane.org/adopt/?type=cats')
# puts p.get_html_nodes(p.fetch, 'class="animal-results"')

f = File.new("out")
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
