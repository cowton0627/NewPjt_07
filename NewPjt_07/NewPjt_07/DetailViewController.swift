//
//  DetailViewController.swift
//  NewPjt_07
//
//  Created by 鄭淳澧 on 2021/6/15.
//

import UIKit

class DetailViewCell: UITableViewCell {
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var showImg: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var cpyLabel: UILabel!
    @IBOutlet weak var desLabel: UILabel!
}

class DetailViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    var astro: Astro!
    

    @IBOutlet weak var detailTableView: UITableView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        detailTableView.delegate = self
        detailTableView.dataSource = self
        
    }
    

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "detailViewCell", for: indexPath) as! DetailViewCell
        
        cell.titleLabel.text = astro.title
        cell.cpyLabel.text = astro.copyright
        cell.desLabel.text = astro.description

        let imageData = NSData(contentsOf: astro.durl!)  //載入hdurl圖片
        let image = UIImage(data: imageData! as Data)
        cell.showImg.image = image
        
        let decoder = JSONDecoder()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy MMM. dd"   //將時間轉換成指定格式
        decoder.dateDecodingStrategy = .formatted(formatter)
        let dateStr = formatter.string(from: astro.date!)
        cell.dateLabel.text = dateStr          //設定dateLabel
        
        return cell
    }

}

// MARK: - local-2021 封存版本（註解保留，原檔來自 local-2021 分支 commit 1099172）
/*
//
//  DetailViewController.swift
//  NewPjt_07
//  Created by 鄭淳澧 on 2021/6/15.
//

import UIKit

class DetailViewCell: UITableViewCell {
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var showImg: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var cpyLabel: UILabel!
    @IBOutlet weak var desLabel: UILabel!
}

class DetailViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    var astro: Astro!

    @IBOutlet weak var detailTableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()
        detailTableView.delegate = self
        detailTableView.dataSource = self
    }

    //設置cell
    func numberOfSections(in tableView: UITableView) -> Int { 2 }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { 1 }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "detailViewCell", for: indexPath) as! DetailViewCell
        cell.titleLabel.text = astro.title
        cell.cpyLabel.text = astro.copyright
        cell.desLabel.text = astro.description


        let url = Bundle.main.url(forResource: astro.hdurl,
                                              withExtension: "tiff")!

        //使用縮圖方法2
        DispatchQueue.global(qos: .userInitiated).async { [self] in
          let image = resizedImage(at: url, for: cell.showImg.bounds.size)

          DispatchQueue.main.sync {
            UIView.transition(with: cell.showImg,
                             duration: 1.0,
                             options: [.curveEaseOut, .transitionCrossDissolve],
                             animations: { cell.showImg.image = image })
          }
        }

        let decoder = JSONDecoder()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy MMM. dd"   //時間轉換成指定格式
        decoder.dateDecodingStrategy = .formatted(formatter)
        let dateStr = formatter.string(from: astro.date)
        cell.dateLabel.text = dateStr          //設定dateLabel

        return cell


        //在主線程載入圖片, 卡主線程的情況
//                let imageData = NSData(contentsOf: astro.durl!)
//                let image = UIImage(data: imageData! as Data)
//                cell.showImg.image = image

        //在背景載入圖片, 不卡主線程的情況
//                DispatchQueue.global(qos: .userInteractive).async { [self] in
//                    let imageData = NSData(contentsOf: astro.durl!)
//                    if let image = UIImage(data: imageData! as Data) {
//                        DispatchQueue.main.async {
//                            cell.showImg.image = image
//                        }
//                    }
//                }

        //使用縮圖方法1
//                DispatchQueue.global(qos: .userInteractive).async { [self] in
//                    if case let image = downsample(imageAt: astro.durl!, to: CGSize(width: 80, height: 80), scale: 1.0)
//                        DispatchQueue.main.async {
//                                cell.showImg.image = image
//                        }
//                    }
//                }


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
