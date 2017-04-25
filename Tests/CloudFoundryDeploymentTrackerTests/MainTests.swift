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

#if os(Linux)
    import Glibc
#else
    import Darwin
#endif

import XCTest
import Foundation
import CloudFoundryEnv
import Configuration
import CloudFoundryConfig

@testable import CloudFoundryDeploymentTracker

class MainTests: XCTestCase {

  static var allTests: [(String, (MainTests) -> () throws -> Void)] {
    return [
      ("testTrackerJsonBuilding", testTrackerJsonBuilding),
      ("testNumerousServiceJson", testNumerousServiceJson)
    ]
  }

  let options = "{ \"vcap\": { \"application\": { \"limits\": { \"mem\": 128, \"disk\": 1024, \"fds\": 16384 }, \"application_id\": \"e582416a-9771-453f-8df1-7b467f6d78e4\", \"application_version\": \"e5e029d1-4a1a-4004-9f79-655d550183fb\", \"application_name\": \"swift-test\", \"application_uris\": [ \"swift-test.mybluemix.net\" ], \"version\": \"e5e029d1-4a1a-4004-9f79-655d550183fb\", \"name\": \"swift-test\", \"space_name\": \"dev\", \"space_id\": \"b15eb0bb-cbf3-43b6-bfbc-f76d495981e5\", \"uris\": [ \"swift-test.mybluemix.net\" ], \"users\": null, \"instance_id\": \"7d4f24cfba06462ba23d68aaf1d7354a\", \"instance_index\": 0, \"host\": \"0.0.0.0\", \"port\": 61263, \"started_at\": \"2016-03-04 02:43:07 +0000\", \"started_at_timestamp\": 1457059387, \"start\": \"2016-03-04 02:43:07 +0000\", \"state_timestamp\": 1457059387 }, \"services\": { \"cloudantNoSQLDB\": [ { \"name\": \"Cloudant NoSQL DB-kd\", \"label\": \"cloudantNoSQLDB\", \"tags\": [ \"data_management\", \"ibm_created\", \"ibm_dedicated_public\" ], \"plan\": \"Shared\", \"credentials\": { \"username\": \"09ed7c8a-fae8-48ea-affa-0b44b2224ec0-bluemix\", \"password\": \"06c19ae06b1915d8a6649df5901eca85e885182421ffa9ef89e14bbc1b76efd4\", \"host\": \"09ed7c8a-fae8-48ea-affa-0b44b2224ec0-bluemix.cloudant.com\", \"port\": 443, \"url\": \"https://09ed7c8a-fae8-48ea-affa-0b44b2224ec0-bluemix:06c19ae06b1915d8a6649df5901eca85e885182421ffa9ef89e14bbc1b76efd4@09ed7c8a-fae8-48ea-affa-0b44b2224ec0-bluemix.cloudant.com\" } } ] } } }"

