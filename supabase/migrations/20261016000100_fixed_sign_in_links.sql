-- Link đăng nhập cố định: mỗi người tham gia một link, mở lại cổng nhân viên
-- lúc nào cũng thấy đúng link đó để gửi lại. Muốn hiện lại link thì máy chủ
-- phải giữ chính mã bí mật, không chỉ bản băm như bản trước.
--
-- Bảng vẫn khoá với anon và authenticated: chỉ Edge Function (service role)
-- đọc được mã. Các link tạo theo cách cũ (nếu có) bị xoá và phải tạo lại.
delete from public.participant_sign_in_links;

alter table public.participant_sign_in_links
  drop column secret_hash,
  add column secret text not null check (secret ~ '^[A-Za-z0-9_-]{43}$');
