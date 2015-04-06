require './import'

RSpec.describe Importer do
  it "successfully imports the test file" do
    test_file = './doc/sample_donotcall/test.txt'
    Importer.import(test_file + '.zip')
    records_created = DoNotCallPhone.count
    records_in_file = `wc #{test_file}`.to_i
    expect(records_created).to eq(records_in_file)
  end
end
