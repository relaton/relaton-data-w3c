# frozen_string_literal: true
source "https://rubygems.org"

# relaton is now a single unpublished gem in the relaton/relaton monorepo. Pull
# it from main (HTTPS so the crawler GH action can clone the public repo
# anonymously, without an SSH key).
gem "relaton", git: "https://github.com/relaton/relaton.git", branch: "main"

# TEMPORARY BRANCH PIN — pubid #339, still open.
#
# The branch carries the updated W3C pubid flavor: it renames the slug
# attribute `code` to `number`, with NO alias. `number` is the key
# `Relaton::Index::Type` sorts and binary-searches `index-v2` on, so any other
# pubid — released, or git `main` — leaves it unset and every row of the index
# this repo publishes keys on "". That fails silently, with no error, and
# degrades the search to a linear scan over the whole index.
#
# This repository has to pin it itself. Bundler reads a git dependency's
# gemspec, never its Gemfile, so relaton's own pubid pin does not reach this
# bundle — and relaton `main` pins pubid `main`, which does not carry the
# rename either. `Gemfile.lock` is git-ignored, so CI resolves fresh on every
# crawl and would otherwise take a released pubid from RubyGems.
#
# TODO: revert to the released pubid once #339 merges and ships.
gem "pubid", git: "https://github.com/metanorma/pubid.git",
             branch: "feat/w3c-index-number"

group :development, :test do
  gem "rspec", "~> 3.13"
end
