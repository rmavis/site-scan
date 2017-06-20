require 'net/http'
require 'uri'


module SiteScan
  class HTML

    def self.fetch_url(url)
      return Net::HTTP.get(URI(url))
    end


    def self.fetch_file(path)
      f = File.new(path, 'r')
      return f.read
    end


    # match_str can be like 'class="animal-results"'
    def self.get_nodes(doc, match_str)
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
end
