alter table public.posts
add column if not exists email text;

update public.posts as post
set email = auth_user.email
from auth.users as auth_user
where post.user_id = auth_user.id
and post.email is null;

update public.posts
set email = 'Unknown email'
where email is null;

alter table public.posts
alter column email set not null;

notify pgrst, 'reload schema';
