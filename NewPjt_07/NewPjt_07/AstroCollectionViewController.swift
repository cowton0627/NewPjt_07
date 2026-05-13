//
//  AstroCollectionViewController.swift
//  NewPjt_07
//
//  Created by 鄭淳澧 on 2021/6/16.
//

import UIKit

struct Astro: Codable {
    var title: String?
    var url: URL?
    let hdurl: String   //因hdurl在解析時報錯, 故先設為String, 再轉為url
    var durl: URL? {
        hdurl.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed).flatMap { URL(string: $0) }
    }
    
    var date: Date?
    var copyright: String?
    var description: String?
}

class AstroCollectionCell: UICollectionViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var showImg: UIImageView!
    
}

private let reuseIdentifier = "Cell"

class AstroCollectionViewController: UICollectionViewController {
    var astros: [Astro] = []
//    let imageCache = NSCache<NSURL, UIImage>()
    
    
    @IBSegueAction func showDetail(_ coder: NSCoder) -> DetailViewController? {
        let controller =  DetailViewController(coder: coder)
        if let row = collectionView.indexPathsForSelectedItems?.first?.row {
            controller?.astro = astros[row]
        }
    return controller
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        getInfo()   //呼叫解析API的function
        
//        self.collectionView!.register(UICollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)

        let width = ( collectionView.bounds.width - 1 * 3 ) / 4     //塞四張圖的寬度計算
        let height = ( collectionView.bounds.width - 1 * 3 ) / 4    //高度同寬度
        
        let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout
            flowLayout?.itemSize = CGSize(width: width, height: height)
            flowLayout?.estimatedItemSize = .zero
            flowLayout?.minimumInteritemSpacing = 1
            flowLayout?.minimumLineSpacing = 1
    }


    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return astros.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! AstroCollectionCell
    
        let astro = astros[indexPath.row]
        cell.titleLabel.text = astro.title  //設定titleLabel
        
        let imageData = NSData(contentsOf: astro.url!)
        let image = UIImage(data: imageData! as Data)
        
//        self.imageCache.setObject(image!, forKey: astro.url as! NSURL)
        
        cell.showImg.image = image         //設定imageView
        
        return cell
    }


    func getInfo() {
        let urlStr = "https://raw.githubusercontent.com/cmmobile/NasaDataSet/main/apod.json"

            if let url = URL(string: urlStr) {
                URLSession.shared.dataTask(with: url) {(data, reponse, error) in
                    let decoder = JSONDecoder()
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd"
                    decoder.dateDecodingStrategy = .formatted(formatter)

                    if let data = data {
                        do {
                            let astro = try decoder.decode([Astro].self, from: data)
                            self.astros = astro
                            DispatchQueue.main.async {
                                self.collectionView.reloadData()
                            }
                        } catch {
                            print(error)
                        }
                    }
                }.resume()
            }else {
                print("Invalid URL.")
            }
    }


}

