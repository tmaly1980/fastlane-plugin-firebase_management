module Fastlane
	module Firebase
		class Manager

			def login(jsonPath)
				begin 
					#Api instance
					@api = Firebase::Api.new(jsonPath)
					@api
				rescue StandardError => e
					UI.crash! e
				end
			end

			def select_project(project_id)

				projects = @api.project_list()
				
				if projects.count == 0 then
					UI.user_error! "No projects exist under the account"
					return
				end

				if project = projects.select {|p| p["projectId"] == project_id }.first then
					project
				else 
					options = projects.map { |p| "#{p["displayName"]} (#{p["projectId"]})" }
					index = select_index("Select project:", options)
					projects[index]
				end
			end

			def select_app(project_id, app_id, type)

				case type
				when :ios
					apps = @api.ios_app_list(project_id)
				when :android
					apps = @api.android_app_list(project_id)
				end

				if apps.empty? then
					UI.user_error! "Project has no #{type} apps"
					return
				end

				apps = apps.sort {|left, right| left["appId"] <=> right["appId"] }

				if app = apps.select {|a| a["appId"] == app_id }.first then
					app
				else
					options = apps.map { |a| "#{a["displayName"] || a["bundleId"] || a["packageName"]} (#{a["appId"]})" }
					index = select_index("Select app:", options)
					apps[index]
				end
			end

			def select_index(text, options)
				selected = UI.select(text, options)
				return options.index(selected)
			end 
		end
	end
end 
