# frozen_string_literal: true

require 'fileutils'

FileUtils.rm_rf('data')
FileUtils.rm Dir.glob('index-w3c.*')

system("git clone https://github.com/relaton/w3c-tr-archive w3c-tr-archive")
system("relaton fetch-data w3c-tr-archive")
system("relaton fetch-data w3c-rdf")
system("zip index-w3c.zip index-w3c.yaml")
system("git add index-w3c.yaml index-w3c.zip")
