"""Apply the initial schema and import the directory and observed API records.

Uses PGHOST/PGUSER/PGPASSWORD/PGDATABASE. Never put a database password in Dart.
Run migrations once with --migrate. Re-running the data import is safe.
"""
import argparse
import json
import os
from pathlib import Path
import re
import psycopg2
from psycopg2.extras import execute_values

ROOT = Path(__file__).resolve().parent.parent

def clean_name(value):
    return re.sub(r'[^a-z0-9]', '', re.sub(r'\s+apmc$', '', value.lower()))

def source_value(row, title, lower):
    return row.get(title, row.get(lower, ''))

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--migrate', action='store_true')
    args = parser.parse_args()
    connection = psycopg2.connect(host=os.environ['PGHOST'], user=os.environ.get('PGUSER','postgres'), password=os.environ['PGPASSWORD'], dbname=os.environ.get('PGDATABASE','postgres'), sslmode='require', connect_timeout=15)
    if args.migrate:
        for path in sorted((ROOT/'supabase/migrations').glob('*.sql')):
            with connection.cursor() as cursor:
                cursor.execute(path.read_text())
            connection.commit()
            print('Applied', path.name)
    directory = json.loads((ROOT/'assets/data/directory.json').read_text())
    with connection.cursor() as cursor:
        execute_values(cursor,'insert into public.rm_districts(id,name) values %s on conflict(id) do nothing',[(d['id'],d['name']) for d in directory['districts']])
        execute_values(cursor,'insert into public.rm_markets(id,district_id,name,api_name,api_district) values %s on conflict(id) do nothing',[(m['id'],m['district_id'],m['name'],m['api_name'],m['api_district']) for m in directory['markets']])
        district_names={d['id']:d['name'] for d in directory['districts']}
        imported=0
        all_records=[]
        aliases={}
        for path in sorted((ROOT/'data/source').glob('*.json')):
            records=json.loads(path.read_text()).get('records',[])
            for row in records:
                source_market=source_value(row,'Market','market')
                source_district=source_value(row,'District','district')
                matches=[m for m in directory['markets'] if clean_name(m['name'])==clean_name(source_market) and source_district.lower() in (district_names[m['district_id']].lower(),m['api_district'].lower())]
                if len(matches)==1:
                    aliases[matches[0]['id']]=(matches[0]['id'],source_market,source_district)
            all_records.extend(records)
        if aliases:
            execute_values(cursor,'update public.rm_markets m set api_name=v.api_name,api_district=v.api_district from (values %s) v(id,api_name,api_district) where m.id=v.id',list(aliases.values()))
        cursor.execute('select rm_private.ingest(%s::jsonb)',(json.dumps(all_records),))
        imported=cursor.fetchone()[0]
        print(json.dumps({'districts':len(directory['districts']),'directory_entries':len(directory['markets']),'imported_observations':imported}))
    connection.commit()
    connection.close()

if __name__=='__main__':
    main()
