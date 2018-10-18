module Fastlane
	module Firebase
		class Api 
			class LoginError < StandardError 
			end

			class BadRequestError < StandardError
				attr_reader :code
				
				def initialize(msg, code)
					@code = code
					super(msg)
				end
			end

			require 'googleauth'
			require 'httparty'

			def initialize(jsonPath)
				@base_url = "https://firebase.googleapis.com"

				scope = 'https://www.googleapis.com/auth/firebase https://www.googleapis.com/auth/cloud-platform'

				authorizer = Google::Auth::ServiceAccountCredentials.make_creds(
					json_key_io: File.open(jsonPath),
					scope: scope
				)

				access_token = authorizer.fetch_access_token!["access_token"]
				@authorization_headers = {
					'Authorization' => 'Bearer ' + access_token
				}
			end

			def request_json(path, method = :get, parameters = Hash.new, headers = Hash.new)
				begin
					if method == :get then
						response = HTTParty.get("#{@base_url}/#{path}", headers: headers.merge(@authorization_headers), format: :plain)
					elsif method == :post then
						headers['Content-Type'] = 'application/json'
						response = HTTParty.post("#{@base_url}/#{path}", headers: headers.merge(@authorization_headers), body: parameters.to_json, format: :plain)
					elsif method == :delete then
						# TODO
						page = @agent.delete("#{@sdk_url}#{path}?key=#{@api_key}", parameters, headers.merge(@authorization_headers))
					end

					case response.code
						when 400...600
							UI.crash! response
						else
							JSON.parse(response)
					end

				rescue HTTParty::Error => e
					UI.crash! e.response.body
				rescue StandardError => e
					UI.crash! e
				end
			end

			def project_list
				UI.verbose "Retrieving project list"
				json = request_json("v1beta1/projects")
				projects = json["results"] || []
				UI.verbose "Found #{projects.count} projects"
				projects
			end

			def app_list(project_id)
				UI.verbose "Retrieving app list for project #{project_id}"
				json = request_json("v1beta1/projects/#{project_id}/iosApps")
				apps = json["apps"] || []
				UI.verbose "Found #{apps.count} apps"
				apps
			end

			def add_ios_app(project_id, bundle_id, app_name)
				parameters = {
					"bundleId" => bundle_id,
					"displayName" => app_name || ""
				}

				request_json("v1beta1/projects/#{project_id}/iosApps", :post, parameters)
			end

			def upload_certificate(project_number, client_id, type, certificate_value, certificate_password)
				
				prefix = type == :development ? "debug" : "prod"

				parameters = {
					"#{prefix}ApnsCertificate" => { 
						"certificateValue" => certificate_value,
						"apnsPassword" => certificate_password 
					}
				}

				json = request_json("v1/projects/#{project_number}/clients/#{client_id}:setApnsCertificate", :post, parameters)
			end

			def download_config_file(project_id, app_id)
				UI.verbose "Downloading config file"
				json = request_json("v1beta1/projects/#{project_id}/iosApps/#{app_id}/config")
				UI.verbose "Successfuly downloaded #{json["configFilename"]}"
				json
			end
		end
	end
end