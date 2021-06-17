//
//  AstroTableViewController.swift
//  NewPjt_07
//
//  Created by 鄭淳澧 on 2021/6/15.
//

import UIKit

class AstroTableViewCell: UITableViewCell {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var photoImgView: UIImageView!
    
}

class AstroTableViewController: UITableViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        getInfo()
        
    }


    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return astros.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "astroCell", for: indexPath) as! AstroTableViewCell
        let astro = astros[indexPath.row]
        cell.titleLabel.text = astro.title
        
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
                                self.tableView.reloadData()
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
