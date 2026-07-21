# Changelog

本專案的重要變更記錄於此。

## 2026-07-21（圖片管線與搜尋）

- 抽象 `ImageLoading`，collection/detail cell 可注入圖片載入器。
- 合併相同 URL 的同時下載，並讓每個 cell 可獨立取消訂閱。
- 圖片快取 cost 改以解碼後像素記憶體計算。
- 清單依日期由新到舊排序，新增標題、描述與作者搜尋。
- 加入清單 cell VoiceOver label／hint，以及狀態畫面的 Dynamic Type。

## 2026-07-21（面試作品強化）

- 新增 loading、empty、error、retry 狀態及 pull-to-refresh。
- 導入 `AstroServicing` dependency injection，讓 ViewModel 可隔離網路測試。
- 補上 HTTP status code、Content-Type 與 decoding error 處理。
- 新增 JSON decoding 與 ViewModel 狀態轉換單元測試。
- 新增 GitHub Actions 自動 build 與 test。

## 2026-07-21

### 專案識別名稱統一

- 專案由 `NewPjt_07` 更名為 `StellarAPOD`，讓名稱能直接表達「Stellar 天文圖」與 NASA APOD 的用途。
- 最外層資料夾、Xcode project、target、Swift module 與產品名稱統一為 `StellarAPOD`。
- Bundle Identifier 由 `ClcStudio.NewPjt-07` 更新為 `ClcStudio.StellarAPOD`。
- App 顯示名稱保留為較適合使用者閱讀的 `Stellar`。
- GitHub repository 更名為 `cowton0627/StellarAPOD`，並同步更新 README、clone 指令與 Git remote。

相關提交：`42615d0 Rename project to StellarAPOD`
