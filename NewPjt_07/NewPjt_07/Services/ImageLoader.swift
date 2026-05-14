//
//  ImageLoader.swift
//  NewPjt_07
//
//  非主線程下載 + NSCache 記憶體快取 + ImageIO downsample。
//  caller 重用 cell 時可 cancel 回傳的 task，避免「晚到的圖蓋掉新 cell」。
//

import UIKit

final class ImageLoader {
    static let shared = ImageLoader()

    private let cache = NSCache<NSURL, UIImage>()

    private init() {
        cache.totalCostLimit = 100 * 1024 * 1024   // 約 100 MB
    }

    /// 載入圖片：先查 cache，沒有就背景下載 + downsample + 存 cache。
    /// - Returns: 真的有發出網路請求時回傳 task；命中 cache 時回傳 nil。
    @discardableResult
    func load(from url: URL,
              targetSize: CGSize,
              completion: @escaping (UIImage?) -> Void) -> URLSessionDataTask? {

        if let cached = cache.object(forKey: url as NSURL) {
            completion(cached)
            return nil
        }

        let task = URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            if let error = error {
                // 被 cancel 也會走這條（NSURLErrorCancelled），不視為錯誤
                let nsError = error as NSError
                if nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled {
                    return
                }
                print("ImageLoader error: \(error)")
                DispatchQueue.main.async { completion(nil) }
                return
            }

            guard let data = data,
                  let image = Self.downsample(data: data, to: targetSize) else {
                DispatchQueue.main.async { completion(nil) }
                return
            }

            self?.cache.setObject(image, forKey: url as NSURL, cost: data.count)
            DispatchQueue.main.async { completion(image) }
        }
        task.resume()
        return task
    }

    /// 在 decode 時就縮到目標尺寸，避免載入後再 resize 浪費記憶體。
    private static func downsample(data: Data, to pointSize: CGSize) -> UIImage? {
        let sourceOptions: [CFString: Any] = [kCGImageSourceShouldCache: false]
        guard let source = CGImageSourceCreateWithData(data as CFData,
                                                       sourceOptions as CFDictionary) else {
            return nil
        }
        let scale = UIScreen.main.scale
        // 至少給 100pt 下限，避免 cell 還沒 layout 時 size 為 0
        let maxDimensionInPoints = max(pointSize.width, pointSize.height, 100)
        let maxDimensionInPixels = maxDimensionInPoints * scale

        let downsampleOptions: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxDimensionInPixels
        ]
        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source,
                                                                0,
                                                                downsampleOptions as CFDictionary) else {
            return nil
        }
        return UIImage(cgImage: cgImage)
    }
}
