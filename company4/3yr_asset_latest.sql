SELECT
		ah.call_report_date,
		ah.cert,
		ah.asset as assets_previous_3y

FROM
		qs_3y_assets ah

	INNER JOIN  (SELECT MAX(call_report_date) as latest_date FROM call_rpt_assets_liabilities) m
	ON DATE_ADD(DATE_ADD(ah.call_report_date, INTERVAL 1 DAY), INTERVAL 3 YEAR) = DATE_ADD(m.latest_date, INTERVAL 1 DAY)
