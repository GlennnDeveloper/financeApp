import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const PLAID_CLIENT_ID = Deno.env.get('PLAID_CLIENT_ID')
const PLAID_SECRET = Deno.env.get('PLAID_SECRET')
const PLAID_ENV = Deno.env.get('PLAID_ENV') || 'sandbox'

const PLAID_URL = `https://${PLAID_ENV}.plaid.com`

serve(async (req) => {
    try {
        const { user_id } = await req.json()

        const response = await fetch(`${PLAID_URL}/link/token/create`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                client_id: PLAID_CLIENT_ID,
                secret: PLAID_SECRET,
                user: { client_user_id: user_id },
                client_name: 'MyFinance',
                products: ['transactions'],
                country_codes: ['US'],
                language: 'en',
            }),
        })

        const data = await response.json()
        return new Response(JSON.stringify(data), {
            headers: { 'Content-Type': 'application/json' },
        })
    } catch (error) {
        return new Response(JSON.stringify({ error: error.message }), {
            status: 500,
            headers: { 'Content-Type': 'application/json' },
        })
    }
})
