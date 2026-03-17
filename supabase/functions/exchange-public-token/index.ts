import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const PLAID_CLIENT_ID = Deno.env.get('PLAID_CLIENT_ID')
const PLAID_SECRET = Deno.env.get('PLAID_SECRET')
const PLAID_ENV = (Deno.env.get('PLAID_ENV') || 'sandbox').trim().toLowerCase()
const SUPABASE_URL = Deno.env.get('SUPABASE_URL')
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')

const PLAID_URL = PLAID_ENV === 'sandbox' 
    ? 'https://sandbox.plaid.com' 
    : 'https://production.plaid.com'

serve(async (req) => {
    try {
        const { public_token, user_id } = await req.json()

        if (!public_token || !user_id) {
            return new Response(JSON.stringify({ error: 'Missing public_token or user_id' }), { status: 400 })
        }

        console.log(`[Plaid] Exchanging token for user: ${user_id} in ${PLAID_ENV}`)

        // 1. Exchange public token for access token
        const plaidResponse = await fetch(`${PLAID_URL}/item/public_token/exchange`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                client_id: PLAID_CLIENT_ID,
                secret: PLAID_SECRET,
                public_token: public_token,
            }),
        })

        const plaidData = await plaidResponse.json()
        
        if (!plaidResponse.ok) {
            console.error('[Plaid] Exchange Error:', JSON.stringify(plaidData, null, 2))
            return new Response(JSON.stringify({ 
                error: 'Plaid exchange failed', 
                details: plaidData 
            }), { status: plaidResponse.status })
        }

        const { access_token, item_id: plaid_item_id } = plaidData

        // 2. Save access token securely in Supabase
        if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) {
            console.error('[Supabase] Missing environment variables')
            return new Response(JSON.stringify({ error: 'Server configuration error (Supabase)' }), { status: 500 })
        }

        const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)

        console.log(`[Database] Saving access_token for user: ${user_id}`)

        const { data: dbData, error: dbError } = await supabase
            .from('plaid_items')
            .insert({
                user_id: user_id,
                access_token: access_token,
                item_id: plaid_item_id,
                status: 'active'
            })
            .select()
            .single()

        if (dbError) {
            console.error('[Database] Error inserting into plaid_items:', dbError)
            return new Response(JSON.stringify({ error: dbError.message }), { status: 500 })
        }

        console.log('[Plaid] Token exchange and DB save success')

        // Return the UUID (dbData.id) as item_id so the App can use it for syncing
        return new Response(JSON.stringify({ status: 'success', item_id: dbData.id }), {
            headers: { 'Content-Type': 'application/json' },
            status: 200
        })

    } catch (error) {
        console.error('[Server] Fatal Error:', error)
        return new Response(JSON.stringify({ error: error.message }), {
            status: 500,
            headers: { 'Content-Type': 'application/json' },
        })
    }
})
