# relaton-data-w3c

A data repository. It holds one relaton YAML document per W3C publication in
`data/`, plus the index files that let a relaton client find them. There is no
library here — `crawler.rb` is the whole program, and CI runs it.

## Two index files

| File | Rows | Written by | Read by |
|---|---|---|---|
| `index-v2.yaml` / `.zip` | `Pubid::W3c::Identifier`, `_type: pubid:w3c:*` | `Relaton::W3c::DataFetcher` | relaton once the consumer half lands |
| `index-v1.yaml` / `.zip` | bespoke hash — `code`, `stage`, `type`, `year`, `date`, `suff` | `derive_index_v1.rb`, here | released relaton v2 clients |

`index-v1` is **derived, never crawled**. The fetcher upstream stopped writing
it. Released relaton v2 consumers still fetch `index-v1.zip` from this
repository, so this repository has to keep producing it, from the `index-v2`
the fetcher just wrote. `Relaton::W3c::PubId` is retained public upstream for
that one purpose, and `derive_index_v1.rb` is its only call site.

The two decompose a reference differently: `PubId` splits `year` from `date`
and keeps a `/`-suffix in `suff`, where pubid folds both into the slug. 44
rows of the corpus are affected. Rendering the pubid and re-parsing it restores
the v1 shape, because `PubId.parse` re-splits the rendered string.

`.zip` companions are built by `relaton/support`'s shared `crawler.yml`, which
zips any changed `index*.yaml` and commits both. Nothing here zips.

## `IndexV1.write` declines by design

`crawler.rb` deletes the index files before every crawl. An installed relaton
that still writes `index-v1` leaves no `index-v2.yaml` behind, and saving an
empty index would replace the published `index-v1.yaml` with `--- []`. So
`IndexV1.write` runs only when `Relaton::W3c::INDEXFILE` names `index-v2` *and*
a non-empty `index-v2.yaml` exists. `crawler.rb` is therefore correct against an
installed relaton that writes v2 and one that does not.

## The derivation reads the file, not the fetcher's index

`crawler.rb` fetches and derives in one process. `Relaton::Index` pools its
Types by name and file, and `Type#actual?` compares only `url` and `file` — so
`find_or_create(:W3C, file: "index-v2.yaml", ...)` after a crawl hands back the
very object the fetcher filled, `pubid_class:` and all. `IndexV1.write` closes
`:W3C` first and re-reads, so the two published files are derived from one
another rather than from a shared object in memory.

## Do not name a file `index*`

`crawler.rb` removes `index-v*.{yaml,zip}` before a crawl. The glob was `index*`,
which also matched the Ruby files beside it. Keep the Ruby files verb-named —
`derive_index_v1.rb`, `build_index_v2.rb` — and keep the glob narrow.

## Commands

```sh
bundle install               # Gemfile.lock is git-ignored; CI resolves fresh
bundle exec rspec            # covers derive_index_v1.rb
bundle exec ruby crawler.rb  # the full crawl; CI runs this, not you
```

`build_index_v2.rb` rebuilds `index-v2.yaml` from `data/` with no network. It
produced the first published `index-v2`, before any crawl could.

## Temporary pins in `Gemfile`

Both carry a `TODO` and a revert condition. Remove them when the condition is met.

- **pubid → `feat/w3c-index-number`** (pubid #339, open). Renames the W3C slug
  attribute `code` to `number`, with no alias. `number` is the key
  `Relaton::Index` sorts and binary-searches `index-v2` on. Any other pubid
  leaves it unset, so every row keys on `""` — silently, with no error.
  Verify with `bundle list | grep pubid` before trusting a generated index.
- **relaton → `main`** carries no `index-v2` support yet; that is
  relaton/relaton#130, still open. Until it merges the crawl still writes
  `index-v1` and the derivation stands down.

Use `bundle update`, not `bundle install`, to refloat a git pin — an
already-locked git source does not move on its own.
