require 'haml'
require 'json'
require 'sinatra'
require "./config/boot"

INSERT_RECORD_CHUNK_SIZE = 10_000
class DoNotCallPhone < ActiveRecord::Base
  self.primary_key = :number
end

# Hello! Welcome to the quickest, dirtiest little web app you have ever seen :)
# It may not be pretty but it works and it's fast.

get '/donotcall/:number' do
  number = params['number']
  if DoNotCallPhone.find_by(number: number)
    return [200, { number: number }.to_json ]
  else
    return [404, {}.to_json]
  end
end

get '/upload' do
  haml :upload_donotcall
end

# The same as upload_clobber but only inserts a number if it doesn't already exist
# This is much slower for large numbers of records
post '/upload' do
  return "Please select a file!" if !params['myfile']
  directory = UPLOAD_PATH
  write_to_file_name = directory + sanitize_filename(params['myfile'][:filename])
  File.open(write_to_file_name, "w") do |f|
    f.write(params['myfile'][:tempfile].read)
  end

  prepare_sql = <<SQL
PREPARE insert_number (text) AS
INSERT INTO do_not_call_phones (number)
SELECT $1
WHERE $1 NOT IN
(
  SELECT  number
  FROM    do_not_call_phones
)
;
SQL

  Thread.new do
    process_file(directory, write_to_file_name, prepare_sql)
  end
  return "The list is being processed!"
end

def process_file(directory, file_path, prepare_sql)
  start_time = Time.now
  `unzip -n -d #{Shellwords.escape(directory)} #{Shellwords.escape(file_path)}`
  unzipped = file_path.gsub(/\.zip/, '')

  DoNotCallPhone.connection.execute(prepare_sql)

  idx = 0
  inserted = 0
  total = `wc -w #{unzipped}`.match(/\d+/)[0]
  numbers = []
  File.open(unzipped, 'r') do |file|
    file.each_line do |line|
      idx += 1
      inserted += 1
      numbers << line.to_s.gsub(',', '')
      if idx == INSERT_RECORD_CHUNK_SIZE || file.eof?
        insert_numbers = numbers.reduce('') do |query, number|
          query + "EXECUTE insert_number(#{number}); "
        end
        DoNotCallPhone.connection.execute(insert_numbers)
        puts "Inserted #{idx} records (#{inserted}/#{total})"
        idx = 0
        numbers = []
      end
    end
  end
rescue => e
  puts "FAILED: #{e.inspect}"
else
  puts "SUCCESS! Inserted #{inserted}/#{total} records."
ensure
  puts "TIME ELAPSED: #{Time.now - start_time}s"
end

def sanitize_filename(filename)
  fn = filename.split /(?<=.)\.(?=[^.])(?!.*\.[^.])/m
  fn.map! { |s| s.gsub /[^a-z0-9\-]+/i, '_' }
  fn.join '.'
end
