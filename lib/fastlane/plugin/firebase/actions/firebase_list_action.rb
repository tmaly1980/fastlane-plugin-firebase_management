module Fastlane
	module Actions
		class FirebaseListAction < Action

			def self.run(params)
				manager = Firebase::Manager.new

				# login
				api = manager.login(params[:service_account_json_path])

				# download list of projects
				projects = api.project_list()

				# download list of apps for each project
				projects.map! { |project|
					project["apps"] = api.app_list(project["projectId"])
					project
				}

				# create formatted output
				projects.each_with_index { |p, i| 
					UI.message "#{i+1}. #{p["displayName"]} (#{p["projectId"]})" 
					apps = p["apps"] || []
					apps.sort {|left, right| left["appId"] <=> right["appId"] }.each_with_index { |app, j|
						UI.message "  - #{app["displayName"] || app["bundleId"]} (#{app["appId"]})" 
					}
				}

				return nil
			end

			def self.description
				"List all Firebase projects and their apps"
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
						optional: false
					)
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
