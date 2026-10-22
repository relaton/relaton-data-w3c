# frozen_string_literal: true

require 'fileutils'
require 'relaton/w3c/data_fetcher'
require_relative 'configure_crawl'
require_relative 'derive_index_v1'

# The data tree is kept between crawls; fetch(prune: true) prunes
# stale files behind the 90% guard (relaton#328).
# Narrower than 'index*', which also matches the Ruby files next to it.
FileUtils.rm Dir.glob('index-v*.{yaml,zip}')

# Identify the crawl to api.w3.org and pace it, so Cloudflare does not ban a
# run that cannot be resumed. Defaults only; see configure_crawl.rb.
ConfigureCrawl.apply

Relaton::W3c::DataFetcher.fetch

# The fetcher writes only index-v2. Released relaton v2 consumers still read
# index-v1, so derive it here. `IndexV1.write` declines if the resolved relaton
# still writes index-v1 itself; see derive_index_v1.rb.
IndexV1.write
