require 'httparty'
require 'uri'
require 'json'

class MattermostApi
	include HTTParty
	attr_accessor :base_uri, :token
	
	format :json
	# debug_output $stdout

	def initialize(url, token)
		if !url.nil?
			unless url.end_with? '/'
				url = url + '/'
			end

			unless url_valid?(url)
				raise "URL #{url} is invalid"
			end
		else
			raise 'MattermostAPI: URL is required'
		end

		if token.nil?
			raise 'MattermostAPI: Could not set auth token.'
		end

		self.base_uri = url + 'api/v4/'
		self.token = token
	end

	def get_current_user
		get_url('users/me')
	end

	def current_user_id
		user = self.get_current_user
		return user['id']
	end

	def get_emoji_by_name(emoji_name)
		get_url("emoji/name/#{emoji_name}")
	end	

	def create_custom_emoji(emoji_name, file_path)
		options = self.options

		options[:multipart] = true

		options[:headers] = { 'Authorization' => "Bearer #{self.token}"}

		options[:body] = {
				image: File.open(file_path),
				emoji: {
					name: emoji_name,
					creator_id: self.current_user_id
				}.to_json
			}

		response = self.class.post(self.base_uri + 'emoji', options)

		if response.code >= 200 && response.code <=300
			return JSON.parse(response.to_s)
		else
			pp response
			return nil	
		end

		
	end

	private

	def url_valid?(url)
		url = URI.parse(url) rescue false
	end

	def get_url(request_url, query=nil)
		options = self.options
		
		unless query.nil?
			options[:query] = query
		end

		response = self.class.get("#{self.base_uri}#{request_url}", options)

		if response.code >= 200 && response.code <= 300 # Successful
			JSON.parse(response.to_s)	
		else
			return nil
		end		
	end

	def post_data(request_url, payload)
		options = self.options
		
		unless payload.nil? 
			options[:body] = payload.to_json
		end
		
		response = self.class.post("#{self.base_uri}#{request_url}", options)

		if response.code >= 200 && response.code <= 300 # Successful
			return JSON.parse(response.to_s)	
		else
			puts "Mattermost API error #{response.code}: #{response.to_s}"
			return nil
		end
	end

	def put_data(request_url, payload)
		options = self.options
		options[:body] = payload.to_json

		self.class.put("#{self.base_uri}#{request_url}", options)
	end

	def options
		{
			headers: {
				'Content-Type' => 'application/json',
				'Authorization' => "Bearer #{self.token}"
			},
			body: nil,
			query: nil,
			verify: true
		}
	end
end