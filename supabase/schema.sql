-- दैनंदिन हिशोब: database schema (Supabase / Postgres)
-- Supabase Dashboard → SQL Editor मध्ये एकदा चालवा.

create table public.transactions (
  user_id          uuid        not null default auth.uid() references auth.users(id) on delete cascade,
  id               text        not null check (char_length(id) between 1 and 64),
  date             date        not null,
  day              text        not null check (char_length(day) <= 20),
  transaction_type text        not null check (transaction_type in ('TAKEN','GIVEN')),
  amount           numeric(12,2) not null check (amount > 0),
  purpose          text        not null default '' check (char_length(purpose) <= 200),
  category         text        not null default '' check (char_length(category) <= 60),
  deleted          boolean     not null default false,   -- हटवलेला हिशोब: दुसऱ्या फोनवरही हटावा म्हणून खूण ठेवतो
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now(),   -- फोनवर शेवटचा बदल
  synced_at        timestamptz not null default now(),   -- server वर शेवटचा बदल (sync साठी)
  primary key (user_id, id)
);

create index transactions_sync_idx on public.transactions (user_id, synced_at);

-- server वर येणाऱ्या प्रत्येक बदलाला नवीन synced_at
create function public.touch_synced_at() returns trigger
language plpgsql set search_path = '' as $$
begin
  new.synced_at := clock_timestamp();
  return new;
end $$;

create trigger transactions_touch before insert or update on public.transactions
for each row execute function public.touch_synced_at();

-- Row Level Security: प्रत्येक व्यक्तीला फक्त स्वतःचा हिशोब
alter table public.transactions enable row level security;

create policy "own rows: select" on public.transactions for select to authenticated
  using (user_id = (select auth.uid()));
create policy "own rows: insert" on public.transactions for insert to authenticated
  with check (user_id = (select auth.uid()));
create policy "own rows: update" on public.transactions for update to authenticated
  using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
create policy "own rows: delete" on public.transactions for delete to authenticated
  using (user_id = (select auth.uid()));

revoke all on public.transactions from anon;
grant select, insert, update, delete on public.transactions to authenticated;

-- "खाते आणि सर्व हिशोब कायमचे हटवा": लॉगिन केलेली व्यक्ती फक्त स्वतःचे खाते हटवू शकते
create function public.delete_my_account() returns void
language sql security definer set search_path = '' as $$
  delete from auth.users where id = (select auth.uid());
$$;
revoke all on function public.delete_my_account() from public, anon;
grant execute on function public.delete_my_account() to authenticated;
revoke all on function public.touch_synced_at() from public, anon, authenticated;

-- वापरकर्त्याची माहिती: नाव, मोबाईल, पत्ता, ई-मेल (खाते तयार करताना भरलेली)
create table public.profiles (
  user_id    uuid primary key references auth.users(id) on delete cascade,
  full_name  text not null default '' check (char_length(full_name) <= 120),
  mobile     text not null default '' check (char_length(mobile) <= 20),
  address    text not null default '' check (char_length(address) <= 300),
  email      text,
  privacy_accepted_at timestamptz not null default now(),  -- खाते तयार करताना गोपनीयता धोरण मान्य केल्याची वेळ
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.profiles enable row level security;
create policy "own profile: select" on public.profiles for select to authenticated
  using (user_id = (select auth.uid()));
revoke all on public.profiles from anon, authenticated;
grant select on public.profiles to authenticated;

-- खाते तयार झाल्यावर / माहिती बदलल्यावर profile आपोआप भरते (app थेट या table मध्ये लिहीत नाही)
create function public.sync_profile() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  insert into public.profiles (user_id, full_name, mobile, address, email)
  values (new.id,
          left(coalesce(new.raw_user_meta_data->>'full_name', ''), 120),
          left(coalesce(new.raw_user_meta_data->>'mobile', ''), 20),
          left(coalesce(new.raw_user_meta_data->>'address', ''), 300),
          new.email)
  on conflict (user_id) do update
    set full_name = excluded.full_name, mobile = excluded.mobile, address = excluded.address,
        email = excluded.email, updated_at = now();
  return new;
end $$;
revoke all on function public.sync_profile() from public, anon, authenticated;

create trigger on_auth_user_profile
after insert or update of raw_user_meta_data, email on auth.users
for each row execute function public.sync_profile();
