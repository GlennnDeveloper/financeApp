import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const PLAID_CLIENT_ID = Deno.env.get('PLAID_CLIENT_ID')
const PLAID_SECRET = Deno.env.get('PLAID_SECRET')
const PLAID_ENV = (Deno.env.get('PLAID_ENV') || 'sandbox').trim().toLowerCase()
const SUPABASE_URL = Deno.env.get('SUPABASE_URL')
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')

// production.plaid.com is the only valid endpoint for both Development and Production tiers.
const PLAID_URL = PLAID_ENV === 'sandbox' 
    ? 'https://sandbox.plaid.com' 
    : 'https://production.plaid.com'

console.log(`[Plaid] Environment: ${PLAID_ENV}, using URL: ${PLAID_URL}`)

serve(async (req) => {
    try {
        const { public_token, user_id } = await req.json()

        // 1. Exchange public token for access token
        const response = await fetch(`${PLAID_URL}/item/public_token/exchange`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                client_id: PLAID_CLIENT_ID,
                secret: PLAID_SECRET,
                public_token: public_token,
            }),
        })

        const data = await response.json()
        
        if (!response.ok) {
            console.error('Plaid error:', data)
            return new Response(JSON.stringify(data), { status: response.status })
        }

        const { access_token, item_id } = data

        // 2. Save access token securely in Supabase
        const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)

        const { error: dbError } = await supabase
            .from('plaid_items')
            .insert({
                user_id: user_id,
                access_token: access_token,
                item_id: item_id,
                status: 'active'
            })

        if (dbError) {
            console.error('Database error:', dbError)
            return new Response(JSON.stringify({ error: dbError.message }), { status: 500 })
        }

        return new Response(JSON.stringify({ status: 'success', item_id }), {
            headers: { 'Content-Type': 'application/json' },
        })
    } catch (error) {
        return new Response(JSON.stringify({ error: error.message }), {
            status: 500,
            headers: { 'Content-Type': 'application/json' },
        })
    }
})
