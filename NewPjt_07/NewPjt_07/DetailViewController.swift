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
