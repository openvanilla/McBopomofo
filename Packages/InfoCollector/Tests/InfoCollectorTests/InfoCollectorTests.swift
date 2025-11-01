import Testing

@testable import InfoCollector

@Test func example() async throws {
    let result: String = await withCheckedContinuation { continuation in
        Task { @MainActor in
            InfoCollector.generate { string in
                continuation.resume(returning: string)
            }
        }
    }
    print(result)
    #expect(!result.isEmpty, "G enerated string should not be empty")
}
