# The Vault class facilitates reading and writing to log files. If
# a Scan is run often, the same Items might occur repeatedly, which
# could lead to much redundancy. The functions in this class allow
# for checking that redundancy so the receiver of the Alerts doesn't 
# receive too many.
module SiteScan
  class Vault

    # cull_new_items receives a file path and an array of Items. The
    # file path should name a log file, which will contain a list of
    # Item hashes (MD5 strings). The return will be an array of Items
    # that are not already logged in the file.
    def self.cull_new_items(file, items)
      if (File.exist?(file))
        hashes = { }
        items.each { |item| hashes[item.hash] = item }

        f = File.new(file, 'r')
        f.each do |line|
          hash = line.chomp
          if (hashes.has_key?(hash))
            hashes.delete(hash)
          end
        end
        f.close

        return hashes.values
      end

      return items
    end


    # add_item_keys receives a file path and an array of Items. The
    # MD5 hashes of the each Item will be appended to the file.
    def self.add_item_keys(file, items)
      f = File.new(file, 'a')
      items.each do |item|
        f.puts(item.hash)
      end
      f.close
    end

  end
end
