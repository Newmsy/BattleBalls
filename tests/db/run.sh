#!/usr/bin/env bash
# Applies the Supabase migrations to a throwaway Postgres database and runs the
# SQL tests against them. Needs psql and DATABASE_URL pointing at an empty
# database the caller may drop and recreate objects in.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
psql_() { psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -q -o /dev/null "$@"; }
psql_ -f "$here/supabase_stub.sql"
for m in "$here"/../../supabase/migrations/*.sql; do
  echo "migrate $(basename "$m")"
  psql_ -f "$m"
done
for t in "$here"/test_*.sql; do
  echo "test $(basename "$t")"
  psql_ -f "$t"
done
echo "All database tests passed."
