#!/usr/bin/env ruby

# Test script to create an SMS and see if callbacks are triggered
require_relative 'config/environment'

puts "Creating SMS record..."
sms = Sms.create!(
  phone: '+12064517216',
  body: 'Test message from script',
  direction: 'incoming'
)

puts "SMS created with ID: #{sms.id}"
puts "Phone: #{sms.phone}"
puts "Body: #{sms.body}"
puts "Direction: #{sms.direction}"

# Check if the record was actually created
found_sms = Sms.find(sms.id)
puts "Found SMS in database: #{found_sms.inspect}" 