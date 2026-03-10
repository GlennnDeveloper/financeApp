import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const PLAID_CLIENT_ID = Deno.env.get('PLAID_CLIENT_ID')
const PLAID_SECRET = Deno.env.get('PLAID_SECRET')
const PLAID_ENV = Deno.env.get('PLAID_ENV') || 'sandbox'
const SUPABASE_URL = Deno.env.get('SUPABASE_URL')
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')

const PLAID_URL = `https://${PLAID_ENV}.plaid.com`

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
        const { access_token, item_id } = data

        // 2. Save access token securely in Supabase
        // Note: In a production app, you should encrypt this token before saving!
        const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)

        // We'll store it in a private table (or just the accounts table for this demo)
        // For this demo, we'll assume we have a way to link items to users.

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
