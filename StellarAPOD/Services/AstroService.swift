//
//  AstroService.swift
//  StellarAPOD
//
//  抽離 API 與 JSON 解碼；VC / ViewModel 都不再直接碰 URLSession。
//  callback 一律在主線程。
//

import Foundation

protocol AstroServicing {
    func fetchAstros(completion: @escaping (Result<[Astro], Error>) -> Void)
}

final class AstroService: AstroServicing {
    static let shared = AstroService()
    private init() {}

    private let endpoint = "https://raw.githubusercontent.com/cmmobile/NasaDataSet/main/apod.json"

    enum ServiceError: LocalizedError {
        case invalidURL
        case emptyData
        case invalidResponse
        case httpStatus(Int)
        case unsupportedContentType(String?)
        case decodingFailed(Error)

        var errorDescription: String? {
            switch self {
            case .invalidURL:     return "資料來源網址無效"
            case .emptyData:      return "沒有取得回傳資料"
            case .invalidResponse: return "伺服器回應格式無效"
            case .httpStatus(let code): return "伺服器回傳錯誤（HTTP \(code)）"
            case .unsupportedContentType(let type):
                return "不支援的資料格式（\(type ?? "未知")）"
            case .decodingFailed: return "資料解析失敗"
            }
        }

        var underlyingError: Error? {
            guard case .decodingFailed(let error) = self else { return nil }
            return error
        }
    }

    func fetchAstros(completion: @escaping (Result<[Astro], Error>) -> Void) {
        guard let url = URL(string: endpoint) else {
            DispatchQueue.main.async { completion(.failure(ServiceError.invalidURL)) }
            return
        }
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                DispatchQueue.main.async { completion(.failure(error)) }
                return
            }
            guard let response = response as? HTTPURLResponse else {
                DispatchQueue.main.async { completion(.failure(ServiceError.invalidResponse)) }
                return
            }
            guard (200...299).contains(response.statusCode) else {
                DispatchQueue.main.async {
                    completion(.failure(ServiceError.httpStatus(response.statusCode)))
                }
                return
            }
            let contentType = response.value(forHTTPHeaderField: "Content-Type")
            let supportedType = contentType?.contains("json") == true ||
                contentType?.contains("text/plain") == true
            guard supportedType else {
                DispatchQueue.main.async {
                    completion(.failure(ServiceError.unsupportedContentType(contentType)))
                }
                return
            }
            guard let data = data else {
                DispatchQueue.main.async { completion(.failure(ServiceError.emptyData)) }
                return
            }
            let decoder = JSONDecoder()
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            decoder.dateDecodingStrategy = .formatted(formatter)
            do {
                let astros = try decoder.decode([Astro].self, from: data)
                DispatchQueue.main.async { completion(.success(astros)) }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(ServiceError.decodingFailed(error)))
                }
            }
        }.resume()
    }
}
