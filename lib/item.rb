require 'digest'
require 'uri'


# An Item contains values pulled from an HTML node. In the source
# YAML file, each item under the `item_attributes` hash contains a
# key and a match string used for pulling the value from that node.
# An Item's `attrs` map to that source hash.
module SiteScan
  class Item

    # Create a new Item with:
    # - the Source it it belongs to
    # - the HTML node (string) to pull the information from
    # - the parsed `item_attributes` hash from the source file,
    #   which will contain both rules for pulling the desired values
    #   from the node and "want" rules for filtering out unwanted items.
    def initialize(source, node, attr_rules)
      @attrs = scan_attrs(node, attr_rules)
      @source = source
    end

    attr_reader :attrs, :source


    # is_wanted? checks if the Item is wanted. This is determined by
    # scanning its attributes. If an attribute has :want rules, those
    # will be checked against its :value. The function's parameter
    # specifies whether the item should match loosely (meaning it's
    # wanted if any of the values match the want rules) or strictly
    # (every attribute must match). If multiple :want values are given
    # on a single attribute, then the :value only needs to match one
    # of them to be considered wanted.
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


    # describe returns a string describing the Item. The component
    # strings will be joined by the given `conj` string.
    def describe(conj = "\n")
      parts = [ ]

      self.attrs.each do |attr|
        if (attr[:title].downcase == 'link')
          if (attr[:value][0] == '/')
            uri = URI.parse(self.source.attrs['url'])
            parts.push("#{attr[:title]}: #{uri.scheme}://#{uri.host}#{attr[:value]}")
          else
            parts.push("#{attr[:title]}: #{attr[:value]}")
          end
        else
          parts.push("#{attr[:title]}: #{attr[:value]}")
        end
      end

      return parts.join(conj)
    end


    # hash returns an MD5 hash of the Item. This can be used as an
    # ID for the item in the Vault, etc.
    def hash
      return Digest::MD5.hexdigest(self.describe(' '))
    end



    private

    # scan_attrs receives an HTML node (string) and a hash of
    # attribute rules. Each Attribute rule will contain:
    # - a key, which will become the attribute's `:title`
    # - a value, which must be a regex pattern containing one capture
    #   group. If the `node` matches this pattern, that capture will
    #   become this atribute's `:value`.
    # - "want" rules, which are optional, but if present must be an
    #   array of strings. These will be checked against the `:value`
    #   to determine if this Item is wanted.
    def scan_attrs(node, attr_rules)
      attrs = [ ]

      attr_rules.each do |rule|
        attr = {
          :want => nil
        }

        rule.each_pair do |key,val|
          # "want" is a reserved word used to specify desired values.
          if (key.downcase == 'want')
            attr[:want] = val
          else
            attr[:title] = key
            attr[:value] = SiteScan::HTML.get_value(node, val)
          end
        end

        attrs.push(attr)
      end

      return attrs
    end

  end
end
