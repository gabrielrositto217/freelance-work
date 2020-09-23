/* need to sanity check renveue and in particular different currencies to confirm  
*/
SELECT 
    ms.name as 'Service Name',
    ms.id,
    subs.total_subscriptions as 'Total Subs',
    subs.current_subscriptions as 'Current Subs',
    subs.active_subscriptions as 'Active Subs',
    subs.inactive_subscriptions as 'Inactive Subs',
    subs.unbilled_subscriptions as 'Unbilled Subs',
    bill.attempted_billings as 'Total Billimg Attempts',
    bill.successful_billings as 'Total Sucessful Billings',
    (bill.attempted_billings - bill.successful_billings) as 'Total Failed Billings',
    CONCAT(round((bill.successful_billings / bill.attempted_billings),2),'%') as 'Billing Sucess Rate',
    -- Here goes cost in other currencies when we have it
    CONCAT('$',c.cost_usd) as 'Total Cost USD',
    CONCAT('$',bill.revenue_usd) as 'Total Revenue USD',
    -- bill.revenue_local,
    CONCAT('£',bill.revenue_gbp) as 'Total Revenue GBP',
    CONCAT('€',bill.revenue_eur) as 'Total Revenue EUR',
    -- Here goes profit in other currencies when we have it
    CONCAT('$',(bill.revenue_usd - c.cost_usd)) as 'Total USD Profit'
    
FROM
    message_services ms
 inner JOIN
	(
	 SELECT
	s.service_id,
    COUNT(s.id) as total_subscriptions,
	COUNT(CASE WHEN s.status <> 10 THEN s.id END) as current_subscriptions,
	COUNT(CASE WHEN s.status = 6 THEN s.id END) as active_subscriptions,
	COUNT(CASE WHEN b.subscription_id IS NOT NULL AND s.status NOT IN (6, 10) THEN s.id END) as inactive_subscriptions,
	COUNT(CASE WHEN b.subscription_id IS NULL AND s.status <> 10 THEN s.id END) as unbilled_subscriptions
	FROM subscriptions s
	LEFT JOIN (SELECT DISTINCT subscription_id FROM subscription_messages WHERE type = 2 AND status = 1) b ON s.id = b.subscription_id
	GROUP BY s.service_id
	) subs ON ms.id = subs.service_id
        LEFT JOIN
      (
      SELECT 
        COUNT(sm.id) AS attempted_billings,
        COUNT(CASE WHEN sm.status = 1 THEN sm.id END) as successful_billings,
        SUM(CASE WHEN sm.status = 1 THEN sm.cost end) AS revenue_usd,
        SUM(CASE WHEN sm.status = 1 THEN sm.local_currency_cost end) AS revenue_local,
        SUM(CASE WHEN sm.status = 1 THEN sm.gbp_cost end) AS revenue_gbp,
        SUM(CASE WHEN sm.status = 1 THEN sm.eur_cost end) AS revenue_eur,
            s.service_id
    FROM
        subscription_messages sm
    LEFT JOIN subscriptions s ON sm.subscription_id = s.id
    WHERE
        sm.type = 2
    GROUP BY s.service_id  
    ) bill ON ms.id = bill.service_id
        
 LEFT JOIN
 (
 SELECT 
        SUM(c.cost) as cost_usd,
        s.service_id
    FROM
        postback_history ph
	left join subscriptions s on ph.subscription_id = s.id
    LEFT JOIN campaigns c ON s.campaign_id = c.id
    WHERE
		s.campaign_id IS NOT NULL
	AND
		ph.skimmed = 0
    GROUP BY s.service_id
    ) c ON ms.id = c.service_id
 
WHERE
    ms.type IN ('OptIn' , 'Interval', 'UKAlert', 'Scheduled')
GROUP BY ms.id
