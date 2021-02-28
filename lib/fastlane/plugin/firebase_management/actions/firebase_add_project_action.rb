require 'googleauth'
require 'google/apis/cloudresourcemanager_v1'

module Fastlane
	module Actions
		class FirebaseManagementAddProjectAction < Action
			
			def self.run(params)
				ENV['GOOGLE_APPLICATION_CREDENTIALS'] = params[:service_account_json_path]

				# CREATE GOOGLE CLOUD PROJECT
				service = Google::Apis::CloudresourcemanagerV1::CloudResourceManagerService.new

				service.authorization = Google::Auth.get_application_default(['https://www.googleapis.com/auth/cloud-platform'])

				response = service.get_project(params[:project_id])

				# TODO: Change code below to process the `response` object:
				puts "GOT="
				puts response.to_json

				#########

				# TODO: Assign values to desired members of `request_body`:
				request_body = Google::Apis::CloudresourcemanagerV1::Project.new

				request_body.project_id = params[:project_id]
				request_body.name = params[:display_name] if params[:display_name]
				request_body.parent = params[:parent] if params[:parent]

				puts "REQ="
				puts request_body.to_json

				response = service.create_project(request_body)

				# TODO: Change code below to process the `response` object:
				puts "GCP CREATE RESP="
				puts response.to_json

				exit
				
				
				###########################
				# NOW CREATE FIREBASE PROJECT (TODO)
				###########################

				manager = FirebaseManagement::Manager.new

				# login
				api = manager.login(params[:service_account_json_path], )

				# select project
				project_id = params[:project_id] || manager.select_project(nil)["projectId"]

				# select type
				type = params[:type].to_sym

				bundle_id = params[:bundle_id]

				display_name = params[:display_name]

puts "RUN ADD APP #{type}"
puts params.to_h

				case type
				when :ios
					# create new ios app on Firebase
					rt = api.add_ios_app(project_id, bundle_id, display_name)
puts "ADD RT="
puts rt

					# App creation is a long-running operation.
					# Creation endpoint returns operation ID which should be used to check
					# the result of the operation. This requires another Google API to be
					# enabled and other stuff to do so just wait for 3 seconds here, fetch
					# apps from Firebase and check whether the new app is there.
					sleep 3

					# download apps for project
					apps = api.ios_app_list(project_id)

					# search for newly created app
					app = apps.detect {|app| app["bundleId"] == bundle_id }

				when :android
					# create new android app on Firebase
					api.add_android_app(project_id, bundle_id, display_name)

					# see reason described above
					sleep 3

					# download apps for project
					apps = api.android_app_list(project_id)

					# search for newly created app
					app = apps.detect {|app| app["packageName"] == bundle_id }
				end

				# present result to user
				if app != nil then
					UI.success "New app with id: #{app["appId"]} successfully created"
				else
					UI.crash! "Unable to create new app"
				end

				if params[:download_config] then
					#Download config
					Actions::FirebaseManagementDownloadConfigAction.run(
						service_account_json_path: params[:service_account_json_path],
						project_id: project_id,
						app_id: app["appId"],
						type: type,
						output_path: params[:output_path]
					)
				end
			end

			def self.description
				"Add new app to Firebase project"
			end

			def self.authors
				["Ackee, s.r.o."]
			end

			def self.return_value
				# If your method provides a return value, you can describe here what it does
			end

			def self.details
				# Optional:
				"Firebase plugin helps you list your projects, create applications and download configuration files."
			end

			def self.available_options
				[
					FastlaneCore::ConfigItem.new(key: :service_account_json_path,
											env_name: "FIREBASE_SERVICE_ACCOUNT_JSON_PATH",
										 description: "Path to service account json key",
											optional: false),

					FastlaneCore::ConfigItem.new(key: :project_id,
											env_name: "FIREBASE_PROJECT_ID",
										 description: "Project id",
											optional: true),

					FastlaneCore::ConfigItem.new(key: :parent,
										 description: "Parent",
										   is_string: false,
											optional: true),

					FastlaneCore::ConfigItem.new(key: :download_config,
											env_name: "FIREBASE_DOWNLOAD_CONFIG",
										 description: "Should download config for created client",
											optional: false,
											is_string: false,
											default_value: false),

					FastlaneCore::ConfigItem.new(key: :type,
											env_name: "FIREBASE_TYPE",
										 description: "Type of client (ios, android)",
											verify_block: proc do |value|
												types = [:ios, :android]
												UI.user_error!("Type must be in #{types}") unless types.include?(value.to_sym)
											end
										 ),
					FastlaneCore::ConfigItem.new(key: :bundle_id,
											env_name: "FIREBASE_BUNDLE_ID",
										 description: "Bundle ID (package name)",
											optional: false),

					FastlaneCore::ConfigItem.new(key: :display_name,
											env_name: "FIREBASE_DISPLAY_NAME",
										 description: "Display name",
											optional: true),

					FastlaneCore::ConfigItem.new(key: :output_path,
					                        env_name: "FIREBASE_OUTPUT_PATH",
					                     description: "Path for the downloaded config",
					                        optional: false,
					                   default_value: "./"),

					FastlaneCore::ConfigItem.new(key: :output_name,
					                        env_name: "FIREBASE_OUTPUT_NAME",
					                     description: "Name of the downloaded file",
					                        optional: true)
				]	
			end

			def self.is_supported?(platform)
				# Adjust this if your plugin only works for a particular platform (iOS vs. Android, for example)
				# See: https://github.com/fastlane/fastlane/blob/master/fastlane/docs/Platforms.md
				#
				# [:ios, :mac, :android].include?(platform)
				true
			end
		end
	end
end
