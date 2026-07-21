# Changelog

本專案的重要變更記錄於此。

## 2026-07-21（URLSession 邊界與日期測試）

- `AstroService` 支援注入 `URLSession` 與 endpoint，讓網路行為可使用 mock `URLProtocol` 隔離測試。
- 補齊成功回應、非 HTTP response、HTTP 錯誤、Content-Type、空資料、transport error、無效 endpoint 與 decoding error 測試。
- 日期解析與顯示固定使用 Gregorian calendar、`en_US_POSIX` locale 與 UTC，避免裝置語系或時區造成結果漂移。
- 新增詳情頁日期格式與缺少日期 placeholder 測試；完整測試套件共 17 項，全部通過。

## 2026-07-21（目錄結構標準化）

- 修正搬移時產生的 `StellarAPOD/NewPjt_07/` 錯誤巢狀目錄。
- 將 Xcode project、App source 與 tests 移到 repository 根目錄下的標準位置。
- 最終結構統一為 `StellarAPOD.xcodeproj`、`StellarAPOD/`、`StellarAPODTests/`。
- 同步更新 README 與 GitHub Actions 的 project 路徑。

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
