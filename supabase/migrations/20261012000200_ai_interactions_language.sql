-- Ask EmbraceAI trả lời theo ngôn ngữ app đang dùng. Nhật ký ghi lại ngôn ngữ
-- đó, và với câu hỏi tiếng Việt thì kèm bản dịch tiếng Anh do model viết, để
-- nhóm nghiên cứu đọc được người tham gia đã hỏi gì.
alter table public.ai_interactions
  add column language text not null default 'en'
    check (language in ('en', 'vi')),
  add column question_english text
    check (char_length(question_english) <= 1000);
