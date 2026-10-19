-- ReStore uses backend JWTs and Prisma, not direct client access through the Supabase Data API.
-- The backend must connect as the table owner or a role with BYPASSRLS.
DO $migration$
DECLARE
  table_name TEXT;
  api_role TEXT;
BEGIN
  FOREACH table_name IN ARRAY ARRAY['Category', 'StorePackage', 'StoreSubscription',
    'StoreOrder', 'PromotionPackage', 'Promotion', 'PromotionOrder']
  LOOP
    EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY', table_name);
    EXECUTE format('REVOKE ALL ON TABLE public.%I FROM PUBLIC', table_name);
    FOREACH api_role IN ARRAY ARRAY['anon', 'authenticated']
    LOOP
      IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = api_role) THEN
        EXECUTE format('REVOKE ALL ON TABLE public.%I FROM %I', table_name, api_role);
      END IF;
    END LOOP;
  END LOOP;
END
$migration$;
