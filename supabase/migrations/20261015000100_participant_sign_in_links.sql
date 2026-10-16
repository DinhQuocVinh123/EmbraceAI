-- Link đăng nhập dùng lại được, mỗi người tham gia một link. Khác link một
-- lần (magic link của Supabase, hết hạn trong vài giờ): link này sống tới khi
-- tài khoản hết hạn hoặc nhân viên tạo link mới / tắt link.
--
-- Chỉ lưu bản băm SHA-256 của mã bí mật: ai đọc được bảng này cũng không dựng
-- lại được link. Chỉ Edge Function (service role) đọc và ghi bảng.
create table public.participant_sign_in_links (
  participant_code text primary key
    references public.participants(participant_code) on delete cascade,
  secret_hash text not null check (secret_hash ~ '^[0-9a-f]{64}$'),
  created_at timestamptz not null default now(),
  created_by uuid references auth.users(id) on delete set null,
  last_used_at timestamptz
);

alter table public.participant_sign_in_links enable row level security;
revoke all on public.participant_sign_in_links from anon, authenticated;
