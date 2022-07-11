--soal 1
SELECT
	DISTINCT kota
FROM
	rakamin_customer_address;

--soal 2
SELECT
	*
FROM
	rakamin_order
ORDER BY tanggal_pembelian DESC
LIMIT 10;

--soal 3
SELECT
	COUNT(1) as jumlah_penipu
FROM
	rakamin_customer
WHERE penipu = 1;

--soal 4
SELECT
	*,
	CASE WHEN email LIKE '%@gmail.com' THEN 'Gmail'
		WHEN email LIKE '%@yahoo.com' THEN 'Yahoo'
		WHEN email LIKE '%@outlook.com' THEN 'Outlook'
	ELSE 'Others' END AS email_platform
FROM
	rakamin_customer
WHERE (umur >= 17) AND (tanggal_registrasi BETWEEN '2013-01-01' AND '2013-06-30')
ORDER BY email_platform;

--soal 5
SELECT
	metode_bayar,
	COUNT(1) AS jumlah_transaksi,
	MIN(harga) AS spending_terendah,
	AVG(harga) AS spending_ratarata,
	MAX(harga) AS spending_tertinggi,
	SUM(harga) AS total_spending
FROM
	rakamin_order
WHERE 
	(LOWER(metode_bayar) IN ('ovo','gopay')) AND
	id_merchant IN (3, 5, 6)
GROUP BY metode_bayar;

--soal 6
SELECT
	metode_bayar,
	CASE WHEN harga*(1+ppn) < 30000 THEN 'low spending'
		WHEN harga*(1+ppn) BETWEEN 30000 AND 50000 THEN 'medium spending'
	ELSE 'high spending' END AS spending_group,
	COUNT (DISTINCT id_pelanggan) AS jumlah_customer_unik
FROM
	rakamin_order
WHERE metode_bayar != 'cash'
GROUP BY metode_bayar, spending_group;
