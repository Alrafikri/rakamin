-- Soal 1
-- Kami membutuhkan data kota (selain Depok) dan 
-- alamat (kolom address) tempat customer berada (filter untuk alamat utama saja) 
-- beserta total order dari masing-masing alamat tersebut. 
-- Urutkan juga dari total order paling banyak.
SELECT
	alamat.kota,
	alamat.alamat,
	SUM(orders.harga) AS total_order,
	COUNT(orders.id_order) AS jumlah_transaksi -- untuk menghindari miss komunikasi
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
	customer.email, -- supaya user tahu kalau email benar-benar @yahoo.com :)
	orders.metode_bayar,
	SUM(orders.kuantitas * orders.harga) AS total_payment_value
FROM rakamin_order AS orders
LEFT JOIN rakamin_customer AS customer ON orders.id_pelanggan = customer.id_pelanggan
-- LEFT JOIN pada rakamin_order digunakan untuk mendapatkan hanya customer yang pernah order
WHERE customer.email LIKE '%@yahoo.com' AND customer.penipu = 0
GROUP BY customer.id_pelanggan, customer.telepon, customer.email, orders.metode_bayar
ORDER BY metode_bayar

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
-- Sub-query untuk filter customer yang tidak pernah cashless sama sekali
	customer.id_pelanggan NOT IN (
		SELECT id_pelanggan
		FROM rakamin_order
		WHERE metode_bayar != 'cash'
	) -- kumpulkan id pelanggan yang pernah bayar cashless, lalu filter supaya id tsb tidak dipakai (NOT IN)
	AND customer.konfirmasi_telepon = 1
	AND customer.penipu = 0
	AND customer.pengguna_aktif = 1
GROUP BY customer.nama, customer.email, customer.telepon, alamat.alamat, orders.metode_bayar
ORDER BY jumlah_order_cash DESC

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
	cust.nama,
	cust.email,
-- c. Tambahkan juga informasi alamat setiap pelanggan.
	alamat.alamat,
-- b. Kemudian, gunakan fungsi agregasi yang tepat untuk menghitung jumlah pesanan
-- Query di bawah juga sebagai pengelompokkan berdasarkan metode bayar (cash or cashless)
	COUNT(CASE WHEN ro.metode_bayar = 'cash' THEN ro.id_order END) AS transaksi_cash, 
	SUM(CASE WHEN ro.metode_bayar = 'cash' THEN ro.kuantitas * ro.harga ELSE 0 END) AS jumlah_pesanan_cash,
	COUNT(CASE WHEN ro.metode_bayar != 'cash' THEN ro.id_order END) AS transaksi_cashless,
	SUM(CASE WHEN ro.metode_bayar != 'cash' THEN ro.kuantitas * ro.harga ELSE 0 END) AS jumlah_pesanan_cashless
FROM
-- a. Gabungkan Tabel rakamin_customer dan rakamin_order
	rakamin_customer AS cust
	LEFT JOIN rakamin_order AS ro ON cust.id_pelanggan = ro.id_pelanggan
	RIGHT JOIN rakamin_customer_address AS alamat ON cust.id_pelanggan = alamat.id_pelanggan
-- kelompokkan berdasarkan nama pelanggan, email (metode bayar dikelompokkan sebagai kolom, query ada di atas)
GROUP BY cust.nama, cust.email, alamat.alamat
ORDER BY transaksi_cashless ASC, transaksi_cash ASC, jumlah_pesanan_cash DESC
	

/*
PENJELASAN CODE:
Query di atas akan menampilkan nama customer, email, alamat customer, jumlah & TPV transaksi cash atau cashless.
Pengelompokkan LEFT JOIN pada rakamin cust digunakan supaya customer yang belum pernah order juga masuk dalam
tabel, sedangkan RIGHT JOIN pada rakamin cust address digunakan untuk hanya menampilkan customer yang data 
alamatnya lengkap, sehingga mudah dihubungi apabila dibutuhkan untuk keperluan KYC.

Data di-order (ASC) berdasarkan transaksi cashless dan transaksi cash, supaya customer dengan jumlah transaksi 
paling sedikit berada di baris atas (prioritas). Di-order juga berdasarkan TPV transaksi cash (DESC) untuk 
mendapatkan customer yang jumlah transaksi cashnya lebih besar dibandingkan cashless.

PENJELASAN SOLUSI:
1. Solusi untuk meningkatkan penggunaan dompet digital dapat berupa memberikan promo pembayaran dompet digital.
Promo ditujukan bagi pengguna baru yang belum pernah order sama sekali, maupun pengguna yang hanya menggunakan
cash (Row 1-45 dalam query).

2. Solusi lainnya dapat berupa melakukan survey terhadap pengguna yang transaksi cashnya lebih besar dibandingkan
transaksi cashless. Customer potensial = row 22-45, row 76-78, row 67-69. Survey digunakan untuk mencari tahu 
alasan pengguna tersebut lebih memilih menggunakan transaksi cash dibandingkan cashless. Survey dapat dikirimkan 
melalui email / aplikasi RakaFood dengan insentif berupa undian untuk mendapatkan saldo e-money.

3. Solusi lainnya bisa berupa program referral bagi customer yang telah nyaman menggunakan dompet digital. 
Customer yang potensial, seperti customer pada row 79-85, 71-75, 46-66. Customer yang telah nyaman dapat 
memberikan ulasan yang baik terhadap dompet digital, sehingga program referral sesuai untuk dijalankan pada 
customer tersebut.

ALTERNATIF:
EDA: 		https://docs.google.com/presentation/d/1B8L376tjMxNuFzaA6Gr6E0jk_wW0MN_FSFi8Mysigl8/edit?usp=sharing
Alternatif: https://www.codepile.net/pile/oAgd5La1
*/


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
		total_poin,
		CASE
			WHEN total_poin BETWEEN 10 AND 100 THEN 'bronze member'
			WHEN total_poin BETWEEN 101 AND 300 THEN 'silver member' 
			WHEN total_poin > 300 THEN 'gold member'
			ELSE 'non-member'
		END AS membership_category
	FROM (
		SELECT
			id_pelanggan,
			SUM(CASE WHEN metode_bayar != 'cash' THEN kuantitas * harga ELSE 0 END) AS total_belanja,
			FLOOR(SUM(CASE WHEN metode_bayar != 'cash' THEN kuantitas * harga ELSE 0 END)/1000) AS total_poin
		-- query di atas untuk menghitung total bayar tiap user yang cashless, kalau pakai cash dihitung 0
		-- floor pada perhitungan poin digunakan karena minimal 1000 untuk 1 poin, sehingga 999 tidak termasuk.
		FROM rakamin_order 
		GROUP BY id_pelanggan
		ORDER BY id_pelanggan
	) AS poin_agg
)
SELECT
	alamat.kota,
	COUNT(CASE WHEN membership_category = 'non-member' THEN 1 END) AS non_member,
	COUNT(CASE WHEN membership_category = 'bronze member' THEN 1 END) AS bronze_member,
	COUNT(CASE WHEN membership_category = 'silver member' THEN 1 END) AS silver_member,
	COUNT(CASE WHEN membership_category = 'gold member' THEN 1 END) AS gold_member
FROM
	rakamin_poin AS membership
	LEFT JOIN rakamin_customer_address AS alamat ON membership.id_pelanggan = alamat.id_pelanggan
GROUP BY alamat.kota
ORDER BY alamat.kota
