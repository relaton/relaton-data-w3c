# frozen_string_literal: true

RSpec.describe ConfigureCrawl do
  # A Hash stands in for ENV. `apply` only reads with `[]` and writes Strings
  # with `[]=`, where the two agree, and a Hash keeps an example from leaking a
  # value into the rest of the suite.
  let(:env) { {} }

  describe ".apply" do
    it "returns the environment it configured" do
      expect(described_class.apply(env)).to be env
    end

    describe "W3C_API_USER_AGENT" do
      # Why this string, and why the suffix: see configure_crawl.rb.
      it "names this repository and a contact URL" do
        described_class.apply env

        expect(env["W3C_API_USER_AGENT"])
          .to start_with "relaton-data-w3c/crawler (+https://github.com/relaton/relaton-data-w3c)"
      end

      it "keeps the w3c_api default agent as the suffix" do
        described_class.apply env

        expect(env["W3C_API_USER_AGENT"]).to end_with W3cApi::Hal::DEFAULT_USER_AGENT
      end
    end

    describe "RELATON_W3C_FETCH_CONCURRENCY" do
      # One fewer than the fetcher's default; see configure_crawl.rb.
      it "lowers the worker count to 3" do
        described_class.apply env

        expect(env["RELATON_W3C_FETCH_CONCURRENCY"]).to eq "3"
      end
    end

    describe "an operator override" do
      it "leaves a User-Agent that is already set alone" do
        env["W3C_API_USER_AGENT"] = "acme-mirror/2.0 (+https://acme.example)"

        expect { described_class.apply env }
          .not_to change { env["W3C_API_USER_AGENT"] }
      end

      it "leaves a concurrency that is already set alone" do
        env["RELATON_W3C_FETCH_CONCURRENCY"] = "1"

        expect { described_class.apply env }
          .not_to change { env["RELATON_W3C_FETCH_CONCURRENCY"] }
      end

      # The shared crawler workflow splices `fetch-command` into a `run:` block,
      # so an override arrives as a shell assignment prefix. An empty one is the
      # variable being unset, not an operator asking for an empty User-Agent.
      it "treats a blank value as unset" do
        env["W3C_API_USER_AGENT"] = "   "
        env["RELATON_W3C_FETCH_CONCURRENCY"] = ""

        described_class.apply env

        expect(env["W3C_API_USER_AGENT"]).to end_with W3cApi::Hal::DEFAULT_USER_AGENT
        expect(env["RELATON_W3C_FETCH_CONCURRENCY"]).to eq "3"
      end
    end
  end
end
