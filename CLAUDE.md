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

The pinned relaton now writes v2, so the derivation is the path CI takes. Keep
the guard anyway. It stops a crawl that resolved a relaton without
relaton/relaton#130 from publishing `--- []` over `index-v1`.

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

## The crawl policy, and why it exists

`configure_crawl.rb` sets two environment defaults, and `crawler.rb` applies them
before the fetch:

| Variable | Default here | Fetcher default |
|---|---|---|
| `W3C_API_USER_AGENT` | names this repository, then the `w3c_api` default | the gem name alone |
| `RELATON_W3C_FETCH_CONCURRENCY` | `3` | `4` |

api.w3.org is fronted by Cloudflare, whose rate limiting is bimodal: a crawl
either never trips it or trips it and stays banned. A ban cannot be recovered
from here. `crawler.rb` wipes `data/` first, so `Relaton::W3c::DataFetcher`
aborts with `CrawlIncompleteError` rather than commit a half-crawled corpus as a
mass deletion. Both knobs therefore aim at not tripping the limiter at all,
which is the only outcome that saves a run. Run 33435903404 lost a crawl 14
minutes in; two of the nine real crawls since 2026-08-20 were banned.

Both are defaults, not overrides — an operator who sets either keeps their value,
and a blank value counts as unset. The shared crawler workflow splices
`fetch-command` into a `run:` block, so an override travels as a shell assignment
prefix.

The policy lives in its own file because `crawler.rb` cannot be required: loading
it deletes `data/`. `spec/configure_crawl_spec.rb` covers it.

Once a ban has started, the crawl's behaviour is `relaton`'s to fix, not this
repository's. Its worker pool keeps issuing requests after the governor gives
up, because `spawn_worker` checks `stopping?` only at `queue.pop`.

## `.github/workflows/crawler.yml` must stay byte-equal to its cimas template

`cimas.yml` maps this file to `support/cimas-config/gh-actions/data/crawler.yml`,
so anything hand-added here is wiped by the next `cimas sync` — silently, with
nothing red in CI. The repo's copy had gone stale and still carried `push` and
`pull_request` triggers, which the template had already dropped. A PR crawl
fetched the whole corpus for ~1h30m and threw it away, because the shared
workflow gates its push step on `github.event_name != 'pull_request'`.

To change the triggers, the `args` input or the `permissions:` grant, edit the
template in `relaton/support`, not this file. `relaton-data-itu` takes the other
route — cimas leaves its `crawler.yml` unmapped, so that repo hand-maintains one.
This repository does not need that, because the template already says what it
wants.

Dropping `pull_request` costs one thing worth knowing before you edit
`crawler.rb`: a PR run was the only non-mutating way to exercise a change to it.
A `workflow_dispatch` run commits and pushes the crawled corpus to the branch it
runs on.

## Commands

```sh
bundle install               # Gemfile.lock is git-ignored; CI resolves fresh
bundle exec rspec            # covers derive_index_v1.rb, configure_crawl.rb
bundle exec ruby crawler.rb  # the full crawl; CI runs this, not you
```

`build_index_v2.rb` rebuilds `index-v2.yaml` from `data/` with no network. It
produced the first published `index-v2`, before any crawl could.

## `Gemfile` pins

- **pubid → `main`** carries a `TODO` and a revert condition. pubid #339 renames
  the W3C slug attribute `code` to `number`, with no alias. `number` is the key
  `Relaton::Index` sorts and binary-searches `index-v2` on. Any pubid without
  the rename leaves it unset, so every row keys on `""` — silently, with no
  error. Verify with `bundle list | grep pubid` before trusting a generated
  index. #339 merged on 2026-08-28, but no release carries it yet
  (2.0.0.pre.alpha.9 predates the merge), so the git pin stays. Revert to the
  released pubid once a later release ships.
- **w3c_api** is declared but unpinned. `configure_crawl.rb` requires
  `w3c_api/hal` directly, so the gem is a direct dependency even though
  relaton also pulls it in. relaton's own `~> 0.3.3` constraint resolves it.
- **relaton → `main`** is permanent. relaton is unpublished, so there is no
  release to revert to. main carries relaton/relaton#130 (merged 2026-08-28), so
  the crawl writes `index-v2` and the derivation runs.

Do not pin a PR's own branch. The head branch can disappear when the PR merges —
metanorma/pubid#339 did. `bundle lock` then fails the whole crawl with
`Revision <branch> does not exist`, before any Ruby runs. Point the pin at
`main` instead.

Use `bundle update`, not `bundle install`, to refloat a git pin — an
already-locked git source does not move on its own.
