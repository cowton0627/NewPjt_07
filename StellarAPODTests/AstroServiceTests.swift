import XCTest
@testable import StellarAPOD

final class AstroServiceTests: XCTestCase {
    override func tearDown() {
        AstroURLProtocol.handler = nil
        super.tearDown()
    }

    func testSuccessfulJSONResponseDecodesPayloadAndCompletesOnMainThread() {
        AstroURLProtocol.handler = { request in
            let response = HTTPURLResponse(
                url: request.url!, statusCode: 200, httpVersion: nil,
                headerFields: ["Content-Type": "application/json; charset=utf-8"]
            )!
            let data = #"[{"title":"Earthrise","date":"2026-07-21"}]"#.data(using: .utf8)!
            return (response, data)
        }
        let service = makeService()
        let completed = expectation(description: "request completed")

        service.fetchAstros { result in
            XCTAssertTrue(Thread.isMainThread)
            XCTAssertEqual(try? result.get().first?.title, "Earthrise")
            completed.fulfill()
        }

        wait(for: [completed], timeout: 2)
    }

    func testNonHTTPResponseReturnsInvalidResponse() {
        AstroURLProtocol.handler = { request in
            (URLResponse(url: request.url!, mimeType: nil, expectedContentLength: 0, textEncodingName: nil), Data())
        }

        assertFailure(from: makeService()) { error in
            guard case AstroService.ServiceError.invalidResponse = error else {
                return XCTFail("Expected invalidResponse, got \(error)")
            }
        }
    }

    func testTransportErrorIsForwarded() {
        AstroURLProtocol.handler = { _ in throw URLError(.notConnectedToInternet) }

        assertFailure(from: makeService()) { error in
            XCTAssertEqual((error as? URLError)?.code, .notConnectedToInternet)
        }
    }

    func testErrorHTTPStatusReturnsStatusCode() {
        AstroURLProtocol.handler = { request in
            let response = HTTPURLResponse(
                url: request.url!, statusCode: 503, httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, Data())
        }

        assertFailure(from: makeService()) { error in
            guard case AstroService.ServiceError.httpStatus(503) = error else {
                return XCTFail("Expected HTTP 503, got \(error)")
            }
        }
    }

    func testUnsupportedContentTypeReturnsReceivedType() {
        AstroURLProtocol.handler = { request in
            let response = HTTPURLResponse(
                url: request.url!, statusCode: 200, httpVersion: nil,
                headerFields: ["Content-Type": "text/html"]
            )!
            return (response, Data("[]".utf8))
        }

        assertFailure(from: makeService()) { error in
            guard case AstroService.ServiceError.unsupportedContentType(let type) = error else {
                return XCTFail("Expected unsupportedContentType, got \(error)")
            }
            XCTAssertEqual(type, "text/html")
        }
    }

    func testEmptySuccessfulResponseReturnsEmptyData() {
        AstroURLProtocol.handler = { request in
            let response = HTTPURLResponse(
                url: request.url!, statusCode: 200, httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, Data())
        }

        assertFailure(from: makeService()) { error in
            guard case AstroService.ServiceError.emptyData = error else {
                return XCTFail("Expected emptyData, got \(error)")
            }
        }
    }

    func testMalformedJSONPreservesUnderlyingDecodingError() {
        AstroURLProtocol.handler = { request in
            let response = HTTPURLResponse(
                url: request.url!, statusCode: 200, httpVersion: nil,
                headerFields: ["Content-Type": "text/plain"]
            )!
            return (response, Data("not json".utf8))
        }

        assertFailure(from: makeService()) { error in
            guard case AstroService.ServiceError.decodingFailed = error else {
                return XCTFail("Expected decodingFailed, got \(error)")
            }
            XCTAssertNotNil((error as? AstroService.ServiceError)?.underlyingError)
        }
    }

    func testInvalidEndpointReturnsInvalidURLWithoutStartingRequest() {
        let service = AstroService(session: makeSession(), endpoint: nil)

        assertFailure(from: service) { error in
            guard case AstroService.ServiceError.invalidURL = error else {
                return XCTFail("Expected invalidURL, got \(error)")
            }
        }
    }

    private func makeService() -> AstroService {
        AstroService(
            session: makeSession(),
            endpoint: URL(string: "https://example.com/apod.json")!
        )
    }

    private func makeSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [AstroURLProtocol.self]
        return URLSession(configuration: configuration)
    }

    private func assertFailure(
        from service: AstroService,
        verify: @escaping (Error) -> Void
    ) {
        let completed = expectation(description: "request failed")
        service.fetchAstros { result in
            XCTAssertTrue(Thread.isMainThread)
            switch result {
            case .success:
                XCTFail("Expected failure")
            case .failure(let error):
                verify(error)
            }
            completed.fulfill()
        }
        wait(for: [completed], timeout: 2)
    }
}

private final class AstroURLProtocol: URLProtocol {
    static var handler: ((URLRequest) throws -> (URLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = Self.handler else {
            return client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse)) ?? ()
        }
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
