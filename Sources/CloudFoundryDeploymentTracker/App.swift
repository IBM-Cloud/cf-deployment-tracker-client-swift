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

  var appEnv: AppEnv?

  public init() {
    do {
      appEnv = try CloudFoundryEnv.getAppEnv()
    } catch {
      print("Couldn't get Cloud Foundry App environment instance.")
    }
  }

  public init(appEnv: AppEnv) {
    self.appEnv = appEnv
  }

  public func track() {

    if let appEnv = appEnv, trackerJson = buildTrackerJson(appEnv: appEnv) {
      // do post request
      print("trackerJson: \(trackerJson)")
    } else {
      // log Error
      return
    }

  }

  public func buildTrackerJson(appEnv: AppEnv) -> JSON? {

      var jsonEvent = JSON([:])
      guard let vcapApplication = appEnv.getApp() else {
        print("Couldn't get Cloud Foundry App instance.")
        return nil
      }

      let dateFormatter = DateFormatter()
      dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
      print("THE date: \(dateFormatter.string(from: Date()))")
      jsonEvent["date_sent"].stringValue = dateFormatter.string(from: Date())

      jsonEvent["application_name"].stringValue = vcapApplication.name
      jsonEvent["space_id"].stringValue = vcapApplication.spaceId
      jsonEvent["application_version"].stringValue = vcapApplication.version
      let urisJson = JSON(vcapApplication.uris)
      jsonEvent["application_uris"] = urisJson

      let services = appEnv.getServices()
      if services.count > 0 {
        
      }
      return jsonEvent
  }

}