//
//  AstroDetailViewModel.swift
//  NewPjt_07
//
//  詳情頁的呈現邏輯：
//  - 純文字屬性（title / copyrightText）
//  - 已格式化的 attributedString（日期字距、描述行距）
//  - 給 tableView heightForRow 計算用的描述高度
//  View 端只負責呈現，不做格式化、不知道 DateFormatter。
//

import UIKit

final class AstroDetailViewModel {

    private let astro: Astro

    init(astro: Astro) {
        self.astro = astro
    }

    // MARK: - 純資料屬性

    var title: String? { astro.title }
    var imageURL: URL? { astro.durl }

    var copyrightText: String? {
        guard let cpy = astro.copyright,
              !cpy.trimmingCharacters(in: .whitespaces).isEmpty else {
            return nil
        }
        return "© \(cpy)"
    }

    // MARK: - 給 View 直接套用的 attributedString

    /// 日期：紅色、字距加大、全大寫 caption
    func dateAttributedText() -> NSAttributedString {
        let text: String
        if let date = astro.date {
            text = Self.dateFormatter.string(from: date).uppercased()
        } else {
            text = "—"
        }
        return NSAttributedString(
            string: text,
            attributes: [
                .kern: 1.5,
                .font: UIFont.systemFont(ofSize: 12, weight: .semibold),
                .foregroundColor: UIColor.systemRed
            ]
        )
    }

    /// 描述：行距 5、justified；nil/空字串回 nil
    func descriptionAttributedText() -> NSAttributedString? {
        guard let text = astro.description, !text.isEmpty else { return nil }
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineSpacing = 5
        paragraph.lineBreakMode = .byWordWrapping
        paragraph.alignment = .justified
        return NSAttributedString(
            string: text,
            attributes: [
                .paragraphStyle: paragraph,
                .font: UIFont.systemFont(ofSize: 15, weight: .regular),
                .foregroundColor: UIColor.label
            ]
        )
    }

    /// 描述在指定寬度下需要的高度（heightForRow 算 cell 高度用）。
    /// 與 descriptionAttributedText() 用同一組 attribute，計算才會跟實際渲染一致。
    func descriptionHeight(forWidth width: CGFloat) -> CGFloat {
        guard let attr = descriptionAttributedText(), width > 0 else { return 0 }
        let rect = attr.boundingRect(
            with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        )
        return ceil(rect.height)
    }

    /// 標題在指定寬度下需要的高度。
    /// 字體要跟 DetailViewCell.applyTypography 中 titleLabel.font 一致，
    /// 不然算出來的高度跟實際渲染對不上。
    func titleHeight(forWidth width: CGFloat) -> CGFloat {
        guard let text = astro.title, !text.isEmpty, width > 0 else { return 0 }
        let attr = NSAttributedString(
            string: text,
            attributes: [.font: UIFont.systemFont(ofSize: 22, weight: .bold)]
        )
        let rect = attr.boundingRect(
            with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        )
        return ceil(rect.height)
    }

    // MARK: - DateFormatter（建構成本高，整 app 共用一份）

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy MMM. dd"
        return f
    }()
}
