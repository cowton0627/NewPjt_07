//
//  ImageLoader.swift
//  StellarAPOD
//

import UIKit

protocol ImageLoadCancellable {
    func cancel()
}

protocol ImageLoading {
    @discardableResult
    func load(from url: URL,
              targetSize: CGSize,
              completion: @escaping (UIImage?) -> Void) -> ImageLoadCancellable?
}

final class ImageLoader: ImageLoading {
    static let shared = ImageLoader()

    private struct PendingRequest {
        let task: URLSessionDataTask
        var completions: [UUID: (UIImage?) -> Void]
    }

    private let cache = NSCache<NSURL, UIImage>()
    private let session: URLSession
    private let lock = NSLock()
    private var pendingRequests: [URL: PendingRequest] = [:]

    init(session: URLSession = .shared) {
        self.session = session
        cache.totalCostLimit = 100 * 1024 * 1024
    }

    @discardableResult
    func load(from url: URL,
              targetSize: CGSize,
              completion: @escaping (UIImage?) -> Void) -> ImageLoadCancellable? {
        if let cached = cache.object(forKey: url as NSURL) {
            completion(cached)
            return nil
        }

        let requestID = UUID()
        lock.lock()
        if var pending = pendingRequests[url] {
            pending.completions[requestID] = completion
            pendingRequests[url] = pending
            lock.unlock()
            return ImageLoadToken { [weak self] in self?.cancel(url: url, id: requestID) }
        }

        let task = session.dataTask(with: url) { [weak self] data, _, error in
            let image: UIImage?
            if error == nil, let data = data {
                image = Self.downsample(data: data, to: targetSize)
            } else {
                image = nil
            }
            self?.finish(url: url, image: image)
        }
        pendingRequests[url] = PendingRequest(
            task: task,
            completions: [requestID: completion]
        )
        lock.unlock()
        task.resume()

        return ImageLoadToken { [weak self] in self?.cancel(url: url, id: requestID) }
    }

    private func finish(url: URL, image: UIImage?) {
        if let image = image, let cgImage = image.cgImage {
            let decodedCost = cgImage.bytesPerRow * cgImage.height
            cache.setObject(image, forKey: url as NSURL, cost: decodedCost)
        }

        lock.lock()
        let callbacks = pendingRequests.removeValue(forKey: url)
            .map { Array($0.completions.values) } ?? []
        lock.unlock()
        DispatchQueue.main.async {
            callbacks.forEach { $0(image) }
        }
    }

    private func cancel(url: URL, id: UUID) {
        lock.lock()
        guard var pending = pendingRequests[url] else {
            lock.unlock()
            return
        }
        pending.completions.removeValue(forKey: id)
        if pending.completions.isEmpty {
            pendingRequests.removeValue(forKey: url)
            lock.unlock()
            pending.task.cancel()
        } else {
            pendingRequests[url] = pending
            lock.unlock()
        }
    }

    private static func downsample(data: Data, to pointSize: CGSize) -> UIImage? {
        let sourceOptions: [CFString: Any] = [kCGImageSourceShouldCache: false]
        guard let source = CGImageSourceCreateWithData(data as CFData,
                                                       sourceOptions as CFDictionary) else {
            return nil
        }
        let maxDimensionInPoints = max(pointSize.width, pointSize.height, 100)
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxDimensionInPoints * UIScreen.main.scale
        ]
        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(
            source, 0, options as CFDictionary
        ) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}

private final class ImageLoadToken: ImageLoadCancellable {
    private let onCancel: () -> Void
    private var isCancelled = false

    init(onCancel: @escaping () -> Void) {
        self.onCancel = onCancel
    }

    func cancel() {
        guard !isCancelled else { return }
        isCancelled = true
        onCancel()
    }
}
