//
//  DetailViewController.swift
//  NewPjt_07
//
//  詳情頁 VC。由上一頁透過 IBSegueAction 注入 viewModel。
//  storyboard 寫死 rowHeight=651.5 且 desLabel 沒有 bottom→contentView 約束，
//  改用 heightForRowAt 依描述文字量動態算高，tableView 才能捲動長描述。
//

import UIKit

class DetailViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    var viewModel: AstroDetailViewModel!

    @IBOutlet weak var detailTableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()
        detailTableView.delegate = self
        detailTableView.dataSource = self
        detailTableView.separatorStyle = .none
        detailTableView.showsVerticalScrollIndicator = false
        detailTableView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 24, right: 0)

        navigationItem.largeTitleDisplayMode = .never
    }

    func numberOfSections(in tableView: UITableView) -> Int { 1 }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { 1 }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        // storyboard 各段固定高度（拆開列出較清楚）：
        //   topMargin(11) + date(21) + spacing(15) + image(229.5) + spacing(7.5) = 284
        let topToTitle: CGFloat = 284
        //   spacing(7.5) + cpy(21) + spacing(8) = 36.5
        let titleToDesc: CGFloat = 36.5
        let bottomPadding: CGFloat = 24

        let insetWidth = tableView.bounds.width - DetailViewCell.horizontalInset * 2
        let titleHeight = viewModel.titleHeight(forWidth: insetWidth)
        let descHeight = viewModel.descriptionHeight(forWidth: insetWidth)

        return topToTitle + titleHeight + titleToDesc + descHeight + bottomPadding
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "detailViewCell",
                                                 for: indexPath) as! DetailViewCell
        cell.configure(with: viewModel)
        return cell
    }
}
