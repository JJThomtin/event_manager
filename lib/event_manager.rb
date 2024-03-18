require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5,"0")[0..4]
end

def get_most_active_hour(registeration_hours)
  registeration_hours.max_by { |i| registeration_hours.count(i) }
end

def get_most_active_day(registeration_days)
  registeration_days.max_by { |i| registeration_days.count(i) }
end

def clean_date(date) 
  date_split = date.split("/")
  if date_split[0].length == 1
    date_split[0] = "0" + date_split[0]
  end
  if date_split[1].length == 1
    date_split[1] = "0" + date_split[1]
  end
  clean_date = date_split.join(" ")
  clean_date
end
def clean_phone_number(phone_number)
  if phone_number.length < 10 || phone_number.length > 11
    "Bad Number"
  elsif phone_number.length == 10
    phone_number
  elsif phone_number.length == 11
    if phone_number[0] == 1
      phone_number[1..-1]
    else
      "Bad Number"
    end
  end
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id,form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

puts 'EventManager initialized.'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter
registeration_hours = []
registeration_days = []
cvs_line_count = contents.count
puts cvs_line_count
contents.rewind
most_active_hour = -1
most_active_day = -1
contents.each_with_index do |row, index|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  phone_number = clean_phone_number(row[:homephone])
  puts "Number: #{phone_number}"
  date_and_time = row[:regdate].split(" ")
  time = Time.parse(date_and_time[1])
  registeration_hours.push(time.hour)
  clean_date = clean_date(date_and_time[0])
  date = Date.parse(clean_date)
  registeration_days.push(date.day)
  legislators = legislators_by_zipcode(zipcode)
  if index == cvs_line_count - 1
    most_active_hour = get_most_active_hour(registeration_hours)
    most_active_day = get_most_active_day(registeration_days)
  end
  form_letter = erb_template.result(binding)
  save_thank_you_letter(id,form_letter)
end

puts "Most active day: " + most_active_day
puts "Most active hour: " + most_active_hour
