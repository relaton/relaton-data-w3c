# frozen_string_literal: true

# require 'fileutils'
require 'relaton/w3c/data_fetcher'

FileUtils.rm_rf('data')
FileUtils.rm Dir.glob('index*')

Relaton::W3c::DataFetcher.fetch
