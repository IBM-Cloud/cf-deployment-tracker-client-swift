/**
* Copyright IBM Corporation 2016, 2017
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
import Configuration
import CloudFoundryEnv
import CloudFoundryConfig
import LoggerAPI

public struct CloudFoundryDeploymentTracker {
  let configMgr: ConfigurationManager
  let repositoryURL: String
  var codeVersion: String?

  public init(configMgr: ConfigurationManager, repositoryURL: String, codeVersion: String? = nil) {
    self.repositoryURL = repositoryURL
    self.codeVersion = codeVersion
    self.configMgr = configMgr
  }

  public init(repositoryURL: String, codeVersion: String? = nil) {
    let configMgr = ConfigurationManager()
    configMgr.load(.environmentVariables)
    self.init(configMgr: configMgr, repositoryURL: repositoryURL, codeVersion: codeVersion)
  }

  /// Sends off HTTP post request to tracking service, simply logging errors on failure
  public func track() {
    Log.verbose("About to construct http request for cf-deployment-tracker-service...")
    if let trackerJson = buildTrackerJson(configMgr: configMgr),
    let jsonData = try? JSONSerialization.data(withJSONObject: trackerJson) {
      Log.verbose("JSON payload for cf-deployment-tracker-service is: \(jsonData)")
      // Build URL instance
      guard let url = URL(string: "https://deployment-tracker.mybluemix.net:443/api/v1/track") else {
        Log.verbose("Failed to create URL object to connect to cf-deployment-tracker-service...")
        return
      }
      var request = URLRequest(url: url)
      request.httpMethod = "POST"
      request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
      request.httpBody = jsonData

      // Build task for request
      let requestTask = URLSession(configuration: .default).dataTask(with: request) {
        data, response, error in

        guard let httpResponse = response as? HTTPURLResponse else {
          Log.error("Failed to send tracking data to cf-deployment-tracker-service: \(String(describing: error))")
          return
        }

        Log.info("HTTP response code: \(httpResponse.statusCode)")
        // OK = 200, CREATED = 201
        if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
          if let data = data, let jsonResponse = try? JSONSerialization.jsonObject(with: data, options: []) {
            Log.info("Deployment Tracker response: \(jsonResponse)")
          } else {
            Log.error("Bad JSON payload received from cf-deployment-tracker-service.")
          }
        } else {
          Log.error("Failed to send tracking data to cf-deployment-tracker-service.")
        }
      }
      Log.verbose("Successfully built HTTP request options for cf-deployment-tracker-service.")
      requestTask.resume()
      Log.verbose("Sent HTTP request to cf-deployment-tracker-service...")
    } else {
      Log.verbose("Failed to build valid JSON payload for deployment tracker... maybe running locally and not on the cloud?")
    }
  }

  /// Helper method to build Json in a valid format for tracking service
  ///
  /// - parameter configMgr: application environment to pull Bluemix app data from
  ///
  /// - returns: JSON, assuming we have access to application info
  public func buildTrackerJson(configMgr: ConfigurationManager) -> [String:Any]? {
    var jsonEvent: [String:Any] = [:]
    guard let vcapApplication = configMgr.getApp() else {
      Log.verbose("Couldn't get Cloud Foundry App instance... maybe running locally and not on the cloud?")
      return nil
    }

    Log.verbose("Preparing dictionary payload for cf-deployment-tracker-service...")
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
    jsonEvent["application_uris"] = vcapApplication.uris
    jsonEvent["instance_index"] = vcapApplication.instanceIndex

    Log.verbose("Verifying services bound to application...")
    let services = configMgr.getServices()
    if services.count > 0 {
      var serviceDictionary = [String: Any]()
      for (_, service) in services {
        if var serviceStats = serviceDictionary[service.label] as? [String: Any] {
          if let count = serviceStats["count"] as? Int {
            serviceStats["count"] = count + 1
          }
          if var plans = serviceStats["plans"] as? [String] {
            if !plans.contains(service.plan) { plans.append(service.plan) }
            serviceStats["plans"] = plans
          }
          serviceDictionary[service.label] = serviceStats
        } else {
          var newService = [String: Any]()
          newService["count"] = 1
          newService["plans"] = service.plan.components(separatedBy: ", ")
          serviceDictionary[service.label] = newService
        }
      }
      jsonEvent["bound_vcap_services"] = serviceDictionary
    }
    Log.verbose("Finished preparing dictionary payload for cf-deployment-tracker-service.")
    Log.verbose("Dictionary payload for cf-deployment-tracker-service is: \(jsonEvent)")
    return jsonEvent
  }

}
