require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'time'



def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def legislator_by_zipcode(zip)
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

def clean_phone_number(number)
  if number.length == 10 
    number
  elsif number.length == 11 
    number[1..10] if number[0] == '1'
  end
end

# Return the time with the most occurences
def peak_register_time (time_array)
  time_array.max_by { |time| time_array.count(time) }
end
puts 'event manager initialized'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

register_hours = []
register_wday = []
contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = row[:zipcode]
  phone_number = row[:homephone].gsub(/\D/, '')
  register_hours.push(Time.strptime(row[:regdate], '%D %H:%M').hour)
  register_wday.push(Time.strptime(row[:regdate], '%D %H:%M').wday)

  phone_number = clean_phone_number(phone_number)
  zipcode = clean_zipcode(zipcode)

  legislators = legislator_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)
  save_thank_you_letter(id, form_letter)

  # puts "#{name} #{register_wday}"
end

peak_hour = peak_register_time(register_hours)
peak_wday = peak_register_time(register_wday)
puts "the peak hour is #{peak_hour} and the peak weekday is #{peak_wday} Sunday being 0"
