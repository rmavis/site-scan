module SiteScan
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
            attr[:value] = SiteScan::HTML.get_value(node, val)
          end
        end

        attrs.push(attr)
      end

      return attrs
    end

  end
end
