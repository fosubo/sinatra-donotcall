require './app'
require 'highline/import'

module Importer
  def self.import(file_path)
    file_path = File.expand_path(file_path)
    directory = File.dirname file_path

    prepare_sql = <<SQL
    TRUNCATE TABLE do_not_call_phones;
    PREPARE insert_number (text) AS
      INSERT INTO do_not_call_phones (number)
      VALUES ($1)
    ;
SQL

    process_file(directory, file_path, prepare_sql)
  end
end

if __FILE__==$0
  file_path = ARGV[0]
  # DROPS EVERYTHING IN THE DATABASE AND INSERTS ALL RECORDS FROM SCRATCH
  # We do this because it is much faster to do it this way than checking for duplicates
  # on every insert
  confirm = ask("WARNING! This will drop the entire database and rebuild it from " \
                "scatch based on the contents of #{file_path}.\n" \
                "Are you SURE you want to do this? [y/n]"
                ) { |yn| yn.limit = 1, yn.validate = /[yn]/i }
  if !confirm.downcase == 'y'
    puts "Abort."
    exit
  else
    Importer.import(file_path)
  end
end
