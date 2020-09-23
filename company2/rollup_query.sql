-- Calculate deltas and filter as needed
WITH time_delta_calculation AS
(
SELECT
		t.external_client_id,
		m.track_id,
		m.station_id,
		m.stream_match_time,
		m.track_match_time,
        m.match_duration,
        t.duration as track_length,
		UNIX_TIMESTAMP(m.stream_match_time) as stream_match_time_seconds,
   		(UNIX_TIMESTAMP(m.stream_match_time) - m.track_match_time) as time_delta,
        LAG(UNIX_TIMESTAMP(m.stream_match_time) - m.track_match_time) OVER(PARTITION BY t.external_client_id, m.track_id, m.station_id ORDER BY (UNIX_TIMESTAMP(m.stream_match_time) - m.track_match_time), m.stream_match_time ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) as previous_time_delta

FROM
		api_matches_raw m
			
	LEFT JOIN	api_tracks t ON m.track_id = t.id
	LEFT JOIN	api_streams s ON m.station_id = s.station_id
        
WHERE
		t.external_client_id = 111
	AND	m.track_id = 33
    AND	m.station_id = 4
),
-- Identify group start rows based on delta and track length
group_start_calculation
AS
(
SELECT
		external_client_id,
        track_id,
        station_id,
        stream_match_time,
        track_match_time,
        stream_match_time_seconds,
        match_duration,
        time_delta,
        (time_delta - previous_time_delta > track_length OR (previous_time_delta IS NULL)) as flag_group_start

FROM
		time_delta_calculation
),
-- Define lowest delta in the group as group delta for future calculations
group_delta_calculation
AS
(
SELECT
		s.external_client_id,
        s.track_id,
        s.station_id,
        s.time_delta,
        MAX(g.group_start_delta) as group_delta
        
FROM
		group_start_calculation s
        
	LEFT JOIN	(SELECT external_client_id, track_id, station_id, time_delta as group_start_delta FROM group_start_calculation WHERE flag_group_start) g
    ON	s.external_client_id = g.external_client_id
    AND	s.track_id = g.track_id
    AND	s.station_id = g.station_id
    AND	s.time_delta >= g.group_start_delta
    
GROUP BY
	1, 2, 3, 4
),
-- Calculate time gap between matches in the same group
gap_by_group_calculation
AS
(
SELECT
		t.external_client_id,
        t.track_id,
        t.station_id,
        g.group_delta,
        t.stream_match_time,
        t.track_match_time,
        t.stream_match_time_seconds,
        LAG(t.stream_match_time_seconds) OVER(PARTITION BY g.group_delta ORDER BY t.stream_match_time_seconds ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) as previous_stream_match_time_seconds,
		LAG(t.match_duration) OVER(PARTITION BY g.group_delta ORDER BY t.stream_match_time_seconds ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) as previous_duration
        
        
FROM
		time_delta_calculation t
        
	LEFT JOIN	group_delta_calculation g USING (external_client_id, track_id, station_id, time_delta)
)
-- Totals
SELECT
		external_client_id,
        track_id,
        station_id,
        group_delta,
        MIN(stream_match_time) as stream_match_time_start,
        MAX(stream_match_time) as stream_match_time_till,
        MIN(track_match_time) as track_match_time_start,
        (MAX(stream_match_time_seconds) - MIN(stream_match_time_seconds) + MIN(track_match_time)) as track_match_time_till,
        COUNT(*) as total_matches,
        MAX(stream_match_time_seconds - COALESCE(previous_stream_match_time_seconds, stream_match_time_seconds) - COALESCE(previous_duration, 0)) as time_gap
           
FROM
		gap_by_group_calculation

GROUP BY
	1, 2, 3, 4
;