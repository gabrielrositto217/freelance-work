SELECT
		c.id,
		c.name,
		c.archived,
		pt.visits,
		conv.conversions,
		declined_stats.declined,
		pt2.payout,
		pt3.revenue
		
FROM
		campaigns c
		
	LEFT JOIN	postbacks p
	ON	c.postback_id = p.id
		
	LEFT JOIN
		(
		SELECT
				COUNT(id) as visits,
				campaign_id
				
		FROM
				page_hits
				
		WHERE
				created_at BETWEEN '2020-06-01 00:00:00' AND '2020-06-30 23:59:59'
		
		GROUP BY
			campaign_id
		)	pt
	ON	c.id = pt.campaign_id

	LEFT JOIN
		(
		SELECT
				COUNT(ph.id) as conversions,
				ph.campaign_id
				
		FROM
				page_hits ph
				
			LEFT JOIN	subscription_page_hit s
			ON	ph.id = s.page_hit_id
				
		WHERE
				s.created_at BETWEEN '2020-06-01 00:00:00' AND '2020-06-30 23:59:59'		-- Review this as it does not make sense to use with LEFT JOIN
		
		GROUP BY
			ph.campaign_id
		)	conv
	ON	c.id = conv.campaign_id
	
	LEFT JOIN
		(
		SELECT
				SUM(pb.postback_cost) as payout,
				ph.campaign_id
				
		FROM
				page_hits ph
				
			LEFT JOIN	postbacks pb
			ON	ph.postback_id = pb.id
				
		WHERE
				pb.postback_id IS NOT NULL					-- This should be removed and the join changed to INNER JOIN (same result)
			AND	ph.created_at BETWEEN '2020-06-01 00:00:00' AND '2020-06-30 23:59:59'
		
		GROUP BY
			ph.campaign_id
		)	pt2
	ON	c.id = pt2.campaign_id

	LEFT JOIN
		(
		SELECT
				COUNT(id) as declined,
				postback_id
				
		FROM
				subscriptions

		WHERE
				created_at BETWEEN '2020-06-01 00:00:00' AND '2020-06-30 23:59:59'
		
		GROUP BY
			postback_id
		)	declined_stats
	ON	p.id = declined_stats.postback_id

	LEFT JOIN
		(
		SELECT
				SUM(sm.cost) as revenue,
				ph.campaign_id
				
		FROM
				page_hits ph
				
			LEFT JOIN	postbacks pb
			ON	ph.postback_id = pb.id
			
			LEFT JOIN	subscription_page_hit sp
			ON	ph.id = sp.page_hit_id
			
			LEFT JOIN	subscriptions s
			ON	sp.subscription_id = s.id
			
			LEFT JOIN	subscription_messages sm
			ON	s.id = sm.subscription_id
				
		WHERE
				pb.postback_id IS NOT NULL					-- This should be removed and the join changed to INNER JOIN (same result)
			AND	sm.sent_at BETWEEN '2020-06-01 00:00:00' AND '2020-06-30 23:59:59'		-- Review this as it does not make sense to use with LEFT JOIN
		
		GROUP BY
			ph.campaign_id
		)	pt3
	ON	c.id = pt3.campaign_id

GROUP BY
	c.id
