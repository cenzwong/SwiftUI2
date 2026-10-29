import XCTest
@testable import SwiftUI2Core
@testable import SwiftUI2Testing

final class ScriptedModelTests: XCTestCase {
    func testScriptedModelInputsAndExpectedIntents() async throws {
        let mockModel = MockIntentModel()

        for testCase in ScriptedModelResponses.testCases {
            let proposals = try await mockModel.identify(
                input: testCase.input,
                context: IntentContext(revision: 1),
                descriptors: ScriptedModelResponses.sampleDescriptors
            )

            let matchedIDs = proposals.map(\.intentID)
            XCTAssertEqual(
                matchedIDs,
                testCase.expectedIntentIDs,
                "Failed test case for input: '\(testCase.input)'"
            )
        }
    }
}
