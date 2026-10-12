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

## Giọng tiếng Việt

Giọng tiếng Việt không trộn vào video. Nó là một file riêng,
`assets/audio/narration_vi.m4a`. Khi người dùng chọn tiếng Việt, app tắt tiếng
video, phát file này và giữ nó khớp với vị trí của video. Làm vậy đỡ phải giữ
thêm hai video, mỗi cái khoảng 200 MB.

Giọng đọc lấy từ **VieNeu-TTS v3 Turbo**. Mô hình này có giấy phép Apache 2.0,
chạy offline bằng CPU, và những người đọc cho các giọng có sẵn đã đồng ý cho
dùng. Nó tự gắn một dấu nước không nghe thấy được để đánh dấu đây là giọng máy.
Cài một lần vào một môi trường riêng nằm ngoài repo:

```powershell
py -3.11 -m venv D:\VideoProjects\voice\venv-vieneu
D:\VideoProjects\voice\venv-vieneu\Scripts\python -m pip install vieneu
```

Mỗi khi sửa câu tiếng Việt trong `lib/data/session_script.dart`, tạo lại giọng:

```powershell
python tools\voice\extract_captions.py
$env:HF_HOME = "D:\VideoProjects\voice\hf-cache"
D:\VideoProjects\voice\venv-vieneu\Scripts\python tools\voice\synth_narration_vi.py "Kim Thanh"
```

Muốn đổi giọng thì thay tên ở cuối lệnh. Năm giọng nữ đọc truyện là Ngọc Linh,
Quỳnh Anh (giọng Bắc), Kim Thanh, Mỹ Duyên và Thục Đoan (giọng Nam). Script
đưa giọng về đúng độ to của bản tiếng Anh (−14,7 LUFS). Câu nào đọc nhanh hay
chậm bất thường sẽ được đọc lại, vì đó thường là dấu hiệu mô hình đọc sót chữ.

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
