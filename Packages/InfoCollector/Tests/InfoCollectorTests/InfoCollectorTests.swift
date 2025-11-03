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
    #expect(!result.isEmpty, "Generated string should not be empty")
}
