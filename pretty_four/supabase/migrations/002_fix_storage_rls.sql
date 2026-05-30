-- 기존 너무 넓은 Storage 정책 삭제
drop policy if exists "recordings_owner_upload" on storage.objects;
drop policy if exists "recordings_owner_select" on storage.objects;
drop policy if exists "recordings_service_delete" on storage.objects;

-- 사용자별 폴더 구조: {user_id}/{session_id}.m4a
-- 업로드: 본인 폴더에만
create policy "recordings_owner_upload" on storage.objects
  for insert with check (
    bucket_id = 'recordings'
    and auth.uid() is not null
    and (storage.foldername(name))[1] = auth.uid()::text
  );

-- 조회: 본인 폴더만
create policy "recordings_owner_select" on storage.objects
  for select using (
    bucket_id = 'recordings'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

-- 삭제: 서비스 롤만 (Edge Function에서 실행)
create policy "recordings_service_delete" on storage.objects
  for delete using (bucket_id = 'recordings');
