module Fastlane
	module Actions
		class FirebaseAddClientAction < Action
			
			def self.run(params)
				manager = Firebase::Manager.new
				
				# Login
				api = manager.login(params[:service_account_json_path])

				#Select project
				project = manager.select_project(params[:project_id])

				# Client input
				type = params[:type].to_sym

				bundle_id = params[:bundle_id]
				display_name = params[:display_name]

				case type
				when :ios
					api.add_ios_app(project["projectId"], bundle_id, display_name)

					sleep 3

					apps = api.app_list(project["projectId"])

					app = apps.detect {|app| app["bundleId"] == bundle_id }

					if app != nil then
						UI.success "App created"
					else
						UI.crash! "Unable to create new app"
					end

				when :android
					UI.crash! "Not implemented"
				end

				if params[:download_config] then
					#Download config
					Actions::FirebaseDownloadConfigAction.run(
						service_account_json_path: params[:service_account_json_path],
						project_id: params[:project_id],
						app_id: app["appId"],
						output_path: params[:output_path]
					)
				end
			end

			def self.description
				"An unofficial tool to access Firebase"
			end

			def self.authors
				["Ackee, s.r.o."]
			end

			def self.return_value
				# If your method provides a return value, you can describe here what it does
			end

			def self.details
				# Optional:
				"Firebase helps you list your projects, create applications, download configuration files and more..."
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
