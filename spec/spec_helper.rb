# frozen_string_literal: true

require_relative "../derive_index_v1"
# The crawl policy lives beside it, so a spec can load it. `crawler.rb`
# itself cannot be required: it deletes `data/` on load.
require_relative "../configure_crawl"

RSpec.configure do |config|
  config.expect_with(:rspec) { |c| c.syntax = :expect }
  config.disable_monkey_patching!
  config.order = :random

  # `Relaton::Index` keeps its Types in a process-wide pool, and reuse is keyed
  # on `file` alone. Examples that write an index in a temporary directory would
  # otherwise hand a stale Type — holding rows and a path from a directory that
  # no longer exists — to the next example.
  config.after do
    Relaton::Index.close :W3C
    Relaton::Index.close :W3C_V1
  end
end