  let optionsTwo = "{\"vcap\":{\"application\":{\"limits\":{\"mem\":512,\"disk\":1024,\"fds\":16384},\"application_id\":\"e58223416a-9731-443f-8df1-7br2r23r8e\",\"application_version\":\"e5e034d1-4a1a-5005-5f78-7655d550183d\",\"application_name\":\"BluePic\",\"application_uris\":[\"bluepic-unprofessorial-inexpressibility.mybluemix.net\"],\"version\":\"e5e034d1-4a1a-5005-5f78-7655d550183d\",\"name\":\"BluePic\",\"space_name\":\"dev\",\"space_id\":\"b15e5trt-cbf3-67d6-bafe-7b467f6d78b6\",\"uris\":[\"bluepic-unprofessorial-inexpressibility.mybluemix.net\"],\"users\":null,\"instance_id\":\"7d44cfba06wre45sgg63533af1d7354a\",\"instance_index\":0,\"host\":\"0.0.0.0\",\"port\":8090,\"started_at\":\"2016-03-04 02:43:07 +0000\",\"started_at_timestamp\":1457059387,\"start\":\"2016-03-04 02:43:07 +0000\",\"state_timestamp\":1457059387},\"services\":{\"cloudantNoSQLDB\":[{\"name\":\"BluePic-Cloudant\",\"label\":\"cloudantNoSQLDB\",\"plan\":\"Shared\",\"credentials\":{\"username\":\"ddad7a02-bf37-4b6e-8d3d-e5c1971697eb-bluemix\",\"password\":\"390dcb82f98254d397deb397d29d202040d3e9249c3ff17aca6b2d469ae80ed7\",\"host\":\"ddad7a02-bf37-4b6e-8d3d-e5c1971697eb-bluemix.cloudant.com\",\"port\":443,\"url\":\"https://ddad7a02-bf37-4b6e-8d3d-e5c1971697eb-bluemix:390dcb82f98254d397deb397d29d202040d3e9249c3ff17aca6b2d469ae80ed7@ddad7a02-bf37-4b6e-8d3d-e5c1971697eb-bluemix.cloudant.com\"}},{\"name\":\"BluePic-Cloudant-Two\",\"label\":\"cloudantNoSQLDB\",\"credentials\":{\"username\":\"ddad7a02-bf37-4b6e-8d3d-e5c1971697eb-bluemix\",\"password\":\"390dcb82f98254d397deb397d29d202040d3e9249c3ff17aca6b2d469ae80ed7\",\"host\":\"adad7a02-bf37-4b6e-8d3d-e5c1971697eb-bluemix.cloudant.com\",\"port\":433,\"url\":\"https://ddad7a02-bf37-4b6e-8d3d-e5c1971697eb-bluemix:390dcb82f98254d397deb397d29d202040d3e9249c3ff17aca6b2d469ae80ed7@ddad7a02-bf37-4b6e-8d3d-e5c1971697eb-bluemix.cloudant.com\"},\"plan\":\"Free\"}],\"Object-Storage\":[{\"name\":\"BluePic-Object-Storage\",\"label\":\"Object-Storage\",\"credentials\":{\"auth_url\":\"https://identity.open.softlayer.com\",\"project\":\"object_storage_89a8e80d_0425_4cf3_89d2_016ce885e631\",\"projectId\":\"bf24aff817b2420c863b1abe3c877694\",\"region\":\"dallas\",\"userId\":\"e5f868dc5f014cf397678e0c22506a02\",\"username\":\"admin_2d465e3a9c377a5e00ae0196d8a5315e36ded243\",\"password\":\"bEILjS3.ns=1Y17Q\",\"domainId\":\"efc4c0b8108a43bd80a9cc8af79a1837\",\"domainName\":\"1050765\",\"role\":\"admin\"}}],\"AdvancedMobileAccess\":[{\"name\":\"BluePic-Mobile-Client-Access\",\"label\":\"AdvancedMobileAccess\",\"plan\":\"Gold\",\"credentials\":{\"serverUrl\":\"https://imf-authserver.ng.bluemix.net/imf-authserver\",\"clientId\":\"e714d3ab-ae18-4afa-8e40-20df4660aad6\",\"secret\":\"+8UrcmTZRUuJhtFkCe2a3w\",\"tenantId\":\"e714d3ab-ae18-4afa-8e40-20df4660aad6\",\"admin_url\":\"https://mobile.ng.bluemix.net/imfmobileplatformdashboard/?appGuid=e714d3ab-ae18-4afa-8e40-20df4660aad6\"}}],\"imfpush\":[{\"name\":\"BluePic-IBM-Push\",\"label\":\"imfpush\",\"plan\":\"Basic\",\"credentials\":{\"url\":\"http://imfpush.ng.bluemix.net/imfpush/v1/apps/e714d3ab-ae18-4afa-8e40-20df4660aad6\",\"admin_url\":\"//mobile.ng.bluemix.net/imfpushdashboard/?appGuid=e714d3ab-ae18-4afa-8e40-20df4660aad6\",\"appSecret\":\"093c608c-9158-4f3d-9deb-6e13385ce30a\"}},{\"name\":\"BluePic-IBM-Push-Two\",\"label\":\"imfpush\",\"plan\":\"Basic\",\"credentials\":{\"url\":\"http://imfpush.ng.bluemix.net/imfpush/v1/apps/e714d3ab-ae18-4afa-8e40-20df4660aad6\",\"admin_url\":\"//mobile.ng.bluemix.net/imfpushdashboard/?appGuid=e714d3ab-ae18-4afa-8e40-20df4660aad6\",\"appSecret\":\"093c608c-9158-4f3d-9deb-6e13385ce30a\"}}]}}}"

  let testCodeVersion = "0.1"
  let testRepoURL = "https://github.com/IBM-Swift/Kitura-Starter-Bluemix.git"

  var jsonOptions: [String:Any] = [:]

  override func setUp() {
      super.setUp()
  }

  override func tearDown() {
    super.tearDown()
    jsonOptions = [:]
  }

  func loadJsonOptions(options: String) {
    jsonOptions = JSONUtils.convertStringToJSON(text: options)!
  }

