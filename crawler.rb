# frozen_string_literal: true

# require 'fileutils'
require 'relaton_w3c'

FileUtils.rm_rf('data')
FileUtils.rm Dir.glob('index*')

RelatonW3c::DataFetcher.fetch
