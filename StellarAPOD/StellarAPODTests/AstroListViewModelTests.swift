import XCTest
@testable import StellarAPOD

final class AstroListViewModelTests: XCTestCase {
    func testFetchPublishesLoadingThenLoaded() {
        let astro = Astro(title: "Earth", url: nil, hdurl: nil, date: nil,
                          copyright: nil, description: nil)
        let service = StubAstroService(result: .success([astro]))
        let viewModel = AstroListViewModel(service: service)
        var states: [String] = []
        viewModel.onStateChange = { states.append(Self.name(of: $0)) }

        viewModel.fetch()

        XCTAssertEqual(states, ["loading", "loaded"])
        XCTAssertEqual(viewModel.numberOfItems, 1)
    }

    func testFetchPublishesEmptyForEmptyResponse() {
        let viewModel = AstroListViewModel(
            service: StubAstroService(result: .success([]))
        )
        var states: [String] = []
        viewModel.onStateChange = { states.append(Self.name(of: $0)) }

        viewModel.fetch()

        XCTAssertEqual(states, ["loading", "empty"])
        XCTAssertEqual(viewModel.numberOfItems, 0)
    }

    func testFetchPublishesLocalizedFailure() {
        let error = AstroService.ServiceError.httpStatus(503)
        let viewModel = AstroListViewModel(
            service: StubAstroService(result: .failure(error))
        )
        var failureMessage: String?
        viewModel.onStateChange = {
            if case .failed(let message) = $0 { failureMessage = message }
        }

        viewModel.fetch()

        XCTAssertEqual(failureMessage, "伺服器回傳錯誤（HTTP 503）")
    }

    private static func name(of state: AstroListViewModel.State) -> String {
        switch state {
        case .idle: return "idle"
        case .loading: return "loading"
        case .loaded: return "loaded"
        case .empty: return "empty"
        case .failed: return "failed"
        }
    }
}

private final class StubAstroService: AstroServicing {
    private let result: Result<[Astro], Error>

    init(result: Result<[Astro], Error>) {
        self.result = result
    }

    func fetchAstros(completion: @escaping (Result<[Astro], Error>) -> Void) {
        completion(result)
    }
}

