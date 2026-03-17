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
        const { user_id, plaid_item_id } = await req.json()
        const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)

        // 1. Get access token from DB
        const { data: plaidItem, error: plaidError } = await supabase
            .from('plaid_items')
            .select('access_token')
            .eq('id', plaid_item_id)
            .single()

        if (plaidError || !plaidItem) {
            throw new Error(`Plaid item not found: ${plaidError?.message}`)
        }

        const accessToken = plaidItem.access_token

        // 2. Fetch Accounts from Plaid
        const accountsResponse = await fetch(`${PLAID_URL}/accounts/get`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                client_id: PLAID_CLIENT_ID,
                secret: PLAID_SECRET,
                access_token: accessToken,
            }),
        })

        const accountsData = await accountsResponse.json()
        if (!accountsResponse.ok) throw new Error(`Plaid accounts error: ${JSON.stringify(accountsData)}`)

        // 3. Sync Accounts to DB
        for (const plaidAcc of accountsData.accounts) {
            await supabase.from('accounts').upsert({
                user_id: user_id,
                name: plaidAcc.name,
                balance: plaidAcc.balances.current,
                symbol: mapAccountTypeToSymbol(plaidAcc.type),
                color_name: 'blue', // Default
                is_liability: ['credit', 'loan'].includes(plaidAcc.type),
                external_id: plaidAcc.account_id,
                plaid_item_id: plaid_item_id
            }, { onConflict: 'external_id' })
        }

        // 4. Fetch Transactions (Last 30 days by default)
        const now = new Date()
        const thirtyDaysAgo = new Date(now.getTime() - (30 * 24 * 60 * 60 * 1000))
        
        const transactionsResponse = await fetch(`${PLAID_URL}/transactions/get`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                client_id: PLAID_CLIENT_ID,
                secret: PLAID_SECRET,
                access_token: accessToken,
                start_date: thirtyDaysAgo.toISOString().split('T')[0],
                end_date: now.toISOString().split('T')[0],
            }),
        })

        const transactionsData = await transactionsResponse.json()
        if (!transactionsResponse.ok) throw new Error(`Plaid transactions error: ${JSON.stringify(transactionsData)}`)

        // 5. Sync Transactions to DB
        for (const plaidTx of transactionsData.transactions) {
            await supabase.from('transactions').upsert({
                user_id: user_id,
                title: plaidTx.name,
                amount: Math.abs(plaidTx.amount),
                date: plaidTx.date,
                is_income: plaidTx.amount < 0,
                category_symbol: mapPlaidCategoryToSymbol(plaidTx.category),
                external_id: plaidTx.transaction_id,
                plaid_item_id: plaid_item_id
            }, { onConflict: 'external_id' })
        }

        return new Response(JSON.stringify({ status: 'success', synced: transactionsData.transactions.length }), {
            headers: { 'Content-Type': 'application/json' },
        })

    } catch (error) {
        console.error('Sync error:', error)
        return new Response(JSON.stringify({ error: error.message }), {
            status: 500,
            headers: { 'Content-Type': 'application/json' },
        })
    }
})

function mapAccountTypeToSymbol(type: string): string {
    switch (type) {
        case 'depository': return 'building.columns.fill'
        case 'credit': return 'creditcard.fill'
        case 'loan': return 'hand.tap.fill'
        case 'investment': return 'chart.line.uptrend.xyaxis'
        default: return 'bag.fill'
    }
}

function mapPlaidCategoryToSymbol(categories: string[]): string {
    if (categories.includes('Food and Drink')) return 'fork.knife'
    if (categories.includes('Travel')) return 'airplane'
    if (categories.includes('Transfer')) return 'arrow.left.arrow.right'
    if (categories.includes('Shops')) return 'cart.fill'
    return 'questionmark.circle'
}
