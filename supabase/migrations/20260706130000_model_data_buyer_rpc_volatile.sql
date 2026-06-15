-- Model Passport hotfix: buyer RPC must be VOLATILE for PostgREST.
--
-- Problem: get_listing_model_data_for_buyer was STABLE but calls
-- enqueue_vehicle_model_fetch_if_needed (INSERT/UPDATE on cache/jobs).
-- PostgREST runs STABLE RPCs in read-only transactions → error 25006.
--
-- Fix: change volatility only; body, grants, and behavior unchanged.

alter function public.get_listing_model_data_for_buyer(uuid) volatile;

notify pgrst, 'reload schema';
