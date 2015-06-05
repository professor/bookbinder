require_relative '../../../lib/bookbinder/app_fetcher'

module Bookbinder
  describe AppFetcher do
    describe 'retrieving apps' do
      let(:routes_to_search) { [['cfapps.io', 'docs']] }
      let(:cf_command_runner) { double 'cf_command_runner' }
      let(:eol_space) { ' ' }

      context 'with a space column in the cf routes output' do
        let(:subject) { AppFetcher.new(routes_to_search, cf_command_runner) }
        it 'returns the correct app' do
          allow(cf_command_runner).to receive(:cf_routes_output).and_return(<<OUTPUT)
Getting routes as cfaccounts+cfdocs@pivotallabs.com ...

space       host                    domain                apps
my-space    no-cat-pictures         cfapps.io
my-space    less-cat-pictures       cfapps.io             cats #{eol_space}
my-space    cat-pictures            cfapps.io             cats #{eol_space}
my-space    docsmisleading          cfapps.io
my-space    docs                    cfapps.io             docs-green #{eol_space}
my-space    docs-testmisleading     cfapps.io
my-space    docs-test               cfapps.io             docs-green,docs-blue #{eol_space}
my-space    more-cat-pictures       cfapps.io             many-cats, too-many-cats #{eol_space}
OUTPUT
          expect(subject.fetch_current_app).to eq(BlueGreenApp.new('docs-green'))
        end
      end

      context 'without a space column in the cf routes output' do
        xit 'returns the correct app' do
          expect(subject.fetch_current_app).to eq(BlueGreenApp.new('docs-green'))
        end
      end

      context 'when there are no apps' do
        let(:subject) { AppFetcher.new(routes_to_search, cf_command_runner) }
        it 'returns nil' do
          allow(cf_command_runner).to receive(:cf_routes_output).and_return(<<OUTPUT)
  Getting routes as cfaccounts+cfdocs@pivotallabs.com ...

space         host                    domain                apps
cool-space    docs                    cfapps.io             #{eol_space}
OUTPUT
          expect(subject.fetch_current_app).to be_nil
        end
      end

      context 'when the host is not found' do
        let(:subject) { AppFetcher.new(routes_to_search, cf_command_runner) }
        it 'returns nil' do
          allow(cf_command_runner).to receive(:cf_routes_output).and_return(<<OUTPUT)
  Getting routes as cfaccounts+cfdocs@pivotallabs.com ...

space           host                    domain                apps
cool-space      foo                     cfapps.io             fantastic-app #{eol_space}
OUTPUT
          expect(subject.fetch_current_app).to be_nil
        end
      end

      context "when there are spaces in between app names" do
        let(:subject) { AppFetcher.new(routes_to_search, cf_command_runner) }
        let(:routes_to_search) { [['cfapps.io', 'more-cat-pictures']] }

        it "returns app names with stripped spaces" do
          allow(cf_command_runner).to receive(:cf_routes_output).and_return(<<OUTPUT)
Getting routes as cfaccounts+cfdocs@pivotallabs.com ...

space       host                    domain                apps
my-space    more-cat-pictures       cfapps.io             many-cats, too-many-cats #{eol_space}
OUTPUT
          expect(subject.fetch_current_app).to eq(BlueGreenApp.new('many-cats'))
        end
      end

      context 'when a route in the creds is not yet mapped in the app' do
        let(:subject) { AppFetcher.new(routes_to_search, cf_command_runner) }
        let(:config_hash) do
          {
              'staging_host' => {
                  'cfapps.io' => %w(docs docs-test docs-new-route)
              }
          }
        end

        it "returns the apps for the mapped routes" do
          allow(cf_command_runner).to receive(:cf_routes_output).and_return(<<OUTPUT)
Getting routes as cfaccounts+cfdocs@pivotallabs.com ...

space       host                    domain                apps
my-space    docs                    cfapps.io             docs-green #{eol_space}
my-space    docs-test               cfapps.io             docs-green,docs-blue #{eol_space}
OUTPUT
          expect(subject.fetch_current_app).to eq(BlueGreenApp.new('docs-green'))
        end
      end
    end
  end
end
