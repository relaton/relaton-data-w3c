# frozen_string_literal: true

# require 'fileutils'
require 'relaton_w3c'

FileUtils.rm_rf('data')
FileUtils.rm Dir.glob('index*')

# system("git clone https://github.com/relaton/w3c-tr-archive w3c-tr-archive")

RelatonW3c::DataFetcher.fetch # output: 'dir' # 'w3c-tr-archive'

system("git add archive.rdf")
