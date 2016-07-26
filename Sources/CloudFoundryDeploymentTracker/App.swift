/**
* Copyright IBM Corporation 2016
*
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
* http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
**/

import Foundation
import CloudFoundryEnv
import SwiftyJSON

public enum DeploymentTrackerError: ErrorProtocol {
  case UnavailableInfo(String)
}

public struct CloudFoundryDeploymentTracker {

  public static func track() throws {

	  let appEnv = try CloudFoundryEnv.getAppEnv()
	  print("The port: \(appEnv.port)")

	  var jsonEvent = JSON([:])
	  guard let vcapApplication = appEnv.getApp() else {
	  	throw DeploymentTrackerError.UnavailableInfo("Failed to get Cloud Foundry App instance.")
	  }

	  let dateFormatter = DateFormatter()
	  dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
	  print("THE date: \(dateFormatter.string(from: Date()))")
	  jsonEvent["date_sent"].stringValue = dateFormatter.string(from: Date())

	  jsonEvent["application_name"].stringValue = vcapApplication.name
	  jsonEvent["space_id"].stringValue = vcapApplication.spaceId
	  jsonEvent["application_version"].stringValue = vcapApplication.version
	  jsonEvent["application_uris"].arrayObject = vcapApplication.uris

	  let services = appEnv.getServices()
	  if services.count > 0 {
	  	
	  }

  }

}