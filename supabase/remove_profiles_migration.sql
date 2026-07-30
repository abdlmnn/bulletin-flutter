alter table public.comments
add column if not exists email text;

update public.comments as comment
set email = auth_user.email
from auth.users as auth_user
where comment.user_id = auth_user.id
and comment.email is null;

update public.comments
set email = 'Unknown email'
where email is null;

alter table public.comments
alter column email set not null;

drop trigger if exists on_auth_user_created on auth.users;
drop function if exists public.handle_new_user();

do $$
declare
  foreign_key record;
begin
  for foreign_key in
    select
      constraint_name.conrelid::regclass as table_name,
      constraint_name.conname as constraint_name
    from pg_constraint as constraint_name
    where constraint_name.confrelid = 'public.profiles'::regclass
  loop
    execute format(
      'alter table %s drop constraint if exists %I',
      foreign_key.table_name,
      foreign_key.constraint_name
    );
  end loop;
end;
$$;

alter table public.posts
drop constraint if exists posts_user_id_fkey;

alter table public.posts
add constraint posts_user_id_fkey
foreign key (user_id) references auth.users(id) on delete cascade;

alter table public.post_images
drop constraint if exists post_images_user_id_fkey;

alter table public.post_images
add constraint post_images_user_id_fkey
foreign key (user_id) references auth.users(id) on delete cascade;

alter table public.comments
drop constraint if exists comments_user_id_profiles_fkey;

alter table public.comments
drop constraint if exists comments_user_id_fkey;

alter table public.comments
add constraint comments_user_id_fkey
foreign key (user_id) references auth.users(id) on delete cascade;

alter table public.comment_images
drop constraint if exists comment_images_user_id_fkey;

alter table public.comment_images
add constraint comment_images_user_id_fkey
foreign key (user_id) references auth.users(id) on delete cascade;

drop policy if exists "Profiles are publicly readable"
on public.profiles;

drop table if exists public.profiles;

notify pgrst, 'reload schema';
