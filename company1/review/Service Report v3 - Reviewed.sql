SELECT 
    ms.name,
    subs.NewSubs as 'New Subscribers',
    unsubs.Unsubscribed as 'Unsubscribes',
    messages.attempted as 'Billing Attempts',
    messages.successful as 'Sucessfull Billing',
    (messages.attempted - messages.successful) as 'Failed Billing',
	
	-- Gabriel@Barney: Same remark as Campaigns report, this should be times 100 or left unhandled as a number
    CONCAT(round((messages.successful / messages.attempted),2),'%') as 'Delivery Rate',
	
	-- Gabriel@Barney: definition pending on how to do this (maybe we discussed already?), assuming ms.message_cost times whatever we use to measure traffic, let's review Thursday. Could be part of the 'messages' table
    -- Still to calculate traffic cost at service level
	
	-- Gabriel@Barney: This value can be changed to GBP or any of the other fields if desired, as long as data is reliable, the currency issue was with Campaigns table. It would be a matter of changing the 'revenue' field on line 27 to whichever field we would like to use instead of 'sm.cost'
    round(messages.revenue,2) as 'Revenue' -- NOTE: This is the USD VALUE

	-- Gabriel note: (messages.revenue - (Traffic cost once defined)) as 'Profit'
    -- still to calculate profit with math

FROM
    message_services ms
     inner JOIN
    (SELECT 
        COUNT(sm.id) AS attempted,
        COUNT(CASE WHEN sm.status = 1 THEN sm.id END) as successful,
        SUM(CASE WHEN sm.status = 1 THEN sm.cost end) AS revenue,
            s.service_id
    FROM
        subscription_messages sm
    LEFT JOIN subscriptions s ON sm.subscription_id = s.id
    WHERE
        sm.type = 2
            AND sm.created_at BETWEEN '2020-07-01 00:00:00' AND '2020-07-08 23:59:59'
    GROUP BY s.service_id) messages ON ms.id = messages.service_id
        LEFT JOIN
    (SELECT 
    COUNT(s.id) as NewSubs,
    s.service_id
    FROM
        subscriptions s
    WHERE
        s.created_at BETWEEN '2020-07-01 00:00:00' AND '2020-07-08 23:59:59'
    GROUP BY s.service_id) subs ON ms.id = subs.service_id
    LEFT JOIN
        (SELECT 
        COUNT(DISTINCT ssc.id) as Unsubscribed, 
    s.service_id
    FROM
        subscription_status_changes ssc
    LEFT JOIN subscriptions s ON ssc.subscription_id = s.id
    WHERE
        ssc.status_to IN (10 , 99)
            AND ssc.created_at BETWEEN '2020-07-01 00:00:00' AND '2020-07-08 23:59:59'
    GROUP BY s.service_id) unsubs ON ms.id = unsubs.service_id
GROUP BY ms.id
