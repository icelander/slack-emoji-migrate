#!/usr/bin/env ruby

require 'fileutils'
require 'slack-ruby-client'
require './lib/mattermost-api.rb'
require 'down'
require 'pp'

# Store the items in /output
if ! Dir.exist? './output'
	Dir.mkdir './output'
end

# Get the custom emoji from Slack
Slack.configure do |config|
  config.token = ENV['SLACK_API_TOKEN']
  raise 'Missing ENV[SLACK_API_TOKEN]!' unless config.token
end

client_options = {}

if ! ENV['SLACK_TIMEOUT'].nil? && ENV['SLACK_TIMEOUT'].to_i > 0
  	client_options[:timeout] = ENV['SLACK_TIMEOUT'].to_i
end

client = Slack::Web::Client.new(client_options)
client.auth_test

emoji_response = client.emoji_list
emoji_by_name = {}
aliases = {}

if emoji_response['ok']
	puts "Emoji response okay, processing emoji"
	emoji_response['emoji'].each do |emoji_name, url|
		# Slack has aliases for emoji
		# They look like alias:original_emoji_name
		# So if the url starts with 'alias:'

		if url.start_with? 'alias:'
			puts "#{emoji_name} is an alias #{url}"
			aliases[emoji_name] = url[6..]
		else
			puts "#{emoji_name} is a normal URL #{url}"
			emoji_by_name[emoji_name] = url
		end
	end

	# Now that we have the URLs, we can process the emoji aliases
	puts "Linking emoji aliases"
	aliases.each do |emoji_alias, emoji_name|
		if emoji_by_name.has_key? emoji_name
			puts "Adding #{emoji_alias} with url #{emoji_by_name[emoji_name]}"
			emoji_by_name[emoji_alias] = emoji_by_name[emoji_name]
		else
			puts "Could not find valid emoji for #{emoji_alias} - #{emoji_name}"
		end
	end
end

# Download them all
puts "Slack emoji processed. Downloading..."
emoji_by_name.each do |emoji_name, url|
	begin
		emoji_file = Down.download(url)
		extension = File.extname(emoji_file.original_filename)
		destination_filename = emoji_name + extension

		puts "Creating #{destination_filename}"
		FileUtils.copy(emoji_file.path, "./output/#{destination_filename}" )

		emoji_file.close
		emoji_file.unlink	
	rescue Down::ResponseError => e
		puts "Unable to download file for #{emoji_name}"
	rescue e
		puts "Encountered an error processing  #{e.to_s}"
	end
end

# Import into Mattermost
mmst_api = MattermostApi.new(ENV['MATTERMOST_URL'], ENV['MATTERMOST_TOKEN'])

Dir.foreach('./output') do |filename|
	next if filename == '.' or filename == '..'

	emoji_name = filename.split('.')[0]
	file_path = File.expand_path("./output/#{filename}")

	mmst_emoji = mmst_api.get_emoji_by_name(emoji_name)

	if mmst_emoji.nil?
		puts "Emoji #{emoji_name} does not exist in Mattermost, creating..."
		puts "Source File: #{file_path}"
		emoji = mmst_api.create_custom_emoji(emoji_name, file_path)
		if emoji.nil?
			puts "Error creating emoji"
		else
			puts "Emoji #{emoji['name']} created in Mattermost. ID: #{emoji['id']}"
		end
	else
		puts "Emoji #{emoji_name} exists. Skipping upload"
	end
end
