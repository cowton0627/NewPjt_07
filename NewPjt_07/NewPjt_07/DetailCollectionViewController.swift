//
//  DetailCollectionViewController.swift
//  NewPjt_07
//
//  整檔內容為 local-2021 分支封存版本（commit 1099172）。
//  因依賴 local-2021 的非 optional Astro struct（main 分支版本為 optional），
//  作為 active code 會 compile error，故整檔以註解形式保留作參考。
//  若要啟用，需先同步調整 AstroCollectionViewController.swift 中 Astro 的欄位定義。
//

import UIKit

/*
//
//  DetailCollectionViewController.swift
//  NewPjt_07
//  Created by 鄭淳澧 on 2021/6/22.
//

import UIKit

class DetailCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var showImg: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var cpyLabel: UILabel!
    @IBOutlet weak var desLabel: UILabel!
}

//private let reuseIdentifier = "Cell2"

class DetailCollectionViewController: UICollectionViewController {
    var astro: Astro!


    override func viewDidLoad() {
        super.viewDidLoad()

        let width = ( collectionView.bounds.width )
        let height = ( collectionView.bounds.height * 1.2)

        let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout
            flowLayout?.itemSize = CGSize(width: width, height: height)
            flowLayout?.estimatedItemSize = .zero
            flowLayout?.minimumInteritemSpacing = 1
            flowLayout?.minimumLineSpacing = 1
    }

    //設置cell
    override func numberOfSections(in collectionView: UICollectionView) -> Int { 1 }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int { 1 }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell2", for: indexPath) as! DetailCollectionViewCell

        cell.titleLabel.text = astro.title
        cell.cpyLabel.text = astro.copyright
        cell.desLabel.text = astro.description

        //不使用縮圖方法
        DispatchQueue.global(qos: .userInteractive).async { [self] in
            let imageData = NSData(contentsOf: astro.durl!)
            if let image = UIImage(data: imageData! as Data) {
                DispatchQueue.main.async {
                    cell.showImg.image = image
                }
            }
        }

        let decoder = JSONDecoder()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy MMM. dd"   //時間轉換成指定格式
        decoder.dateDecodingStrategy = .formatted(formatter)
        let dateStr = formatter.string(from: astro.date)
        cell.dateLabel.text = dateStr          //設定dateLabel

        return cell

        //使用縮圖方法1
//        DispatchQueue.global(qos: .userInteractive).async { [self] in
//            if case let image = downsample(imageAt: astro.durl!, to: CGSize(width: 400, height: 400), scale: 0.7) {
//                DispatchQueue.main.async {
//                    cell.showImg.image = image
//                }
//            }
//        }

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


}
*/