  func testTrackerJsonBuilding() {
    loadJsonOptions(options: options)
    let configMgr = ConfigurationManager()
    configMgr.load(jsonOptions)
    let tracker = CloudFoundryDeploymentTracker(configMgr: configMgr, repositoryURL: testRepoURL)
    guard let jsonResult = tracker.buildTrackerJson(configMgr: configMgr) else {
      XCTFail("Failed to receive json from build tracker method.")
      return
    }

    XCTAssertEqual(jsonResult["application_name"] as? String, "swift-test")
    let uris = jsonResult["application_uris"] as! [String]
    XCTAssertEqual(uris.count, 1, "There should be only 1 uri in the uris array.")
    XCTAssertEqual(uris[0] as String, "swift-test.mybluemix.net", "URI value should match.")
    XCTAssertEqual(jsonResult["application_version"] as? String, "e5e029d1-4a1a-4004-9f79-655d550183fb")
    XCTAssertEqual(jsonResult["runtime"] as? String, "swift")
    XCTAssertEqual(jsonResult["space_id"] as? String, "b15eb0bb-cbf3-43b6-bfbc-f76d495981e5")
    XCTAssertNil(jsonResult["code_version"] as? String)
    XCTAssertEqual(jsonResult["repository_url"] as? String, testRepoURL)
    XCTAssertEqual(jsonResult["application_id"] as? String, "e582416a-9771-453f-8df1-7b467f6d78e4")
    XCTAssertEqual(jsonResult["instance_index"] as? Int, 0)

    // Validate date_sent
    XCTAssertNotNil(jsonResult["date_sent"] as? String)
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSX"
    let currentDate = dateFormatter.date(from: jsonResult["date_sent"] as! String)
    XCTAssertNotNil(currentDate)

    let cloudantJSON = jsonResult["bound_vcap_services"] as! [String:Any]
    let cloudantStats = cloudantJSON["cloudantNoSQLDB"] as! [String:Any]
    XCTAssertEqual(cloudantStats["count"] as? Int, 1)
    let plans = cloudantStats["plans"] as! [String]
    XCTAssertEqual(plans.count, 1)
    XCTAssertEqual(plans[0], "Shared")
  }

  func testNumerousServiceJson() {
    loadJsonOptions(options: optionsTwo)
    let configMgr = ConfigurationManager()
    configMgr.load(jsonOptions)
    let tracker = CloudFoundryDeploymentTracker(configMgr: configMgr, repositoryURL: testRepoURL, codeVersion: testCodeVersion)
    guard let jsonResult = tracker.buildTrackerJson(configMgr: configMgr) else {
      XCTFail("Failed to receive json from build tracker method.")
      return
    }

    XCTAssertEqual(jsonResult["application_name"] as? String, "BluePic")
    let uris = jsonResult["application_uris"] as? [String]
    XCTAssertEqual(uris!.count, 1, "There should be only 1 uri in the uris array.")
    XCTAssertEqual(uris![0] as String, "bluepic-unprofessorial-inexpressibility.mybluemix.net", "URI value should match.")
    XCTAssertEqual(jsonResult["application_version"] as? String, "e5e034d1-4a1a-5005-5f78-7655d550183d")
    XCTAssertEqual(jsonResult["runtime"] as? String, "swift")
    XCTAssertEqual(jsonResult["space_id"] as? String, "b15e5trt-cbf3-67d6-bafe-7b467f6d78b6")
    XCTAssertEqual(jsonResult["code_version"] as? String, testCodeVersion)
    XCTAssertEqual(jsonResult["repository_url"] as? String, testRepoURL)
    XCTAssertEqual(jsonResult["application_id"] as? String, "e58223416a-9731-443f-8df1-7br2r23r8e")
    XCTAssertEqual(jsonResult["instance_index"] as? Int, 0)

    let services = jsonResult["bound_vcap_services"] as! [String:Any]

    // basic test
    let objStorageStats = services["Object-Storage"] as! [String:Any]
    XCTAssertEqual(objStorageStats["count"] as? Int, 1)
    var plans = objStorageStats["plans"] as! [String]
    XCTAssertEqual(plans.count, 1)
    XCTAssertEqual(plans[0], "N/A")

    // mult-version of same service
    let pushStats = services["imfpush"] as! [String:Any]
    XCTAssertEqual(pushStats["count"] as? Int, 2)
    plans = pushStats["plans"] as! [String]
    XCTAssertEqual(plans.count, 1)
    XCTAssertEqual(plans[0], "Basic")

    // multi-version and plan of same service
    let cloudantStats = services["cloudantNoSQLDB"] as! [String:Any]
    XCTAssertEqual(cloudantStats["count"] as? Int, 2)
    plans = cloudantStats["plans"] as! [String]
    XCTAssertEqual(plans.count, 2)
    let expectedPlans = ["Free", "Shared"]
    for index in 0..<plans.count {
        XCTAssertTrue(plans.contains(expectedPlans[index]))
    }
  }
}
