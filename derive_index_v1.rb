# frozen_string_literal: true

require "pubid"
require "pubid/w3c"
require "relaton/index"
require "relaton/w3c"
require "relaton/w3c/pubid"

#
# The legacy `index-v1`, derived from the pubid-backed `index-v2`.
#
# `Relaton::W3c::DataFetcher` writes only `index-v2` now. Released relaton v2
# consumers — the published `relaton-w3c` gem, and any relaton older than the
# switch — still fetch `index-v1.zip` from this repository, so this repository
# has to keep producing it. `Relaton::W3c::PubId` is retained public upstream
# for exactly this purpose, and this is its only call site.
#
module IndexV1
  FILE = "index-v1.yaml"
  V2_FILE = "index-v2.yaml"

  # The value `Relaton::W3c::INDEXFILE` holds once the fetcher writes v2.
  V2_INDEXFILE = "index-v2"

  class << self
    #
    # Convert one `index-v2` identifier into its `index-v1` row id.
    #
    # `Relaton::W3c::PubId` and `Pubid::W3c` do not decompose a reference the
    # same way: `PubId` splits `year` from `date` and keeps a `/`-suffix in
    # `suff`, where pubid folds both into the slug. Rendering the pubid and
    # re-parsing it is what restores the v1 shape — `PubId.parse` re-splits the
    # rendered string. 41 of the 17,287 rows depend on this.
    #
    # `with_publisher: false` drops the leading `W3C `, which `PubId.parse`
    # does not expect.
    #
    # @param [Pubid::W3c::Identifier] pubid an `index-v2` row identifier
    #
    # @return [Hash] the `index-v1` row id
    #
    def row_id(pubid)
      Relaton::W3c::PubId.parse(pubid.to_s(with_publisher: false)).to_hash
    end

    #
    # Write `index-v1.yaml` from the `index-v2` the fetcher just wrote.
    #
    # Declines unless there is a real v2 index to derive from; see {.source}.
    #
    # @return [Integer, nil] rows written, or nil if it declined
    #
    def write
      rows = source or return nil

      index = Relaton::Index.find_or_create(:W3C_V1, file: FILE)
      # Build from scratch. `crawler.rb` deletes the index files before a crawl,
      # but a pooled Type outlives that, and `add_or_update` would otherwise
      # merge this crawl's rows into a previous crawl's.
      index.remove_all
      rows.each { |row| index.add_or_update row_id(row[:id]), row[:file] }
      index.save

      written = index.index.size
      if written < rows.size
        Relaton::Index::Util.warn "#{rows.size - written} of #{rows.size} " \
                                  "index-v2 rows collapsed into an existing " \
                                  "index-v1 row"
      end
      written
    end

    private

    #
    # The `index-v2` rows to derive from, or nil to decline.
    #
    # Deriving when the fetcher did not write a v2 index is destructive, not
    # merely useless: `crawler.rb` removes the index files before every crawl,
    # so an installed relaton that still writes `index-v1` leaves no
    # `index-v2.yaml` behind, and saving an empty index would replace the
    # published `index-v1.yaml` with `--- []`. Declining keeps `crawler.rb`
    # correct against both an installed relaton that writes v2 and one that
    # does not.
    #
    # @return [Array<Hash>, nil] `index-v2` rows, or nil
    #
    def source
      return nil unless Relaton::W3c::INDEXFILE == V2_INDEXFILE
      return nil unless File.exist?(V2_FILE)

      # Read the file, not the fetcher's in-memory index. `crawler.rb` fetches
      # and derives in one process, and `Relaton::Index` pools its Types by
      # name and file, so `find_or_create` would otherwise hand back the very
      # object the fetcher filled — deriving `index-v1` from rows that were
      # never compared against what `save` actually wrote. Closing it forces
      # the reload, so the two published files are derived from one another
      # rather than from a shared object, and every row goes through
      # `Relaton::Index`'s own deserialization checks on the way.
      Relaton::Index.close :W3C

      rows = Relaton::Index.find_or_create(
        :W3C, file: V2_FILE, pubid_class: ::Pubid::W3c::Identifier
      ).index
      rows.empty? ? nil : rows
    end
  end
end
