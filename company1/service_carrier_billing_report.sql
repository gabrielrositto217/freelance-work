SELECT
		ms.name,
		ms.id,
		s.network_id,
		pt1.cost,
		pt2.revenue,
		pt3.bill_attempts,
		messages3.bill_failed,
		sm2.earned,
		sm2.lc_earned,
		sm2.gbp_earned,
		sm2.eur_earned,
		sm2.retry_earned,
		sm2.retry_loc_earned,
		sm2.retry_gbp_earned,
		sm2.retry_eur_earned
		
FROM
		message_services ms		-- Validate this name as it is not visible in the screenshot
		
	LEFT JOIN	subscriptions s
	ON	ms.id = s.service_id
	
	LEFT JOIN	postbacks p
	ON	s.postback_id = p.id
	
	LEFT JOIN
		(
		SELECT
				SUM(p.lifetime_earnings) as cost,
				s.postback_id
				
		FROM
				subscriptions s
				
			LEFT JOIN	postbacks p
			ON	s.postback_id = p.id
			
		WHERE
				s.postbacks_sent IS NOT NULL
			AND	s.created_at BETWEEN '2020-06-01 00:00:00' AND '2020-06-30 23:59:59'
			
		GROUP BY
			s.postback_id
		)	pt1
	ON	p.id = pt1.postback_id
	
	LEFT JOIN
		(
		SELECT
				SUM(lifetime_revenue) as revenue,
				service_id
				
		FROM
				subscriptions
				
		WHERE
				created_at BETWEEN '2020-06-01 00:00:00' AND '2020-06-30 23:59:59'
				
		GROUP BY
			s.service_id
		)	pt2
	ON	ms.id = pt2.service_id
	
	LEFT JOIN
		(
		SELECT
				COUNT(sm.id) as bill_attempts,
				sm.subscription_id
				
		FROM
				subscription_messages sm
				
			LEFT JOIN	subscriptions s
			ON	sm.subscription_id = s.id				-- This join is not required as nothing from 'subscriptions' table is used in the SQL
			
		WHERE
				sm.type = 2
			AND	sm.status <> 6
			AND	sm.created_at BETWEEN '2020-06-01 00:00:00' AND '2020-06-30 23:59:59'
			
		GROUP BY
			sm.subscription_id
		)	pt3
	ON	s.id = pt3.subscription_id
	
	LEFT JOIN
		(
		SELECT
				subscription_id,
				COUNT(id) as count,
				SUM(local_currency_cost) as lc_earned,
				SUM(cost) as earned,
				SUM(gbp_cost) as gbp_earned,
				SUM(eur_cost) as eur_earned,
				SUM(CASE WHEN retry_count > 0 THEN local_currency_cost ELSE 0 END) as retry_lc_earned,
				SUM(CASE WHEN retry_count > 0 THEN cost ELSE 0 END) as retry_earned,
				SUM(CASE WHEN retry_count > 0 THEN gbp_cost ELSE 0 END) as retry_gbp_earned,
				SUM(CASE WHEN retry_count > 0 THEN eur_cost ELSE 0 END) as retry_eur_earned
				
		FROM
				subscription_messages
				
		WHERE
				type = 2
			AND	status = 1
			AND	sent_at BETWEEN '2020-06-01 00:00:00' AND '2020-06-30 23:59:59'
			AND	account_id = ''		-- We can probably test this with one known value, the code seems to expect this as a filter/parameter. This can be done in a better way by adding the account ID to the field list and keeping the filter in only one place.

		GROUP BY
			subscription_id
		)	sm2
	ON	s.id = sm2.subscription_id
	
	LEFT JOIN
		(
		SELECT
				COUNT(id) as bill_failed,
				subscription_id
				
		FROM
				subscription_messages
				
		WHERE
				status = 5
			AND	created_at BETWEEN '2020-06-01 00:00:00' AND '2020-06-30 23:59:59'
			
		GROUP BY
			subscription_id
		)	messages3
	ON	s.id = messages3.subscription_id
	
WHERE
		ms.type IN ('OptIn', 'Interval', 'UKAlert', 'Scheduled')		-- Validate these as they seem to be code-declared constants
	AND	ms.account_id = ''		-- We can probably test this with one known value, the code seems to expect this as a filter/parameter

GROUP BY
	ms.id, s.service_id
