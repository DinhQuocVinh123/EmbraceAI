-- Số đo mới nhất của máy GPU, gửi kèm mỗi lần nó hỏi việc: số câu nó trả lời
-- cùng lúc và các con số của nvidia-smi (GPU bận bao nhiêu phần trăm, điện,
-- bộ nhớ, xung nhịp). Bài đo sức chứa (tools/ai-lab/capacity.mjs) đọc nó để
-- biết GPU đã làm hết sức chưa. Không chứa gì về câu hỏi.
alter table public.ai_worker_status add column stats jsonb;
