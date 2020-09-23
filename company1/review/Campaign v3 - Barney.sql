SELECT 
    c.name as 'Campaign Name',
    pt.visits as 'Total Visits',
    conv.subscriptions as 'Subscriptions',
    CONCAT(round(conv.subscriptions / pt.visits,2),'%') as 'Conversion Rate',
    postbacks.postback_sent as 'Postback Sent',
    postbacks.postback_declined as 'Postback Declined',
    pt2.payout as 'Traffic Payout', -- NOTE: This is pulling local revenue cost from the campaign cost and is not consistent with the value below 
    pt3.revenue as 'Revenue', -- NOTE: This is pulling USD revenue and is inconsistent with above
    (pt3.revenue - pt2.payout) as 'Profit', -- NOTE: With two different currency calues being used for payout and revenue this value is innacurate
    round((pt2.payout / pt.visits) * 1000,2) as 'ePCM' -- NOTE: As above calculates will be incorrect due to currency mismatch
FROM
    campaigns c
        inner JOIN
    (SELECT 
        COUNT(id) AS visits, campaign_id
    FROM
        page_hits
    WHERE
        created_at BETWEEN '2020-07-01 00:00:00' AND '2020-07-02 23:59:59'
    GROUP BY campaign_id) pt ON c.id = pt.campaign_id
        LEFT JOIN
    (SELECT 
        COUNT(id) AS subscriptions, campaign_id
	FROM
		subscriptions s 
    WHERE
        created_at BETWEEN '2020-07-01 00:00:00' AND '2020-07-02 23:59:59'
    GROUP BY campaign_id) conv ON c.id = conv.campaign_id
        LEFT JOIN
  (SELECT 
        SUM(c.cost) AS payout, s.campaign_id
    FROM
        postback_history ph
	left join subscriptions s on ph.subscription_id = s.id
    LEFT JOIN campaigns c ON s.campaign_id = c.id
    WHERE
		s.campaign_id IS NOT NULL
	AND
		ph.created_at BETWEEN '2020-07-01 00:00:00' AND '2020-07-02 23:59:59'
	AND
		ph.skimmed = 0
    GROUP BY s.campaign_id)  pt2 ON c.id = pt2.campaign_id
        LEFT JOIN
    (SELECT 
		COUNT(CASE WHEN ph.skimmed = 0 THEN ph.id END) as postback_sent,
		COUNT(CASE WHEN ph.skimmed = 1 THEN ph.id END) as postback_declined,
		s.campaign_id
    FROM
        postback_history ph
	left join subscriptions s on ph.subscription_id = s.id
    WHERE
        ph.created_at BETWEEN '2020-07-01 00:00:00' AND '2020-07-02 23:59:59'
    GROUP BY s.campaign_id) postbacks ON c.id = postbacks.campaign_id
        LEFT JOIN
       (SELECT 
        SUM(sm.cost) AS revenue, s.campaign_id
    FROM
        subscription_messages sm
    LEFT JOIN subscriptions s ON sm.subscription_id = s.id
    WHERE
		sm.sent_at BETWEEN '2020-07-01 00:00:00' AND '2020-07-02 23:59:59'
	and
		sm.status = 1
    GROUP BY s.campaign_id) pt3 ON c.id = pt3.campaign_id
where c.archived = 0 and c.active = 1
GROUP BY c.id
