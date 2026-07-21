# 面試展示改善路線

這份文件記錄 StellarAPOD 作為 iOS 面試作品時的改善方向。原則是先補齊工程可信度，再增加功能。

## P0：展示前優先完成

- 加入 loading、empty、error 三種明確畫面狀態；錯誤畫面提供「重試」，不要只顯示一次性 alert。
- 驗證 HTTP status code 與 MIME type，保留底層 decoding error，讓錯誤可診斷。
- 對 `AstroService` 與 `ImageLoader` 做 dependency injection，避免 ViewModel 綁死 singleton。
- 加入 unit tests：成功解碼、格式錯誤、網路錯誤、ViewModel 狀態轉換與日期顯示。
- README 放入真實截圖或 30–60 秒操作 GIF，移除 placeholder 說明，並寫清楚自己的設計決策與取捨。
- 確認專案可在乾淨環境 build，並加入 GitHub Actions 執行 build 與 tests。

## P1：強化使用體驗與技術深度

- 支援 pull-to-refresh、離線快取，以及上次成功資料的 fallback。
- 加入搜尋、日期排序或收藏，讓作品有清楚且可展示的使用情境。
- 改善 Accessibility：Dynamic Type、VoiceOver label、對比度、按鈕觸控範圍與 Reduce Motion。
- 圖片載入加入同 URL request coalescing，避免多個 cell 重複下載同一張圖；快取 cost 使用解碼後像素記憶體，而非壓縮資料大小。
- 將 URLSession、decoder 與 endpoint 抽象化，讓測試可使用 mock URLProtocol 或 fake service。

## P2：現代化方向（需能說明取捨再做）

- 逐步改用 Swift Concurrency（`async/await`、取消傳播、`@MainActor`）表達非同步流程。
- 評估用 diffable data source 改善資料更新；若資料只是一次整批載入，可保留現況並在面試時說明原因。
- 若部署版本允許，再評估 SwiftUI；不要為追新而重寫，應以能展示架構判斷與測試能力為優先。

## 面試 Demo 建議流程

1. 用 20 秒說明問題、資料來源與目標使用者。
2. 展示圖庫、圖片載入與詳情頁，刻意示範旋轉、Dark Mode 與網路失敗後重試。
3. 用架構圖說明 View → ViewModel → Service，以及 dependency injection 如何讓測試隔離網路。
4. 打開一個代表性測試，再說明圖片 downsampling、cache 與 cell reuse 的記憶體／競態考量。
5. 最後說明尚未完成的限制與下一步，展現取捨能力。

