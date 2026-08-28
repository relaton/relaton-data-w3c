#!/usr/bin/env ruby
# frozen_string_literal: true

#
# Build `index-v2.yaml` from the documents already in `data/`.
#
# This is NOT part of a crawl. `Relaton::W3c::DataFetcher` builds the index as
# it fetches; this script exists because the first `index-v2` had to be
# published before any crawl could produce one, so that relaton could write its
# consumer half against a real file.
#
# It is kept for the same reason a crawl can be repeated: `data/` is the source
# of truth, and this rebuilds the index from it with no network access. It reads
# each document's primary `docidentifier` — the same field
# `DataFetcher#index_primary` indexes — so its output is what a crawl produces.
#
# Usage:
#
#   bundle exec ruby build_index_v2.rb
#
# Then zip it, the way `relaton/support`'s crawler workflow does:
#
#   zip index-v2.zip index-v2.yaml
#

require "yaml"
require "pubid"
require "pubid/w3c"
require "relaton/index"

FILE = "index-v2.yaml"

index = Relaton::Index.find_or_create(
  :W3C, file: FILE, pubid_class: ::Pubid::W3c::Identifier
)
index.remove_all

files = Dir["data/*.yaml"].sort
errors = []

files.each do |file|
  doc = YAML.safe_load_file file, permitted_classes: [Date, Time]
  docid = (doc["docidentifier"] || []).find { |i| i["primary"] }

  unless docid
    errors << "#{file}: no primary docidentifier"
    next
  end

  begin
    index.add_or_update ::Pubid::W3c::Identifier.parse(docid["content"].to_s), file
  rescue StandardError => e
    errors << "#{file}: cannot parse `#{docid['content']}`: #{e.message}"
  end
end

rows = index.index.size
errors.each { |e| warn e }

# Check before writing. An identifier that does not parse leaves its document
# out of the index, and two documents whose identifiers render alike collapse
# into one row. Either way a document becomes unreachable by lookup, so fail
# without leaving a partial index on disk for someone to publish by mistake.
abort "#{errors.size} document(s) not indexed; #{FILE} not written" if errors.any?
if rows < files.size
  abort "#{files.size - rows} document(s) collapsed into another row; " \
        "#{FILE} not written"
end

index.save
puts "#{files.size} documents read, #{rows} rows written to #{FILE}"
