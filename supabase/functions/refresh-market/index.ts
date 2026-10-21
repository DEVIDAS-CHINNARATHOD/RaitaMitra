import { createClient, type SupabaseClient } from 'npm:@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

const reply = (status: number, body: unknown) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });

Deno.serve(async (request) => {
  if (request.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });
  if (request.method !== 'POST') return reply(405, { message: 'POST required.' });

  const baseUrl = Deno.env.get('SUPABASE_URL');
  const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
  if (!baseUrl || !serviceKey) {
    return reply(503, { message: 'Market data service is not configured.' });
  }

  let marketId = '';
  const admin = createClient(baseUrl, serviceKey, { auth: { persistSession: false } });
  try {
    const body = await request.json();
    marketId = typeof body.market_id === 'string' ? body.market_id.trim() : '';
    if (!marketId || marketId.length > 150) {
      return reply(400, { message: 'Select a valid mandi.' });
    }

    const { data: claim, error: claimError } = await admin.rpc('rm_claim_current_refresh', {
      p_market: marketId,
    });
    if (claimError || !claim) {
      return reply(503, { message: 'Could not check the saved market data.' });
    }
    if (claim.status !== 'claimed') {
      return reply(claim.status === 'invalid' ? 400 : 200, claim);
    }

    const { data: sourceKey, error: keyError } = await admin.rpc('rm_get_data_api_key');
    if (keyError || typeof sourceKey !== 'string' || !sourceKey) {
      await finishError(admin, marketId, 'The market data connection is awaiting configuration.');
      return reply(503, { message: 'The market data connection is awaiting configuration.' });
    }

    const { data: market, error: marketError } = await admin
      .from('rm_markets')
      .select('id,name,api_name,api_district,district_id')
      .eq('id', marketId)
      .maybeSingle();
    if (marketError || !market) {
      await finishError(admin, marketId, 'The selected mandi could not be found.');
      return reply(404, { message: 'The selected mandi could not be found.' });
    }
    const { data: district } = await admin
      .from('rm_districts')
      .select('name')
      .eq('id', market.district_id)
      .maybeSingle();

    const url = new URL('https://api.data.gov.in/resource/9ef84268-d588-465a-a308-a864a43d0070');
    url.searchParams.set('api-key', sourceKey);
    url.searchParams.set('format', 'json');
    // The demo successfully uses 100-record pages. data.gov.in test keys may
    // cap each response at 10 records regardless of the requested limit.
    url.searchParams.set('limit', '100');
    url.searchParams.set('offset', '0');
    url.searchParams.set('filters[state.keyword]', 'Karnataka');
    url.searchParams.set('filters[district]', market.api_district || district?.name || '');
    url.searchParams.set('filters[market]', market.api_name || market.name);

    let upstream: Response;
    try {
      upstream = await fetch(url, {
        headers: {
          Accept: 'application/json',
          'User-Agent': 'Mozilla/5.0 (compatible; RaithaMitra/1.0)',
        },
        signal: AbortSignal.timeout(45000),
      });
    } catch (_) {
      await finishError(admin, marketId, 'data.gov.in did not respond. Saved prices are still available.');
      return reply(200, { status: 'error', message: 'data.gov.in did not respond. Saved prices are still available.' });
    }
    if (!upstream.ok) {
      // Include only the HTTP status; do not echo upstream response bodies or
      // request URLs because those can contain the API key.
      const message = `data.gov.in returned HTTP ${upstream.status}. Saved prices are still available.`;
      await finishError(admin, marketId, message);
      return reply(200, { status: 'error', message });
    }

    let payload: Record<string, unknown>;
    try {
      payload = await upstream.json();
    } catch (_) {
      await finishError(admin, marketId, 'data.gov.in returned an unreadable response.');
      return reply(200, { status: 'error', message: 'data.gov.in returned an unreadable response.' });
    }
    if (!Array.isArray(payload.records)) {
      await finishError(admin, marketId, 'data.gov.in returned an unexpected response.');
      return reply(200, { status: 'error', message: 'data.gov.in returned an unexpected response.' });
    }

    const expectedMarket = (market.api_name || market.name).trim().toLocaleLowerCase();
    const expectedDistrict = (market.api_district || district?.name || '').trim().toLocaleLowerCase();
    const records = payload.records.filter((value) => {
      if (!value || typeof value !== 'object') return false;
      const row = value as Record<string, unknown>;
      const state = String(row.state ?? row.State ?? '').trim().toLocaleLowerCase();
      const rowMarket = String(row.market ?? row.Market ?? '').trim().toLocaleLowerCase();
      const rowDistrict = String(row.district ?? row.District ?? '').trim().toLocaleLowerCase();
      return state === 'karnataka' && rowMarket === expectedMarket && rowDistrict === expectedDistrict;
    });

    const { data: result, error: finishErrorResult } = await admin.rpc('rm_finish_current_refresh', {
      p_market: marketId,
      p_records: records,
      p_error: null,
    });
    if (finishErrorResult || !result) {
      await finishError(admin, marketId, 'Could not save the market report.');
      return reply(503, { message: 'Could not save the market report. Saved prices remain available.' });
    }
    return reply(200, result);
  } catch (_) {
    if (marketId) await finishError(admin, marketId, 'Market refresh failed. Saved prices remain available.');
    return reply(503, { message: 'Market refresh failed. Saved prices remain available.' });
  }
});

async function finishError(admin: SupabaseClient, marketId: string, message: string) {
  await admin.rpc('rm_finish_current_refresh', {
    p_market: marketId,
    p_records: [],
    p_error: message,
  });
}
