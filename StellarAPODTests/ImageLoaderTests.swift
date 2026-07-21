import XCTest
@testable import StellarAPOD

final class ImageLoaderTests: XCTestCase {
    override func setUp() {
        super.setUp()
        ImageURLProtocol.requestCount = 0
    }

    func testConcurrentLoadsForSameURLShareOneRequest() {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [ImageURLProtocol.self]
        let loader = ImageLoader(session: URLSession(configuration: configuration))
        let url = URL(string: "https://example.com/image.png")!
        let first = expectation(description: "first completion")
        let second = expectation(description: "second completion")

        _ = loader.load(from: url, targetSize: CGSize(width: 100, height: 100)) { image in
            XCTAssertNotNil(image)
            first.fulfill()
        }
        _ = loader.load(from: url, targetSize: CGSize(width: 100, height: 100)) { image in
            XCTAssertNotNil(image)
            second.fulfill()
        }

        wait(for: [first, second], timeout: 2)
        XCTAssertEqual(ImageURLProtocol.requestCount, 1)
    }
}

private final class ImageURLProtocol: URLProtocol {
    static var requestCount = 0

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        Self.requestCount += 1
        let png = Data(base64Encoded:
            "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII="
        )!
        let response = HTTPURLResponse(
            url: request.url!, statusCode: 200,
            httpVersion: "HTTP/1.1", headerFields: ["Content-Type": "image/png"]
        )!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: png)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
