alter table profiles
  add column if not exists display_name text,
  add column if not exists avatar_url text,
  add column if not exists gender text,
  add column if not exists birth_date date,
  add column if not exists preferred_language text default 'vi',
  add column if not exists music_level text,
  add column if not exists favorite_genres text[],
  add column if not exists listening_moods text[],
  add column if not exists bio text,
  add column if not exists motto text,
  add column if not exists location text,
  add column if not exists country text,
  add column if not exists website_url text,
  add column if not exists updated_at timestamptz default now();

alter table songs
  add column if not exists genres text[],
  add column if not exists moods text[];