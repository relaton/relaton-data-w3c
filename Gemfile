# frozen_string_literal: true
source "https://rubygems.org"

# relaton is now a single unpublished gem in the relaton/relaton monorepo. Pull
# it from main (HTTPS so the crawler GH action can clone the public repo
# anonymously, without an SSH key). There is nothing to revert to: the gem is
# not published. main carries relaton/relaton#130 (merged 2026-08-28), so
# `Relaton::W3c::INDEXFILE` is `index-v2` and the crawl writes the v2 index that
# `derive_index_v1.rb` derives `index-v1` from.
gem "relaton", git: "https://github.com/relaton/relaton.git", branch: "main"

# TEMPORARY BRANCH PIN — pubid #339 is merged (2026-08-28) but not released.
#
# #339 renames the W3C slug attribute `code` to `number`, with NO alias.
# `number` is the key `Relaton::Index::Type` sorts and binary-searches
# `index-v2` on, so a pubid without the rename leaves it unset and every row of
# the index this repo publishes keys on "". That fails silently, with no error,
# and degrades the search to a linear scan over the whole index.
#
# The pin was on the PR branch `feat/w3c-index-number`. GitHub deleted that
# branch on merge, which broke `bundle lock` in CI. The latest release,
# 2.0.0.pre.alpha.9 (2026-08-17), predates the merge and does not carry the
# rename, so the pin has to stay a git pin. `main` is what relaton/relaton's own
# Gemfile pins for the same reason.
#
# This repository has to pin it itself. Bundler reads a git dependency's gemspec,
# never its Gemfile. relaton's own pubid pin therefore does not reach this
# bundle. `Gemfile.lock` is git-ignored, so CI resolves fresh on every crawl. It
# would otherwise take a released pubid from RubyGems.
#
# Verify with `bundle list | grep pubid` before trusting a generated index.
#
# TODO: revert to the released pubid once a release later than
# 2.0.0.pre.alpha.9 ships the rename.
gem "pubid", git: "https://github.com/metanorma/pubid.git", branch: "main"

group :development, :test do
  gem "rspec", "~> 3.13"
end
