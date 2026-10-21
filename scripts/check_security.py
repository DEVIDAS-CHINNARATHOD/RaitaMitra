"""Exercise RLS inside one transaction, then roll back every fixture."""
import json
import os
import uuid
import psycopg2

c=psycopg2.connect(host=os.environ['PGHOST'],user=os.environ.get('PGUSER','postgres'),password=os.environ['PGPASSWORD'],dbname=os.environ.get('PGDATABASE','postgres'),sslmode='require',connect_timeout=15)
try:
    a,b=str(uuid.uuid4()),str(uuid.uuid4())
    with c.cursor() as q:
        q.execute('insert into auth.users(id) values(%s),(%s)',(a,b))
        q.execute('insert into public.rm_profiles(id,name) values(%s,%s),(%s,%s)',(a,'RLS test A',b,'RLS test B'))
        q.execute('set local role anon')
        q.execute('select count(*) from public.rm_profiles')
        assert q.fetchone()[0]==0, 'Anonymous profile access must return zero rows'
        q.execute('reset role')
        q.execute("select set_config('request.jwt.claims',%s,true)",(json.dumps({'sub':a,'role':'authenticated'}),))
        q.execute('set local role authenticated')
        q.execute('select id from public.rm_profiles')
        assert q.fetchall()==[(a,)], 'A user must see only their profile'
        q.execute('update public.rm_profiles set name=%s where id=%s',('Attempted update',b))
        assert q.rowcount==0, 'A user must not modify another profile'
        q.execute('savepoint price_write')
        try:
            q.execute("insert into public.rm_districts(id,name) values('rls-test','RLS test')")
            raise AssertionError('A farmer must not write the market directory')
        except psycopg2.errors.InsufficientPrivilege:
            q.execute('rollback to savepoint price_write')
    print('PASS: anonymous profiles hidden; owner-only reads and updates; directory writes denied.')
finally:
    c.rollback()
    c.close()
