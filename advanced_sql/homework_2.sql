-- Soal 1
-- Kami membutuhkan data kota (selain Depok) dan 
-- alamat (kolom address) tempat customer berada (filter untuk alamat utama saja) 
-- beserta total order dari masing-masing alamat tersebut. 
-- Urutkan juga dari total order paling banyak.
SELECT
	alamat.kota,
	alamat.alamat,
	COUNT(orders.id_order) AS total_order
FROM rakamin_order AS orders
LEFT JOIN rakamin_customer_address AS alamat ON orders.id_pelanggan = alamat.id_pelanggan
WHERE alamat.kota != 'Depok'
GROUP BY alamat.kota, alamat.alamat
ORDER BY total_order DESC

-- Soal 2
-- Dari customer yang pernah melakukan order, 
-- kami ingin memberikan cashback untuk customer yang sudah menggunakan email ‘@yahoo.com’. 
-- Karena itu, kami butuh informasi customer ID, nomor telepon, metode bayar, dan TPV (Total Payment Value). 
-- Pastikan bahwa mereka bukan penipu.
SELECT
	customer.id_pelanggan,
	customer.telepon,
	customer.email, -- supaya user tahu kalau email benar-benar @yahoo.com
	orders.metode_bayar,
	SUM(orders.kuantitas * orders.harga * (1+ppn)) AS total_payment_value
FROM rakamin_order AS orders
LEFT JOIN rakamin_customer AS customer ON orders.id_pelanggan = customer.id_pelanggan
WHERE customer.email LIKE '%@yahoo.com' AND customer.penipu = 0
GROUP BY customer.id_pelanggan, customer.telepon, customer.email, orders.metode_bayar
ORDER BY customer.id_pelanggan

-- Soal 3
-- Tim UX researcher ingin mengetahui alasan dari 
-- user yang belum menggunakan digital payment method dalam pembayaran transaksinya 
-- secara kualitatif dan melakukan interview kepada user secara langsung. 
-- Mereka membutuhkan data customer berupa 
-- nama, email. nomor telepon, alamat user, metode_bayar, dan jumlah ordernya (dari table rakamin_orders), 
-- yang dibayarkan secara cash. 
-- Pastikan user sudah mengkonfirmasi nomor telepon, bukan penipu, dan masih aktif.
SELECT
	customer.nama,
	customer.email,
	customer.telepon,
	alamat.alamat,
	orders.metode_bayar,
	COUNT(orders.id_order) AS jumlah_order_cash
FROM
	rakamin_order AS orders
	LEFT JOIN rakamin_customer AS customer ON orders.id_pelanggan = customer.id_pelanggan
	LEFT JOIN rakamin_customer_address AS alamat on customer.id_pelanggan = alamat.id_pelanggan
WHERE
-- sub query untuk filter customer yang tidak pernah cashless sama sekali
	customer.id_pelanggan NOT IN (
		SELECT id_pelanggan
		FROM rakamin_order
		WHERE metode_bayar != 'cash'
	)
	AND customer.konfirmasi_telepon = 1
	AND customer.penipu = 0
	AND customer.pengguna_aktif = 1
GROUP BY customer.nama, customer.email, customer.telepon, alamat.alamat, orders.metode_bayar

-- Soal 4
-- Salah satu tantangan bisnis yang sedang dihadapi oleh RakaFood adalah untuk 
-- meningkatkan transaksi menggunakan digital payment (cahsless). 
-- Kira-kira dari data yang kita miliki, data apa yang dapat membantu business problem tersebut? 
-- Sediakan suatu query untuk bisa membantu tim-tim terkait dari RakaFood 
-- untuk bisa menjawab tantangan bisnis tersebut, 
-- kemudian jelaskan mengapa menurut Anda data hasil dari query Anda itu 
-- bisa membantu menyelesaikan business problem tersebut, 
-- yaitu untuk meningkatkan digital payment di transaksi RakaFood!
SELECT
	alamat.kota,
	CASE 
		WHEN orders.metode_bayar = 'cash' THEN 'cash'
		ELSE 'cashless' 
	END AS cash_or_cashless,
	COUNT(DISTINCT orders.id_pelanggan) AS pelanggan_unik,
	SUM(kuantitas * harga) AS total_value
FROM rakamin_order AS orders
LEFT JOIN rakamin_customer AS customer ON orders.id_pelanggan = customer.id_pelanggan
LEFT JOIN rakamin_customer_address AS alamat ON customer.id_pelanggan = alamat.id_pelanggan
GROUP BY 1,2
ORDER BY 1,2

-- Soal 5
-- Tim customer experience (CX) ingin mengoptimalkan penggunaan dompet digital dan 
-- membuat program membership untuk meningkatkan loyalitas pelanggan. 
-- Membership ini berbasis poin, setiap poin diperoleh dari 
-- total belanja minimal 1000 menggunakan dompet digital. 
-- Adapun kategori membership berbasis poin, adalah sebagai berikut: 
-- a. Total poin kurang dari 10 adalah non member 
-- b. Total poin 10 - 100 adalah bronze member 
-- c. Total poin 100 - 300 adalah silver member 
-- d. Total poin lebih dari 300 adalah gold member 
-- Tim CX membutuhkan data jumlah pelanggan di setiap kota berdasarkan kategori membershipnya.
WITH rakamin_poin AS (
	SELECT
		id_pelanggan,
		total_belanja,
		FLOOR(total_belanja / 1000) AS total_poin
	FROM (
		SELECT
			id_pelanggan,
			SUM(kuantitas * harga * (1+ppn)) AS total_belanja
		FROM rakamin_order 
		WHERE metode_bayar != 'cash'
		GROUP BY id_pelanggan
	) AS poin_agg
)
SELECT
	alamat.kota,
	CASE
		WHEN membership.total_poin < 10 THEN '0_non-member'
		WHEN membership.total_poin BETWEEN 10 AND 100 THEN '1_bronze member'
		WHEN membership.total_poin BETWEEN 101 AND 300 THEN '2_silver member' 
		WHEN membership.total_poin > 300 THEN '3_gold member'
	END AS membership_category,
	COUNT(membership.id_pelanggan) AS jumlah_member
FROM
	rakamin_customer_address AS alamat
	RIGHT JOIN rakamin_poin AS membership ON alamat.id_pelanggan = membership.id_pelanggan
GROUP BY alamat.kota, membership_category
ORDER BY alamat.kota, membership_category
