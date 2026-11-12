
INSERT INTO hotel_bookings (
    org_id,
    hotel_id,
    city,
    checkin_date,
    checkout_date,
    amount,
    status,
    created_at
)
SELECT
    CASE (i % 4)
        WHEN 0 THEN '11111111-1111-1111-1111-111111111111'::UUID
        WHEN 1 THEN '22222222-2222-2222-2222-222222222222'::UUID
        WHEN 2 THEN '33333333-3333-3333-3333-333333333333'::UUID
        ELSE '44444444-4444-4444-4444-444444444444'::UUID
    END,
    'HOTEL-' || LPAD(i::TEXT, 3, '0'),
    CASE (i % 5)
        WHEN 0 THEN 'delhi'
        WHEN 1 THEN 'mumbai'
        WHEN 2 THEN 'bangalore'
        WHEN 3 THEN 'hyderabad'
        ELSE 'chennai'
    END,
    CURRENT_DATE + (i % 90),
    CURRENT_DATE + (i % 90) + 2,
    (1000 + i * 125.50)::NUMERIC(12,2),
    CASE (i % 4)
        WHEN 0 THEN 'confirmed'
        WHEN 1 THEN 'cancelled'
        WHEN 2 THEN 'pending'
        ELSE 'completed'
    END,
    CURRENT_TIMESTAMP - (i % 60) * INTERVAL '1 day'
FROM generate_series(1, 120) AS series(i);

INSERT INTO booking_events (
    booking_id,
    event_type,
    payload,
    created_at
)
SELECT
    id,
    CASE
        WHEN status = 'confirmed' THEN 'booking_confirmed'
        WHEN status = 'cancelled' THEN 'booking_cancelled'
        WHEN status = 'pending' THEN 'booking_pending'
        ELSE 'booking_completed'
    END,
    jsonb_build_object(
        'source', 'seed_data',
        'city', city,
        'status', status,
        'amount', amount
    ),
    created_at
FROM (
    SELECT *,
           ROW_NUMBER() OVER (ORDER BY created_at, id) AS row_num
    FROM hotel_bookings
) bookings
WHERE row_num % 3 = 0;

ANALYZE hotel_bookings;
ANALYZE booking_events;
