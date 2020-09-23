SELECT
  $__timeGroupAlias(created_at,$__interval),
  count(id) AS "id",
  (CASE WHEN sm.status = 1 THEN 'Successful' ELSE 'Other' END) as status_code,
  ms.name as service_name
FROM subscription_messages sm
LEFT JOIN subscriptions s ON sm.subscription_id = s.id
LEFT JOIN message_services ms ON s.service_id = ms.id
WHERE
  $__timeFilter(created_at)
GROUP BY 1, 3, 4
ORDER BY $__timeGroup(created_at,$__interval)