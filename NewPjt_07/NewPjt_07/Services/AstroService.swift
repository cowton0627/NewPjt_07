//
//  AstroService.swift
//  NewPjt_07
//
//  抽離 API 與 JSON 解碼；VC / ViewModel 都不再直接碰 URLSession。
//  callback 一律在主線程。
//

import Foundation

final class AstroService {
    static let shared = AstroService()
    private init() {}

    private let endpoint = "https://raw.githubusercontent.com/cmmobile/NasaDataSet/main/apod.json"

    enum ServiceError: LocalizedError {
        case invalidURL
        case emptyData
        case decodingFailed

        var errorDescription: String? {
            switch self {
            case .invalidURL:     return "資料來源網址無效"
            case .emptyData:      return "沒有取得回傳資料"
            case .decodingFailed: return "資料解析失敗"
            }
        }
    }

    func fetchAstros(completion: @escaping (Result<[Astro], Error>) -> Void) {
        guard let url = URL(string: endpoint) else {
            DispatchQueue.main.async { completion(.failure(ServiceError.invalidURL)) }
            return
        }
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                DispatchQueue.main.async { completion(.failure(error)) }
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
                DispatchQueue.main.async { completion(.failure(ServiceError.decodingFailed)) }
            }
        }.resume()
    }
}
