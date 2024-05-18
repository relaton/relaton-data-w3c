# frozen_string_literal: true

require 'fileutils'
require 'relaton_w3c'

FileUtils.rm_rf('data')
FileUtils.rm Dir.glob('index*')

system("git clone --depth=1 https://github.com/relaton/w3c-tr-archive w3c-tr-archive")

RelatonW3c::DataFetcher.fetch 'w3c-tr-archive'
RelatonW3c::DataFetcher.fetch 'w3c-rdf'
