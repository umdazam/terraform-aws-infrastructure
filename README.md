## Part 4 & 5: PostgreSQL Database

Created two PostgreSQL tables:
- hotel_bookings
- booking_events

Seed data:
- 120 hotel bookings
- 4 organizations
- 5 cities
- 4 booking statuses
- 40 booking events

### Index optimization

Created a composite covering index:

CREATE INDEX idx_hotel_bookings_city_created_at
ON hotel_bookings (city, created_at)
INCLUDE (org_id, status, amount);

The city column supports equality filtering, while created_at supports date-range filtering. The INCLUDE columns support the aggregation and may allow an index-only scan.

An additional index on booking_events(booking_id) improves booking event lookups.
