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
