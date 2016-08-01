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
import HeliumLogger
import LoggerAPI
import KituraNet

public enum DeploymentTrackerError: ErrorProtocol {
  case UnavailableInfo(String)
}

public struct CloudFoundryDeploymentTracker {

  var appEnv: AppEnv?

  public init() {
    initLogger()
    do {
      appEnv = try CloudFoundryEnv.getAppEnv()
    } catch {
      Log.warning("Couldn't get Cloud Foundry App environment instance.")
    }
  }

  public init(appEnv: AppEnv) {
    initLogger()
    self.appEnv = appEnv
  }
  
  private func initLogger() {
    if Log.logger == nil {
      Log.logger = HeliumLogger()
    }
  }

  public func track() {

    if let appEnv = appEnv, trackerJson = buildTrackerJson(appEnv: appEnv), jsonString = trackerJson.rawString() {
      // do post request
      print("trackerJson: \(trackerJson)")
      
      var requestOptions: [ClientRequest.Options] = []
      requestOptions.append(.method("POST"))
      requestOptions.append(.schema("https://"))
      requestOptions.append(.hostname("deployment-tracker.mybluemix.net"))
      requestOptions.append(.port(443))
      requestOptions.append(.path("/api/v1/track"))
      
      let req = HTTP.request(requestOptions) { response in
        if let response = response where response.statusCode == HTTPStatusCode.OK || response.statusCode == HTTPStatusCode.accepted {
          Log.info("Uploaded stats \(response.status)")
          do {
            let body = NSMutableData()
            try response.readAllData(into: body)
            let jsonResponse = JSON(data: body)
            Log.info("Deployment Tracker response: \(jsonResponse)")
          } catch {
            Log.error("Bad JSON doc received from deployment tracker.")
          }
          
        } else {
          Log.error("Failed to send tracking data with status code: \(response?.status)")
        }
      }
      req.end(jsonString)
      
    } else {
      Log.error("Failed to build valid JSON for deployment tracker.")
      return
    }

  }

  public func buildTrackerJson(appEnv: AppEnv) -> JSON? {

      var jsonEvent = JSON([:])
      guard let vcapApplication = appEnv.getApp() else {
        Log.warning("Couldn't get Cloud Foundry App instance.")
        return nil
      }

      let dateFormatter = DateFormatter()
      dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
      jsonEvent["date_sent"].stringValue = dateFormatter.string(from: Date())

      jsonEvent["runtime"].stringValue = "swift"
      jsonEvent["application_name"].stringValue = vcapApplication.name
      jsonEvent["space_id"].stringValue = vcapApplication.spaceId
      jsonEvent["application_version"].stringValue = vcapApplication.version
      let urisJson = JSON(vcapApplication.uris)
      jsonEvent["application_uris"] = urisJson

      let services = appEnv.getServices()
      if services.count > 0 {
        var serviceDictionary = [String : JSON]()
        for (_, service) in services {
          
          if var serviceStats = serviceDictionary[service.label] {
            
            serviceStats["count"].intValue = serviceStats["count"].intValue + 1
            var plans = serviceStats["plans"].arrayValue.map { $0.stringValue }            
            plans.append(service.plan)
            serviceStats["plans"] = JSON(Array(Set(plans)))
            serviceDictionary[service.label] = serviceStats
          } else {
            
            let newService = JSON(["count" : 1, "plans" : [service.plan]])
            serviceDictionary[service.label] = newService
          }
        }
        jsonEvent["bound_vcap_services"] = JSON(serviceDictionary)
      }
      return jsonEvent
  }

}
