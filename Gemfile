# frozen_string_literal: true
source "https://rubygems.org"

# relaton is now a single unpublished gem in the relaton/relaton monorepo. Pull
# it from main (HTTPS so the crawler GH action can clone the public repo
# anonymously, without an SSH key).
gem "relaton", git: "https://github.com/relaton/relaton.git", branch: "main"

eval File.read("Gemfile.deploy"), nil, "Gemfile.deploy" # rubocop:disable Security/Eval