// MARK: - local-2021 封存版本（註解保留，原檔來自 local-2021 分支 commit 1099172）
/*
//
//  AstroCollectionViewController.swift
//  NewPjt_07
//  Created by 鄭淳澧 on 2021/6/16.
//

import UIKit

struct Astro: Codable {
    var title: String
    var url: URL
    let hdurl: String   //因hdurl在解析時報錯, 故先設為String, 再轉為url
    var durl: URL? {
        hdurl.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed).flatMap { URL(string: $0) }
    }

    var date: Date
    var copyright: String
    var description: String?
}

class AstroCollectionCell: UICollectionViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var showImg: UIImageView!

}

class AstroCollectionViewController: UICollectionViewController {
    var astros: [Astro] = []

    //使用Cache部份
//    let imageCache = NSCache<NSURL, UIImage>()

    @IBSegueAction func detailShowed(_ coder: NSCoder) -> DetailCollectionViewController? {
        let controller = DetailCollectionViewController(coder: coder)
        if let row = collectionView.indexPathsForSelectedItems?.first?.row {
            controller?.astro = astros[row]
        }
    return controller
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let diskCapacity = 500 * 1024 * 1024
        URLCache.shared = URLCache(memoryCapacity: URLCache.shared.memoryCapacity, diskCapacity: diskCapacity, diskPath: nil)
        print(NSHomeDirectory())

        getInfo()   //呼叫解析API的function

//        self.collectionView!.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "Cell")

        let width = ( collectionView.bounds.width - 1 * 3 ) / 4     //塞四張圖的寬度計算
        let height = ( collectionView.bounds.width - 1 * 3 ) / 4    //高度同寬度

        let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout
            flowLayout?.itemSize = CGSize(width: width, height: height)
            flowLayout?.estimatedItemSize = .zero
            flowLayout?.minimumInteritemSpacing = 1
            flowLayout?.minimumLineSpacing = 1

    }

    //設置cell
    override func numberOfSections(in collectionView: UICollectionView) -> Int { 1 }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int { astros.count }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! AstroCollectionCell

        let astro = astros[indexPath.row]
        cell.titleLabel.text = astro.title  //設定titleLabel

        DispatchQueue.global(qos: .userInteractive).async { [self] in
            if case let image = downsample(imageAt: astro.url, to: CGSize(width: 200, height: 200), scale: 0.8) {
                DispatchQueue.main.async {
                    cell.showImg.image = image
                }
            }
        }
        return cell

        //不使用縮圖方法
//        DispatchQueue.global(qos: .userInteractive).async {
//            let imageData = NSData(contentsOf: astro.url)
//            if let image = UIImage(data: imageData! as Data) {
//                DispatchQueue.main.async {
//                    cell.showImg.image = image
//                }
//            }
//        }

        //使用Cache, 直接在主線程載入時
//        let imageData = NSData(contentsOf: astro.url!)
//        let image = UIImage(data: imageData! as Data)
//        self.imageCache.setObject(image!, forKey: astro.url as! NSURL)
//        cell.showImg.image = image


    }

    func getInfo() {
        let urlStr = "https://raw.githubusercontent.com/cmmobile/NasaDataSet/main/apod.json"

            if let url = URL(string: urlStr) {
                URLSession.shared.dataTask(with: url) {(data, reponse, error) in
                    let decoder = JSONDecoder()
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd"
                    decoder.dateDecodingStrategy = .formatted(formatter)

                    if let data = data {
                        do {
                            let astro = try decoder.decode([Astro].self, from: data)
                            self.astros = astro

                            //如果使用Cache
//                            self.imageCache.setObject(image, forKey: url as NSURL)

                            DispatchQueue.main.async {
                                self.collectionView.reloadData()
                            }
                        } catch {
                            print(error)
                        }
                    }
                }.resume()

            }else {
                print("Invalid URL.")
            }
    }


    //縮圖方法1
    private func downsample(imageAt imageURL: URL, to pointSize: CGSize, scale: CGFloat) -> UIImage {
       let imageSourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
       let imageSource = CGImageSourceCreateWithURL(imageURL as CFURL, imageSourceOptions)!

       let maxDimentionInPixels = max(pointSize.width, pointSize.height) * scale

       let downsampledOptions = [kCGImageSourceCreateThumbnailFromImageAlways: true,
                                 kCGImageSourceShouldCacheImmediately: true,
                                 kCGImageSourceCreateThumbnailWithTransform: true,
                                 kCGImageSourceThumbnailMaxPixelSize: maxDimentionInPixels] as CFDictionary
      let downsampledImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, downsampledOptions)!

       return UIImage(cgImage: downsampledImage)
    }

    //縮圖方法2
    func resizedImage(at url: URL, for size: CGSize) -> UIImage? {
        guard let image = UIImage(contentsOfFile: url.path) else {
            return nil
        }

        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { (context) in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }


}
*/
