-- Nội dung của Ask EmbraceAI chia theo lĩnh vực (biên bản họp, mục 3): hướng
-- dẫn dùng app, tình trạng sức khoẻ, sức khoẻ tâm lý, lối sống lành mạnh. Mỗi
-- câu hỏi chỉ gửi cho model tài liệu của lĩnh vực hợp nhất (chọn bằng bộ từ
-- khoá trong supabase/functions/_shared/ask_domains.ts), nên kệ tổng cộng dài
-- được hơn khung 4.096 token của model.
alter table public.ai_documents
  add column domain text not null default 'app'
    check (domain in ('app', 'health', 'wellbeing', 'lifestyle'));

-- Lĩnh vực mà câu hỏi được xếp vào, để nhóm nghiên cứu xem lại; null với câu
-- dừng trước bước chọn (khẩn cấp, hàng chờ đầy) và các dòng cũ.
alter table public.ai_interactions
  add column domain text
    check (domain in ('app', 'health', 'wellbeing', 'lifestyle'));
