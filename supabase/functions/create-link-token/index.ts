import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const PLAID_CLIENT_ID = Deno.env.get('PLAID_CLIENT_ID')
const PLAID_SECRET = Deno.env.get('PLAID_SECRET')
const PLAID_ENV = (Deno.env.get('PLAID_ENV') || 'sandbox').trim().toLowerCase()
const PLAID_CLIENT_NAME = Deno.env.get('PLAID_CLIENT_NAME') || 'MyFinance'
const PLAID_PRODUCTS = (Deno.env.get('PLAID_PRODUCTS') || 'transactions').split(',')
const PLAID_COUNTRY_CODES = ['US']

// production.plaid.com is the only valid endpoint for both Development and Production tiers.
// development.plaid.com is deprecated/non-existent.
const PLAID_URL = PLAID_ENV === 'sandbox' 
    ? 'https://sandbox.plaid.com' 
    : 'https://production.plaid.com'

console.log(`[Plaid] Environment: ${PLAID_ENV}, using URL: ${PLAID_URL}`)

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
                client_name: PLAID_CLIENT_NAME,
                products: PLAID_PRODUCTS,
                country_codes: PLAID_COUNTRY_CODES,
                language: 'en',
                redirect_uri: 'https://glennndeveloper.github.io/financeApp/oauth',
            }),
        })

        const data = await response.json()
        
        if (!response.ok) {
            console.error('Plaid error:', data)
            return new Response(JSON.stringify(data), { status: response.status })
        }

        return new Response(JSON.stringify({ link_token: data.link_token }), {
            headers: { 'Content-Type': 'application/json' },
        })
    } catch (error) {
        return new Response(JSON.stringify({ error: error.message }), {
            status: 500,
            headers: { 'Content-Type': 'application/json' },
        })
    }
})
