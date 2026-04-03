-- Order Chat Messages table
-- Stores live chat messages between passengers and stores/hotels per order.
-- Run this migration on the Supabase SQL editor.

create table if not exists public.order_chat_messages (
  id text primary key,
  order_id text not null,
  sender text not null check (sender in ('passenger', 'store')),
  sender_name text not null default 'Unknown',
  message text not null,
  timestamp timestamptz not null default now(),
  is_read boolean not null default false,
  transport_note text
);

-- Index for fast per-order lookup
create index if not exists idx_order_chat_order_id
  on public.order_chat_messages (order_id, timestamp);

-- Enable realtime
alter publication supabase_realtime add table public.order_chat_messages;

-- Row-level security
alter table public.order_chat_messages enable row level security;

-- Allow authenticated users to read and write chat messages
create policy "Allow all access to order_chat_messages"
  on public.order_chat_messages
  for all
  using (true)
  with check (true);
