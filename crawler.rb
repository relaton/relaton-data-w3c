# frozen_string_literal: true

require 'fileutils'

FileUtils.rm_rf('data')

t1 = Time.now
puts "Started at: #{t1}"

system("relaton fetch-data w3c-rdf")

t2 = Time.now
puts "Stopped at: #{t2}"
puts "Done in: #{(t2 - t1).round} sec."

system("git add index-w3c.yaml index-w3c.zip")