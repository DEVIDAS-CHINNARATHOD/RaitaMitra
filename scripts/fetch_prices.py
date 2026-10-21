"""Bounded manual source fetch. No API credentials are written to disk.

Use DATA_GOV_API_KEY for an account key. Without it, only the public portal's
10-record sample key is used. Run import_data.py after reviewing the output.
"""
import argparse
import datetime as dt
import json
import os
from pathlib import Path
import re
import subprocess

RESOURCE='9ef84268-d588-465a-a308-a864a43d0070'
SAMPLE='579b464db66ec23bdd000001cdd3946e44ce4aad7209ff7b23ac571b'

def value(row, title, lower):
    return row.get(title, row.get(lower))

def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('--district', required=True)
    parser.add_argument('--market', help='Optional mandi name to narrow the request')
    parser.add_argument('--date', help='Source report date, DD/MM/YYYY')
    parser.add_argument('--pages', type=int, default=1, choices=range(1,11))
    args=parser.parse_args()
    key=os.environ.get('DATA_GOV_API_KEY',SAMPLE)
    records=[]
    for page in range(args.pages):
        params={'api-key':key,'format':'json','limit':'10','offset':str(page*10),'filters[state.keyword]':'Karnataka','filters[district]':args.district}
        if args.market:params['filters[market]']=args.market
        command=['curl','-4','--silent','--connect-timeout','8','--max-time','20','--get',f'https://api.data.gov.in/resource/{RESOURCE}']
        for name,value in params.items():command+=['--data-urlencode',name+'='+value]
        result=subprocess.run(command,capture_output=True,text=True)
        if result.returncode:
            raise SystemExit('Source request failed. No credentials or request URL are logged.')
        try:payload=json.loads(result.stdout)
        except ValueError:raise SystemExit('Source returned a non-JSON response.')
        page_rows=payload.get('records')
        if not isinstance(page_rows,list):raise SystemExit('Source rejected the request or returned an unexpected schema.')
        if any(value(r,'State','state')!='Karnataka' or value(r,'District','district')!=args.district for r in page_rows):raise SystemExit('Source filter was not respected; refusing to save mixed data.')
        if args.market and any(value(r,'Market','market')!=args.market for r in page_rows):raise SystemExit('Market filter was not respected; refusing to save mixed data.')
        if args.date:
            page_rows=[r for r in page_rows if value(r,'Arrival_Date','arrival_date')==args.date]
        records.extend(page_rows)
        if len(page_rows)<10:break
    slug=re.sub('[^a-z0-9]+','-',args.district.lower()).strip('-')
    stamp=dt.datetime.now(dt.timezone.utc).strftime('%Y%m%dT%H%M%SZ')
    directory=Path(__file__).resolve().parent.parent/'data/source'
    directory.mkdir(parents=True,exist_ok=True)
    path=directory/f'{slug}-{stamp}.json'
    path.write_text(json.dumps({'resource_id':RESOURCE,'fetched_at':dt.datetime.now(dt.timezone.utc).isoformat(),'partial':True,'records':records},ensure_ascii=False,indent=2))
    print(json.dumps({'file':path.name,'records':len(records),'markets':sorted({value(r,'Market','market') for r in records if value(r,'Market','market')}),'report_dates':sorted({value(r,'Arrival_Date','arrival_date') for r in records if value(r,'Arrival_Date','arrival_date')})}))

if __name__=='__main__':main()
