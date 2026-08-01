-- 1. Enable PostGIS Extension for geospatial queries
CREATE EXTENSION IF NOT EXISTS postgis;

-- 2. Create Candidate Profiles Table
CREATE TABLE IF NOT EXISTS candidate_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    full_name TEXT NOT NULL,
    trade_role TEXT NOT NULL,
    hourly_rate TEXT NOT NULL,
    phone_number TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'available', -- 'available', 'shortlisted', 'hired', 'rejected'
    location GEOGRAPHY(POINT, 4326) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Create Spatial Index for fast distance filtering
CREATE INDEX IF NOT EXISTS candidate_profiles_location_idx 
ON candidate_profiles USING GIST (location);

-- 4. Stored Procedure for Nearby Candidate Search (RPC)
CREATE OR REPLACE FUNCTION get_nearby_candidates(
    lat DOUBLE PRECISION,
    long DOUBLE PRECISION,
    radius_km DOUBLE PRECISION
)
RETURNS TABLE (
    id UUID,
    name TEXT,
    trade_role TEXT,
    hourly_rate TEXT,
    phone TEXT,
    status TEXT,
    distance_km DOUBLE PRECISION
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        cp.id,
        cp.full_name AS name,
        cp.trade_role,
        cp.hourly_rate,
        cp.phone_number AS phone,
        cp.status,
        ROUND((ST_Distance(cp.location, ST_SetSRID(ST_MakePoint(long, lat), 4326)::geography) / 1000)::numeric, 1)::double precision AS distance_km
    FROM candidate_profiles cp
    WHERE ST_DWithin(
        cp.location, 
        ST_SetSRID(ST_MakePoint(long, lat), 4326)::geography, 
        radius_km * 1000
    )
    ORDER BY distance_km ASC;
END;
$$;
