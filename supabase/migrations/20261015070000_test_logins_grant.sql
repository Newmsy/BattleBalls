-- The deploy script (tools/supabase_auth_config.mjs) stores the test login
-- with the project's server key, which runs as service_role. The live project
-- doesn't give service_role rights on new tables by default (the first deploy
-- got HTTP 403), so grant exactly what the script needs.
grant select, insert, update on public.test_logins to service_role;
