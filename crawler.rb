# frozen_string_literal: true

require 'bundler/setup'
require 'fileutils'
require 'relaton-w3c'

FileUtils.rm_rf('data')
FileUtils.rm Dir.glob('index-w3c.*')

system("git clone https://github.com/relaton/w3c-tr-archive w3c-tr-archive")

RelatonW3c::DataFetcher.fetch 'w3c-tr-archive'
RelatonW3c::DataFetcher.fetch 'w3c-rdf'

system("zip index-w3c.zip index-w3c.yaml")
system("git add index-w3c.yaml index-w3c.zip")
