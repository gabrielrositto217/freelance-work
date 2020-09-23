SELECT
		ms.name,
		ms.id,
		messages.attempted,
		messages.total,
		messages2.successful,
		messages2.revenue,
		messages3.failed
		
FROM
		message_services ms		-- Validate this name as it is not visible in the screenshot
		
	LEFT JOIN	subscriptions s
	ON	ms.id = s.service_id
	
	LEFT JOIN
		(
		SELECT
				COUNT(sm.id) as attempted,
				SUM(sm.cost) as total,
				sm.subscription_id
				
		FROM
				subscription_messages sm
				
			LEFT JOIN	subscriptions s
			ON	sm.subscription_id = s.id
			
		WHERE
				sm.type = 2
			AND	sm.created_at BETWEEN '2020-06-01 00:00:00' AND '2020-06-30 23:59:59'
		
		GROUP BY
			s.service_id					-- This looks strange, should it group by service or individual subscription? Likely causing issues with aggregation
		)	messages
	ON	s.id = ms.subscription_id
	
	LEFT JOIN
		(
		SELECT
				COUNT(sm.id) as successful,
				SUM(sm.cost) as revenue,
				sm.subscription_id,
				s.service_id
				
		FROM
				subscription_messages sm
				
			LEFT JOIN	subscriptions s
			ON	sm.subscription_id = s.id
			
		WHERE
				sm.status = 1
			AND	sm.created_at BETWEEN '2020-06-01 00:00:00' AND '2020-06-30 23:59:59'
			
		GROUP BY
			s.service_id			
		)	messages2
	ON	ms.id = messages2.service_id				-- Looks wrong, may be duplicating data, should join on subscription+service or else the inner query should have only service
	
	LEFT JOIN
		(
		SELECT
				COUNT(sm.id) as failed,
				sm.subscription_id,
				s.service_id
				
		FROM
				subscription_messages sm
			
			LEFT JOIN	subscription s
			ON	sm.subscription_id = s.id
			
		WHERE
				sm.status = 5
			AND	sm.created_at BETWEEN '2020-06-01 00:00:00' AND '2020-06-30 23:59:59'
			
		GROUP BY
			s.service_id
		)	messages3
	ON	ms.id = messages3.service_id		-- Same as previous join
	
WHERE
		ms.account_id = ''			-- We can probably test this with one known value, the code seems to expect this as a filter/parameter
		
GROUP BY
	ms.id
