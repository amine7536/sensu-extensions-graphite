require File.join(File.dirname(__FILE__), "helpers")
require "sensu/extensions/graphite"

describe "Sensu::Extension::Graphite" do
  include Helpers

  before do
    @extension = Sensu::Extension::Graphite.new
  end

  it "can run" do
    async_wrapper do
      @extension.safe_run(event_template) do |output, status|
        expect(output).to eq("template")
        expect(status).to eq(0)
        async_done
      end
    end
  end
end
