SELECT
		a.fdiccert,
		a.max_rate_bps,
		(CASE	WHEN y.bucket_num = 1 THEN CONCAT('									< ', FLOOR(y.bucket_ceiling), ' bps')
				WHEN y.bucket_num = 2 THEN CONCAT('								', FLOOR(y.bucket_floor), ' to ', FLOOR(y.bucket_ceiling), ' bps')
				WHEN y.bucket_num = 3 THEN CONCAT('							', FLOOR(y.bucket_floor), ' to ', FLOOR(y.bucket_ceiling), ' bps')
				WHEN y.bucket_num = 4 THEN CONCAT('						', FLOOR(y.bucket_floor), ' to ', FLOOR(y.bucket_ceiling), ' bps')
				WHEN y.bucket_num = 5 THEN CONCAT('					', FLOOR(y.bucket_floor), ' to ', FLOOR(y.bucket_ceiling), ' bps')
        		WHEN y.bucket_num = 6 THEN CONCAT('				', FLOOR(y.bucket_floor), ' to ', FLOOR(y.bucket_ceiling), ' bps')
				WHEN y.bucket_num = 7 THEN CONCAT('			', FLOOR(y.bucket_floor), ' to ', FLOOR(y.bucket_ceiling), ' bps')
				WHEN y.bucket_num = 8 THEN CONCAT('		', FLOOR(y.bucket_floor), ' to ', FLOOR(y.bucket_ceiling), ' bps')
				WHEN y.bucket_num = 9 THEN CONCAT('	', FLOOR(y.bucket_floor), ' to ', FLOOR(y.bucket_ceiling), ' bps')						
				WHEN y.bucket_num = 10 THEN CONCAT('> ', FLOOR(y.bucket_floor), ' bps')
				END) as bucket_name
		
FROM
		(SELECT fdiccert, MAX(max_savings_rate * 100) as max_rate_bps FROM bankbalances WHERE newbalance > 0 GROUP BY 1) a
		
	LEFT JOIN
		(
		SELECT
				bucket_num,
				COUNT(*) as members,
				MIN(max_rate_bps) as bucket_floor,
				MAX(max_rate_bps) as bucket_ceiling
		
		FROM
			(
			SELECT
					-- Split into buckets based on banks stddev. Change the '2' for the desired minimum separation between buckets, and adjust the stddev multipliers in case they do not make sense
					(CASE	WHEN z1.max_rate_bps < (z1.median_rate_bps - (2 * ((0.4 * z1.stddev_factor) DIV 2))) THEN 1
							WHEN z1.max_rate_bps < (z1.median_rate_bps - (2 * ((0.3 * z1.stddev_factor) DIV 2))) THEN 2
							WHEN z1.max_rate_bps < (z1.median_rate_bps - (2 * ((0.2 * z1.stddev_factor) DIV 2))) THEN 3
							WHEN z1.max_rate_bps < (z1.median_rate_bps - (2 * ((0.1 * z1.stddev_factor) DIV 2))) THEN 4
							WHEN z1.max_rate_bps < (2 * (z1.median_rate_bps DIV 2)) THEN 5
							WHEN z1.max_rate_bps < (z1.median_rate_bps + (2 * ((0.1 * z1.stddev_factor) DIV 2))) THEN 6
							WHEN z1.max_rate_bps < (z1.median_rate_bps + (2 * ((0.2 * z1.stddev_factor) DIV 2))) THEN 7
							WHEN z1.max_rate_bps < (z1.median_rate_bps + (2 * ((0.3 * z1.stddev_factor) DIV 2))) THEN 8
							WHEN z1.max_rate_bps < (z1.median_rate_bps + (2 * ((0.4 * z1.stddev_factor) DIV 2))) THEN 9
							ELSE 10
							END) as bucket_num,
					z1.max_rate_bps

			FROM
				(
				SELECT
						b.fdiccert,
						b.max_rate_bps,
						x.median_rate_bps,
						t.stddev_factor
			
				FROM
						(SELECT fdiccert, MAX(max_savings_rate * 100) as max_rate_bps FROM bankbalances WHERE newbalance > 0 GROUP BY 1) b,
						(SELECT (@row_number := @row_number + 1) as row_num, b1.max_rate_bps as median_rate_bps FROM (SELECT fdiccert, MAX(max_savings_rate * 100) as max_rate_bps FROM bankbalances WHERE newbalance > 0 GROUP BY 1) b1, (SELECT @row_number := 0) x1 ORDER BY b1.max_rate_bps) x,
						(SELECT COUNT(*) as total_banks, STDDEV(b2.max_rate_bps) as stddev_factor FROM (SELECT fdiccert, MAX(max_savings_rate * 100) as max_rate_bps FROM bankbalances WHERE newbalance > 0 GROUP BY 1) b2) t
					
				WHERE
						x.row_num = CEIL(t.total_banks / 2)
				)	z1
			)	z
			
		GROUP BY
			bucket_num
		)	y
	ON	a.max_rate_bps >= y.bucket_floor
	AND	a.max_rate_bps <= y.bucket_ceiling