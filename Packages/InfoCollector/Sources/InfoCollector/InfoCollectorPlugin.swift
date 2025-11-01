protocol InfoCollectorPlugin {
    var name: String { get }
    func collect(callback: @escaping (Result<String, Error>) -> Void)
    @available(iOS 13.0.0, macOS 10.15, *)
    func collect() async throws -> String
}

extension InfoCollectorPlugin {
    @available(iOS 13.0.0, macOS 10.15, *)
    func collect() async throws -> String {
        try await withCheckedThrowingContinuation {
            (continuation: CheckedContinuation<String, Error>) in
            collect { result in
                switch result {
                case .success(let string):
                    continuation.resume(returning: string)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
