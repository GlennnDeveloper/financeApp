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
        const { user_id, plaid_item_id } = await req.json()
        
        if (!user_id || !plaid_item_id) {
            return new Response(JSON.stringify({ error: 'Missing user_id or plaid_item_id' }), { status: 400 })
        }

        const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)

        console.log(`[Sync] Starting sync for user: ${user_id}, internal item ID: ${plaid_item_id}`)

        // 1. Get access token from DB
        const { data: plaidItem, error: plaidError } = await supabase
            .from('plaid_items')
            .select('access_token, id')
            .eq('id', plaid_item_id)
            .single()

        if (plaidError || !plaidItem) {
            console.error('[Sync] Plaid item fetch error:', plaidError)
            return new Response(JSON.stringify({ 
                error: 'Plaid item not found in database', 
                details: plaidError?.message 
            }), { status: 500 })
        }

        const accessToken = plaidItem.access_token
        const internalItemId = plaidItem.id

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

        // 3. Sync Accounts & Create ID Mapping
        console.log(`[Sync] Processing ${accountsData.accounts.length} accounts...`)
        const plaidToInternalIdMap: Record<string, string> = {}

        const accountUpserts = accountsData.accounts.map(async (plaidAcc: any) => {
            const { data: savedAcc, error: accError } = await supabase.from('accounts').upsert({
                user_id: user_id,
                name: plaidAcc.name,
                balance: plaidAcc.balances.current,
                symbol: mapAccountTypeToSymbol(plaidAcc.type),
                color_name: 'blue',
                is_liability: ['credit', 'loan'].includes(plaidAcc.type),
                external_id: plaidAcc.account_id,
                plaid_item_id: internalItemId
            }, { onConflict: 'external_id' })
            .select('id, external_id')
            .single()
            
            if (accError) {
                console.error('[Sync] Account upsert error:', accError)
                const { data: existingAcc } = await supabase
                    .from('accounts')
                    .select('id')
                    .eq('external_id', plaidAcc.account_id)
                    .single()
                
                if (existingAcc) {
                    plaidToInternalIdMap[plaidAcc.account_id] = existingAcc.id
                }
            } else if (savedAcc) {
                plaidToInternalIdMap[savedAcc.external_id] = savedAcc.id
            }
        })

        await Promise.all(accountUpserts)

        // 4. Fetch Transactions (Last 30 days)
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
                options: { count: 100 }
            }),
        })

        const transactionsData = await transactionsResponse.json()
        if (!transactionsResponse.ok) throw new Error(`Plaid transactions error: ${JSON.stringify(transactionsData)}`)

        // 5. Sync Transactions with Account IDs (BATCHED)
        const txs = transactionsData.transactions || []
        console.log(`[Sync] Successfully fetched ${txs.length} transactions from Plaid`)

        const transactionsToUpsert = txs
            .map((plaidTx: any) => {
                const internalAccountId = plaidToInternalIdMap[plaidTx.account_id]
                if (!internalAccountId) {
                    console.warn(`[Sync] Skipping transaction ${plaidTx.name} because account mapping was not found.`)
                    return null
                }
                return {
                    user_id: user_id,
                    account_id: internalAccountId,
                    title: plaidTx.name,
                    amount: Math.abs(plaidTx.amount),
                    date: plaidTx.date,
                    is_income: plaidTx.amount < 0,
                    category_symbol: mapPlaidCategoryToSymbol(plaidTx.category),
                    external_id: plaidTx.transaction_id,
                    plaid_item_id: internalItemId,
                    is_recurring: false
                }
            })
            .filter((tx: any) => tx !== null)

        let successCount = 0
        if (transactionsToUpsert.length > 0) {
            const { error: batchError } = await supabase
                .from('transactions')
                .upsert(transactionsToUpsert, { onConflict: 'external_id' })

            if (batchError) {
                console.error(`[Sync] Batch transaction upsert error:`, batchError)
            } else {
                successCount = transactionsToUpsert.length
            }
        }

        console.log(`[Sync] Finished. Successfully synced ${successCount}/${txs.length} transactions.`)

        return new Response(JSON.stringify({ 
            status: 'success', 
            accounts: Object.keys(plaidToInternalIdMap).length,
            transactions: successCount 
        }), {
            headers: { 'Content-Type': 'application/json' },
            status: 200
        })

    } catch (error: any) {
        console.error('[Sync] Fatal Error:', error)
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
    const cats = categories || []
    if (cats.includes('Food and Drink')) return 'fork.knife'
    if (cats.includes('Travel')) return 'airplane'
    if (cats.includes('Transfer')) return 'arrow.left.arrow.right'
    if (cats.includes('Shops')) return 'cart.fill'
    return 'questionmark.circle'
}
