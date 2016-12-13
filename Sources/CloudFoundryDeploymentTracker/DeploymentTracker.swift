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
import HeliumLogger
import LoggerAPI
import KituraNet

public struct CloudFoundryDeploymentTracker {

  var appEnv: AppEnv?
  var repositoryURL: String
  var codeVersion: String?

  public init(repositoryURL: String, codeVersion: String? = nil) {
    self.repositoryURL = repositoryURL
    self.codeVersion = codeVersion
    initLogger()
    do {
      appEnv = try CloudFoundryEnv.getAppEnv()
    } catch {
      Log.verbose("Couldn't get Cloud Foundry App environment instance...")
    }
  }

  public init(appEnv: AppEnv, repositoryURL: String, codeVersion: String? = nil) {
    self.repositoryURL = repositoryURL
    self.codeVersion = codeVersion
    initLogger()
    self.appEnv = appEnv
  }

  private func initLogger() {
    if Log.logger == nil {
      Log.logger = HeliumLogger()
    }
  }


  /// Sends off http post request to tracking service, simply logging errors on failure
  public func track() {
    if let appEnv = appEnv, let trackerJson = buildTrackerJson(appEnv: appEnv) {
      let jsonString = trackerJson.description
      var requestOptions: [ClientRequest.Options] = []
      requestOptions.append(.method("POST"))
      requestOptions.append(.schema("https://"))
      requestOptions.append(.hostname("deployment-tracker.mybluemix.net"))
      requestOptions.append(.port(443))
      requestOptions.append(.path("/api/v1/track"))
      let headers = ["Content-Type": "application/json"]
      requestOptions.append(.headers(headers))

      let req = HTTP.request(requestOptions) { response in
        if let response = response, response.statusCode == HTTPStatusCode.OK || response.statusCode == HTTPStatusCode.created {
          Log.info("Uploaded stats \(response.status)")
          do {
            var body = Data()
            try response.readAllData(into: &body)
            let jsonResponse = try? JSONSerialization.jsonObject(with: body, options: [])
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
      Log.verbose("Failed to build valid JSON payload for deployment tracker... maybe running locally and not on the cloud?")
      return
    }
  }

  /// Helper method to build Json in a valid format for tracking service
  ///
  /// - parameter appEnv: application environment to pull Bluemix app data from
  ///
  /// - returns: JSON, assuming we have access to application info
  public func buildTrackerJson(appEnv: AppEnv) -> [String: Any]? {
      var jsonEvent: [String: Any] = [:]
      guard let vcapApplication = appEnv.getApp() else {
        Log.verbose("Couldn't get Cloud Foundry App instance... maybe running locally and not on the cloud?")
        return nil
      }

      let dateFormatter = DateFormatter()
      #if os(OSX)
        //dateFormatter.calendar = Calendar(identifier: .iso8601)
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
      #else
        //dateFormatter.calendar = Calendar(identifier: .iso8601)
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone(abbreviation: "GMT")
      #endif
      dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSX"
      jsonEvent["date_sent"] = dateFormatter.string(from: Date())

      if let codeVersion = self.codeVersion {
        jsonEvent["code_version"] = codeVersion
      }
      jsonEvent["repository_url"] = repositoryURL
      jsonEvent["runtime"] = "swift"
      jsonEvent["application_name"] = vcapApplication.name
      jsonEvent["space_id"] = vcapApplication.spaceId
      jsonEvent["application_id"] = vcapApplication.id
      jsonEvent["application_version"] = vcapApplication.version
      //let urisJson = JSON(vcapApplication.uris)
      //jsonEvent["application_uris"] = urisJson
      jsonEvent["application_uris"] = vcapApplication.uris

      let services = appEnv.getServices()
      if services.count > 0 {
        var serviceDictionary = [String : [String: Any]]()
        for (_, service) in services {
          if var serviceStats = serviceDictionary[service.label] {
            if let count = serviceStats["count"] as? Int {
                serviceStats["count"] = count + 1
            }
            var plans = serviceStats["plans"].arrayValue.map { $0.stringValue }
            plans.append(service.plan)
            serviceStats["plans"] = plans
            serviceDictionary[service.label] = serviceStats
          } else {
            let newService = JSON(["count" : 1, "plans" : [service.plan]])
            serviceDictionary[service.label] = newService
          }
        }
        jsonEvent["bound_vcap_services"] = serviceDictionary
      }
      return jsonEvent
  }

}
