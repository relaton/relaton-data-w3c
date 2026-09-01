# frozen_string_literal: true

# `W3cApi::Hal::DEFAULT_USER_AGENT` is read at load, not at request time, so the
# constant has to be in scope here. The require defines constants only: no
# connection is built and no request is made.
require "w3c_api/hal"

#
# Crawl policy for api.w3.org, applied by `crawler.rb` before the fetch.
#
# It lives in its own file rather than in `crawler.rb` so that a spec can load
# it. Requiring `crawler.rb` deletes `data/`.
#
# api.w3.org is fronted by Cloudflare, whose rate limiting is bimodal: a crawl
# either never trips it or trips it and stays banned. A ban is not recoverable
# here — `crawler.rb` wipes `data/` first, so `Relaton::W3c::DataFetcher` aborts
# rather than commit a half-crawled corpus as a mass deletion. Both knobs below
# therefore aim at not tripping the limiter in the first place, which is the
# only outcome that saves a run.
#
# Both are `relaton`'s own environment variables, and both are read per crawl.
# See run 33435903404, which lost a crawl to a ban 14 minutes in.
#
module ConfigureCrawl
  # W3C asks API consumers to identify themselves so it can tell traffic sources
  # apart and reach the operator instead of throttling silently. `w3c_api`
  # otherwise sends only its own name, which identifies the gem but not the
  # crawl that is running it. The gem default is kept as the suffix, which is
  # the pattern `W3cApi::Hal.configure_user_agent` documents.
  USER_AGENT = "relaton-data-w3c/crawler " \
               "(+https://github.com/relaton/relaton-data-w3c) " \
               "#{W3cApi::Hal::DEFAULT_USER_AGENT}".freeze

  # One worker fewer than `DEFAULT_CONCURRENCY`. Four is the top of the range
  # that has survived: of the crawls since the governor landed on 2026-08-20,
  # seven finished in ~1h30m with zero throttled responses and two were banned
  # outright. Three costs roughly half an hour of wall clock on a healthy run,
  # against a 6-hour Actions cap.
  CONCURRENCY = "3"

  # Defaults only. An operator who sets one of these — by hand, or through the
  # shared crawler workflow's `fetch-command`, which is spliced into a `run:`
  # block and so takes a shell assignment prefix — keeps their value.
  DEFAULTS = {
    W3cApi::Hal::USER_AGENT_ENV_VAR => USER_AGENT,
    "RELATON_W3C_FETCH_CONCURRENCY" => CONCURRENCY,
  }.freeze

  #
  # Fill in every unset knob, leaving the ones already set alone.
  #
  # @param env [#[], #[]=] the environment to configure; `ENV` in a real crawl.
  #
  # @return [#[], #[]=] the same environment, configured.
  #
  def self.apply(env = ENV)
    DEFAULTS.each do |name, value|
      # A blank value is the variable being unset — an empty shell assignment
      # prefix — not an operator asking for an empty User-Agent. `w3c_api`
      # reads a blank agent the same way.
      env[name] = value if env[name].to_s.strip.empty?
    end
    env
  end
end
