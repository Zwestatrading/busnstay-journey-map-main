-- Supabase Schema for Delivery Tracking System

-- Enable required extensions
create extension if not exists "uuid-ossp";
create extension if not exists "postgis";

-- Rider Locations - Real-time GPS tracking
create table if not exists public.rider_locations (
  rider_id uuid primary key references auth.users(id) on delete cascade,
  latitude decimal(9, 6) not null,
  longitude decimal(9, 6) not null,
  accuracy decimal(5, 2),
  heading decimal(5, 2),
  speed decimal(5, 2),
  timestamp timestamp with time zone default now(),
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now()
);

-- Create index for faster queries
create index if not exists idx_rider_locations_timestamp on public.rider_locations(timestamp desc);

-- RLS Policies for rider_locations
alter table public.rider_locations enable row level security;

create policy "Riders can update own location"
  on public.rider_locations
  for update
  using (auth.uid() = rider_id);

create policy "Riders can insert own location"
  on public.rider_locations
  for insert
  with check (auth.uid() = rider_id);

create policy "Restaurants and admins can view rider locations"
  on public.rider_locations
  for select
  using (
    auth.jwt() ->> 'user_metadata' ->> 'role' in ('restaurant', 'admin')
  );

-- Delivery Jobs
create table if not exists public.delivery_jobs (
  id uuid primary key default uuid_generate_v4(),
  order_id uuid not null references public.orders(id) on delete cascade,
  rider_id uuid not null references public.delivery_agents(user_id) on delete cascade,
  status text not null check (status in ('pending', 'accepted', 'in_transit', 'delivered', 'cancelled')) default 'pending',
  origin_stop_id uuid not null references public.stops(id),
  destination_stop_id uuid not null references public.stops(id),
  pickup_location_name text,
  delivery_location_name text,
  estimated_delivery_time timestamp with time zone,
  actual_delivery_time timestamp with time zone,
  notes text,
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now()
);

-- Indexes for delivery_jobs
create index if not exists idx_delivery_jobs_rider on public.delivery_jobs(rider_id);
create index if not exists idx_delivery_jobs_status on public.delivery_jobs(status);
create index if not exists idx_delivery_jobs_created on public.delivery_jobs(created_at desc);

-- RLS Policies for delivery_jobs
alter table public.delivery_jobs enable row level security;

create policy "Riders can view own jobs"
  on public.delivery_jobs
  for select
  using (auth.uid() = rider_id OR auth.jwt() ->> 'user_metadata' ->> 'role' = 'admin');

create policy "Riders can update own jobs"
  on public.delivery_jobs
  for update
  using (auth.uid() = rider_id OR auth.jwt() ->> 'user_metadata' ->> 'role' = 'admin');

-- Route History (for analytics)
create table if not exists public.delivery_routes (
  id uuid primary key default uuid_generate_v4(),
  job_id uuid not null references public.delivery_jobs(id) on delete cascade,
  latitude decimal(9, 6) not null,
  longitude decimal(9, 6) not null,
  accuracy decimal(5, 2),
  speed decimal(5, 2),
  heading decimal(5, 2),
  timestamp timestamp with time zone default now(),
  created_at timestamp with time zone default now()
);

-- Index for route history
create index if not exists idx_delivery_routes_job on public.delivery_routes(job_id);
create index if not exists idx_delivery_routes_timestamp on public.delivery_routes(timestamp desc);

-- Update existing tables if needed
alter table public.orders add column if not exists rider_id uuid references public.delivery_agents(user_id);
alter table public.orders add column if not exists estimated_delivery_time timestamp with time zone;
alter table public.orders add column if not exists actual_delivery_time timestamp with time zone;

-- Create function to update delivery_jobs updated_at timestamp
create or replace function public.update_delivery_jobs_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

-- Create trigger for delivery_jobs
drop trigger if exists update_delivery_jobs_updated_at on public.delivery_jobs;
create trigger update_delivery_jobs_updated_at
  before update on public.delivery_jobs
  for each row
  execute function public.update_delivery_jobs_updated_at();

-- Realtime subscriptions
alter publication supabase_realtime add table public.rider_locations;
alter publication supabase_realtime add table public.delivery_jobs;

-- Grant permissions
grant select on public.rider_locations to authenticated;
grant insert on public.rider_locations to authenticated;
grant update on public.rider_locations to authenticated;

grant select on public.delivery_jobs to authenticated;
grant update on public.delivery_jobs to authenticated;
