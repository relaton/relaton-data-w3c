# frozen_string_literal: true

require 'fileutils'

FileUtils.rm_rf('data')

system("relaton fetch-data w3c-rdf")
system("git add index-w3c.yaml index-w3c.zip")
