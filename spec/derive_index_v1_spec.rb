# frozen_string_literal: true

require "tmpdir"

RSpec.describe IndexV1 do
  describe ".row_id" do
    # Each pair is an `index-v2` identifier and the `index-v1` row it has to
    # derive to. The expectations are lifted verbatim from the published
    # `index-v1.yaml`, so they pin the real published shape, not a guess.
    {
      # The ordinary shape: stage, slug, publication date.
      "W3C REC-xml-names-20091208" =>
        { code: "xml-names", stage: "REC", date: "20091208" },
      # No date at all.
      "W3C NOTE-authentform" => { code: "authentform", type: "NOTE" },
      # `TR` is a type v1 drops rather than records.
      "W3C TR-html401-19991224" => { code: "html401", date: "19991224" },

      # The divergent rows. pubid folds a `year` and a `/`-suffix into the slug;
      # v1 splits them out again. 44 rows of the corpus decompose differently
      # under the two, and these are what the round trip through `to_s` exists
      # to restore.
      "W3C css-2010" => { code: "css", year: "2010" },
      "W3C NOTE-css-2015-20151013" =>
        { code: "css", type: "NOTE", year: "2015", date: "20151013" },
      "W3C REC-CSS2-19980512/fonts" =>
        { code: "CSS2", stage: "REC", date: "19980512", suff: "fonts" },
      "W3C WCA-terms/01" => { code: "WCA-terms", suff: "01" },
      "W3C 9605-Indexing-Workshop/ReportOutcomes" =>
        { code: "9605-Indexing-Workshop", suff: "ReportOutcomes" },
      "W3C WD-DOM-19980416/requirements" =>
        { code: "DOM", stage: "WD", date: "19980416", suff: "requirements" },
    }.each do |reference, expected|
      it "derives #{expected} from #{reference}" do
        pubid = ::Pubid::W3c::Identifier.parse reference
        expect(described_class.row_id(pubid)).to eq expected
      end
    end
  end

  describe ".write" do
    around do |example|
      Dir.mktmpdir { |dir| Dir.chdir(dir) { example.run } }
    end

    # Pin the behaviour, not the installed relaton. Until relaton/relaton#130
    # merges, the installed `Relaton::W3c::INDEXFILE` is still `index-v1`, and
    # every example here would otherwise pass by taking the declining branch.
    before { stub_const "Relaton::W3c::INDEXFILE", "index-v2" }

    let(:rows) do
      { "W3C REC-xml-names-20091208" => "data/rec-xml-names-20091208.yaml",
        "W3C css-2010" => "data/css-2010.yaml" }
    end

    def write_index_v2
      index = Relaton::Index.find_or_create(
        :W3C, file: "index-v2.yaml", pubid_class: ::Pubid::W3c::Identifier
      )
      rows.each do |reference, file|
        index.add_or_update ::Pubid::W3c::Identifier.parse(reference), file
      end
      index.save
      # Deliberately left pooled and open, the way `crawler.rb` leaves the
      # fetcher's Type. `.write` has to reach the saved file past it.
    end

    it "derives index-v1.yaml from the index-v2 the fetcher wrote" do
      write_index_v2

      expect(described_class.write).to eq 2
      expect(YAML.unsafe_load_file("index-v1.yaml")).to contain_exactly(
        { id: { code: "xml-names", stage: "REC", date: "20091208" },
          file: "data/rec-xml-names-20091208.yaml" },
        { id: { code: "css", year: "2010" }, file: "data/css-2010.yaml" },
      )
    end

    # The path `crawler.rb` actually takes. The fetcher's `:W3C` Type is still
    # pooled, holding rows that were never saved, and `Relaton::Index` reuses a
    # Type on a matching file name alone. Deriving from that object instead of
    # the file would publish an `index-v1` that does not match the `index-v2`
    # beside it.
    it "derives from the saved file, not from a pooled in-memory index" do
      write_index_v2
      stale = Relaton::Index.find_or_create(
        :W3C, file: "index-v2.yaml", pubid_class: ::Pubid::W3c::Identifier
      )
      stale.remove_all
      stale.add_or_update ::Pubid::W3c::Identifier.parse("W3C NOTE-authentform"),
                          "data/note-authentform.yaml"

      expect(described_class.write).to eq 2
      expect(YAML.unsafe_load_file("index-v1.yaml").map { |r| r[:file] })
        .to contain_exactly("data/rec-xml-names-20091208.yaml",
                            "data/css-2010.yaml")
    end

    # v1 drops the `TR` type that v2 keeps, so two distinct v2 rows can derive
    # to one v1 row. `add_or_update` dedups on the id, so the second silently
    # replaces the first and a document becomes unreachable in v1.
    it "warns, and reports the real count, when two v2 rows collapse into one" do
      rows.replace("W3C TR-html401-19991224" => "data/tr-html401-19991224.yaml",
                   "W3C html401-19991224" => "data/html401-19991224.yaml")
      write_index_v2

      # The count is the contract: it reports what reached index-v1, not what
      # index-v2 held. `.write` also logs the shortfall through
      # `Relaton::Index::Util`, which resolves `warn` via `method_missing` and
      # so cannot be stubbed; that line is left unasserted deliberately.
      expect(described_class.write).to eq 1
      expect(YAML.unsafe_load_file("index-v1.yaml").size).to eq 1
    end

    # The guard. `crawler.rb` deletes the index files before every crawl, so a
    # derivation that ran anyway would `save` a Type that was never loaded —
    # writing `--- []` over the index every released relaton v2 consumer reads.
    it "declines, and writes nothing, when index-v2.yaml is absent" do
      expect(described_class.write).to be_nil
      expect(File).not_to exist("index-v1.yaml")
    end

    it "declines when the installed relaton still writes index-v1" do
      stub_const "Relaton::W3c::INDEXFILE", "index-v1"
      write_index_v2

      expect(described_class.write).to be_nil
      expect(File).not_to exist("index-v1.yaml")
    end

    it "declines when index-v2.yaml holds no rows" do
      File.write "index-v2.yaml", [].to_yaml

      expect(described_class.write).to be_nil
      expect(File).not_to exist("index-v1.yaml")
    end
  end
end
