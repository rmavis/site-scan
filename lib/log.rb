module SiteScan
  class Log

    def self.items(sources)

    end

  end
end


=begin
Three classes:
- Log, parent of:
- Vault, which is in charge of writing hashes of each item to a file, scanning those files for duplicates, etc, and
- Dump, which can just pass plaintext explanations of scans into files
Actually Log might not even be necessary.
=end
