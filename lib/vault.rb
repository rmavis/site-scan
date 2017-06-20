module SiteScan
  class Vault

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



    def self.add_item_keys(file, items)
      f = File.new(file, 'a')
      items.each do |item|
        f.puts(item.hash)
      end
      f.close
    end

  end
end
