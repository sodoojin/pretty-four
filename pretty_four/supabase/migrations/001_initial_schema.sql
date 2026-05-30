-- 아이 프로필
create table public.children (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade not null,
  name text not null,
  birth_date date not null,
  created_at timestamptz default now() not null
);

-- 분석 세션
create table public.sessions (
  id uuid primary key default gen_random_uuid(),
  child_id uuid references public.children(id) on delete cascade not null,
  recorded_at timestamptz default now() not null,
  duration_sec integer not null,
  status text not null default 'processing'
    check (status in ('processing', 'completed', 'failed'))
);

-- 분석 결과
create table public.analysis_results (
  id uuid primary key default gen_random_uuid(),
  session_id uuid references public.sessions(id) on delete cascade not null unique,
  summary jsonb not null,
  feedbacks jsonb not null default '[]',
  raw_transcript text,
  child_age_months integer not null,
  created_at timestamptz default now() not null
);

-- RLS 활성화
alter table public.children enable row level security;
alter table public.sessions enable row level security;
alter table public.analysis_results enable row level security;

-- children 정책: 본인 데이터만
create policy "children_owner" on public.children
  for all using (auth.uid() = user_id);

-- sessions 정책: children을 통해 본인 데이터만
create policy "sessions_owner" on public.sessions
  for all using (
    exists (
      select 1 from public.children
      where children.id = sessions.child_id
        and children.user_id = auth.uid()
    )
  );

-- analysis_results 정책: sessions를 통해 본인 데이터만
create policy "results_owner" on public.analysis_results
  for all using (
    exists (
      select 1 from public.sessions
      join public.children on children.id = sessions.child_id
      where sessions.id = analysis_results.session_id
        and children.user_id = auth.uid()
    )
  );

-- Storage RLS: recordings 버킷
create policy "recordings_owner_upload" on storage.objects
  for insert with check (
    bucket_id = 'recordings' and auth.uid() is not null
  );

create policy "recordings_owner_select" on storage.objects
  for select using (
    bucket_id = 'recordings' and auth.uid() is not null
  );

create policy "recordings_service_delete" on storage.objects
  for delete using (bucket_id = 'recordings');
