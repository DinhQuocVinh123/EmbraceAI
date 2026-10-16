EmbraceAI model server (chạy một lần trên máy có GPU 16 GB)

1. Chép cả thư mục này sang máy desktop-8tdlosq (USB, OneDrive, hoặc tải từ
   cuộc trò chuyện với Claude).
2. Bấm đúp START-HERE.bat.
3. Ở bước 5, Windows hỏi quyền Administrator: bấm Yes (hoặc nhờ người có quyền).
4. Chờ tải model (khoảng 14 GB). Khi thấy chữ DONE màu xanh là xong.
5. Để máy luôn bật và cắm điện. Không cần đăng nhập lại sau này.

Nếu thấy FAILED màu đỏ: gửi file setup-log.txt trong thư mục này cho Claude.

Bước 2: nối model với Supabase (làm sau bước 1)
1. Deploy hàm ai-worker và migration ai_jobs lên Supabase.
2. Trên máy phát triển, chạy tools\model-server\new-key.ps1. Script tạo khoá bí
   mật mới, đặt nó vào Supabase và đóng bộ cài thành
   tools\model-server\EmbraceAI-model-server.zip.
3. Chép file zip sang máy GPU, giải nén, bấm đúp 2-CONNECT-TO-SUPABASE.bat, bấm
   Yes khi Windows hỏi quyền Administrator. Chờ chữ DONE màu xanh.
Bước này cài một chương trình chạy nền (task "EmbraceAI model worker") cứ vài
giây lại hỏi Supabase xem có câu hỏi mới không, đưa cho model trả lời rồi gửi
kết quả về. Máy GPU chỉ đi ra internet, không mở cổng nào, nên mạng của trường
không chặn được. Bộ cài cũng gỡ Funnel và Caddy của cách làm trước.
Nếu thấy FAILED màu đỏ: gửi file worker-setup-log.txt cho Claude.
Giữ kín server-key.txt và file zip có chứa nó; xoá sau khi dùng xong.
Nhật ký của chương trình chạy nền: C:\ProgramData\EmbraceAI\worker-log.txt
(không ghi nội dung câu hỏi).

Bước 3: nói thay vì gõ (làm sau bước 2)
1. Deploy hàm transcribe, ai-worker mới và migration ai_jobs_transcribe lên Supabase.
2. Đóng lại bộ cài: tools\model-server
ew-key.ps1 -KeepKey (giữ khoá đang dùng).
3. Chép zip sang máy GPU, giải nén, bấm đúp 3-ADD-SPEECH-TO-TEXT.bat, bấm Yes khi
   Windows hỏi quyền Administrator. Chờ chữ DONE màu xanh.
Bước này tải whisper.cpp (khoảng 675 MB) và model Whisper large-v3-turbo (khoảng
575 MB), chạy nó nền ở 127.0.0.1:8178 (chỉ trong máy, không mở cổng nào), thử với
một câu tiếng Việt, rồi khởi động lại chương trình chạy nền để nó nhận cả việc
chuyển giọng nói thành chữ. Whisper chiếm thêm khoảng 1 GB bộ nhớ GPU; nếu GPU
không chạy được (card quá mới cho bản CUDA này hoặc hết bộ nhớ), bộ cài tự chuyển
sang chạy bằng CPU, chậm hơn nhưng vẫn dùng được. Đoạn ghi âm bị xoá ngay sau khi
chuyển xong, nhật ký không ghi nội dung.
Nếu thấy FAILED màu đỏ: gửi file speech-setup-log.txt cho Claude.

Bộ cài làm gì:
- Cài Ollama (phần mềm chạy model) và tải model gpt-oss:20b.
- Cho Ollama nhận yêu cầu qua mạng, nhưng tường lửa chỉ mở cho các máy
  trong mạng Tailscale riêng (dải 100.64.0.0/10), không mở ra internet.
- Tắt chế độ ngủ khi cắm điện; bật Tailscale "Run unattended".
- Giữ model nằm sẵn trong GPU 24 giờ để trả lời nhanh.
- Cho Ollama trả lời 16 câu cùng lúc (OLLAMA_NUM_PARALLEL=16): khoảng 81 câu
  mỗi phút, so với 74 khi 8 câu và 42 khi từng câu một (mỗi câu hỏi một khác).
  Khi đông, khoảng 62 người hỏi cùng lúc được trả lời trong 60 giây; đo lại
  bằng tools/ai-lab/capacity.mjs sau mỗi lần đổi máy hay model. Chương trình chạy nền
  lấy việc theo đúng số này mỗi khi chạy 2-CONNECT-TO-SUPABASE.bat, nên đổi số
  thì khởi động lại Ollama rồi chạy lại file đó.
  Lưu ý: model chiếm khoảng 13 GB bộ nhớ GPU, nên nếu người khác cũng dùng
  GPU của máy này cho việc nặng, hai bên sẽ tranh nhau.
