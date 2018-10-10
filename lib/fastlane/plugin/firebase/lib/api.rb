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

			require 'mechanize'
			require 'digest/sha1'
			require 'json'
			require 'cgi'

			require 'googleauth'
			require 'httparty'
			def initialize(jsonPath)
				@base_url = "https://firebase.googleapis.com"

				scope = 'https://www.googleapis.com/auth/firebase'

				authorizer = Google::Auth::ServiceAccountCredentials.make_creds(
					json_key_io: File.open('firebase-api-test-b515420aa5ab.json'),
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
							# TODO
							headers['Content-Type'] = 'application/json'
							page = @agent.post("#{@sdk_url}#{path}?key=#{@api_key}", parameters.to_json, headers.merge(@authorization_headers))
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
				UI.message "Retrieving project list"
				json = request_json("v1beta1/projects")
				projects = json["results"] || []
				UI.success "Found #{projects.count} projects"
				projects
			end

			def app_list(project_id)
				UI.message "Retrieving app list for project #{project_id}"
				json = request_json("v1beta1/projects/#{project_id}/iosApps")
				apps = json["apps"] || []
				UI.success "Found #{apps.count} apps"
				apps
			end			


			def add_client(project_number, type, bundle_id, app_name, ios_appstore_id )
				parameters = {
					"requestHeader" => { "clientVersion" => "FIREBASE" },
					"displayName" => app_name || ""
				}

				case type
					when :ios
						parameters["iosData"] = {
							"bundleId" => bundle_id,
							"iosAppStoreId" => ios_appstore_id || ""
						}
					when :android
						parameters["androidData"] = {
							"packageName" => bundle_id
						}
				end

				json = request_json("v1/projects/#{project_number}/clients", :post, parameters)
				if client = json["client"] then
					UI.success "Successfuly added client #{bundle_id}"
					client
				else
					UI.error "Client could not be added"
				end
			end

			def delete_client(project_number, client_id)
				json = request_json("v1/projects/#{project_number}/clients/#{client_id}", :delete)
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
				UI.message "Downloading config file"
				json = request_json("v1beta1/projects/#{project_id}/iosApps/#{app_id}/config")
				# returns 501 NOT IMPLEMENTED
				UI.success "Successfuly downloaded #{json["configFilename"]}"
				json
			end
		end
	end
end