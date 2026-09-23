# Lời đọc

Bốn script dựng dải lời đọc 8 phút từ chính kịch bản trong app, rồi trộn vào
video. Chạy từ thư mục gốc của app (`D:\EmbraceAI`).

## Đổi giọng

```powershell
python tools\voice\extract_captions.py
python tools\voice\synth_narration.py en_GB-jenny_dioco-medium
python tools\voice\mux_voice.py
python tools\voice\verify_voice.py
```

Đổi giọng = đổi tham số ở dòng thứ hai. Tải thêm giọng:

```powershell
python -m piper.download_voices --download-dir D:\VideoProjects\voice\piper_models en_US-amy-medium
```

## Vì sao chia ra bốn bước

| Script | Việc |
|---|---|
| `extract_captions.py` | Đọc 36 câu và mốc thời gian thẳng từ `lib/data/session_script.dart`. Kịch bản chỉ có một bản gốc, nên lời đọc không thể lệch khỏi chữ trên màn hình. |
| `synth_narration.py` | Đọc từng câu riêng, đặt vào đúng giây nó xuất hiện. Câu nào dài hơn khoảng trống tới câu kế thì đọc nhanh lại vừa đủ — và chỉ câu đó. |
| `mux_voice.py` | Trộn vào video, nhạc nền tự lùi khi có lời. Phần hình chỉ chép lại, không mã hoá lại. |
| `verify_voice.py` | Đo xem tiếng nói có thật sự rơi đúng mốc phụ đề không, kèm một phép đối chứng để phép đo không tự khen mình. |

## Hai chỗ dễ hỏng

**Nguồn để trộn luôn là bản câm.** Chúng nằm ở `D:\VideoProjects\voice\masters`.
Trộn đè lên file trong `assets/video/` sẽ cho ra hai giọng chồng lên nhau, và
không lấy lại được bản sạch. `mux_voice.py` luôn đọc từ `masters`, nên cứ chạy
lại bao nhiêu lần cũng được.

**Phần nặng để ngoài repo app.** Bản câm gốc, mô hình giọng và file
`narration.wav` nằm ở `D:\VideoProjects\voice`, đổi được qua biến môi trường
`EMBRACE_VOICE_DIR`. Để trong `build/` thì `flutter clean` xoá mất; để trong
`assets/` thì chúng bị đóng luôn vào APK.

## Giấy phép

Giọng hiện dùng là **piper** (MIT, mô hình mở, chạy offline). Chọn nó thay cho
`edge-tts` vì `edge-tts` gọi tới một cổng không công bố của Microsoft: nghe hay
hơn nhưng không có quyền dùng thương mại rõ ràng, nên không nên đóng vào bản
phát hành cho bệnh nhân.
