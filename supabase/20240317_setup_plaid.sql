-- Create plaid_items table to store access tokens securely
CREATE TABLE IF NOT EXISTS public.plaid_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    access_token TEXT NOT NULL,
    item_id TEXT NOT NULL,
    institution_name TEXT,
    status TEXT DEFAULT 'active',
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Enable RLS
ALTER TABLE public.plaid_items ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Users can view their own plaid items" 
    ON public.plaid_items FOR SELECT 
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own plaid items" 
    ON public.plaid_items FOR INSERT 
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own plaid items" 
    ON public.plaid_items FOR UPDATE 
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own plaid items" 
    ON public.plaid_items FOR DELETE 
    USING (auth.uid() = user_id);

-- Ensure accounts and transactions tables have external_id for syncing
ALTER TABLE public.accounts ADD COLUMN IF NOT EXISTS external_id TEXT UNIQUE;
ALTER TABLE public.transactions ADD COLUMN IF NOT EXISTS external_id TEXT UNIQUE;
ALTER TABLE public.accounts ADD COLUMN IF NOT EXISTS plaid_item_id UUID REFERENCES public.plaid_items(id) ON DELETE CASCADE;
ALTER TABLE public.transactions ADD COLUMN IF NOT EXISTS plaid_item_id UUID REFERENCES public.plaid_items(id) ON DELETE CASCADE;

-- INDEX for faster syncing
CREATE INDEX IF NOT EXISTS idx_accounts_external_id ON public.accounts(external_id);
CREATE INDEX IF NOT EXISTS idx_transactions_external_id ON public.transactions(external_id);
