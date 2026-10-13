# Submitted food catalogue lists audit — 2026-10-13

This report covers the three newly submitted lists (bread/cereals, potato crisps, and two pulse-crisp lists) together with the preceding biscuit and nuts/cake/pasta submissions. The source text files are preserved in [`submitted_catalogues_20261013`](submitted_catalogues_20261013).

A GTIN checksum only detects a mistyped digit; it does not prove that the code belongs to the named product. Product identity and full ingredients were imported only when separately corroborated. A matching brand prefix or a valid checksum is not sufficient evidence. No source list is treated as verified product data.

## Review totals

| Submitted list | Parsed rows | Checksum valid | Checksum invalid |
| --- | ---: | ---: | ---: |
| Kurabiye, bisküvi ve gofret | 200 | 3 | 197 |
| Kuruyemiş, kek ve makarna | 200 | 55 | 145 |
| Ekmek, gevrek, peynir, ayran ve dondurma | 125 | 52 | 73 |
| Patates cipsleri | 119 | 70 | 49 |
| Protein ve bakliyat cipsleri | 30 | 4 | 26 |
| Ek protein ve bakliyat cipsleri | 45 | 8 | 37 |

Total parsed rows: 719. Invalid-checksum occurrences: 527. The lists contain 24 repeated GTINs across submissions; repeated rows were not treated as independent evidence. 92 total food records are now bundled in the app (previously 77, see dated exact additions below).

## Newly added evidenced records

| GTIN | Product | Ingredient source | Separate barcode evidence |
| --- | --- | --- | --- |
| 8690787601020 | Tadım Çiğ Badem İçi 90 g | [Özel Beslenme ürün kaydı](https://www.ozelbeslenme.com/products/tadim-cig-badem-ici-90g) | [Barcode listing](https://www.ozelbeslenme.com/products/tadim-cig-badem-ici-90g) |
| 8690787601037 | Tadım Çiğ Badem İçi 180 g | [CarrefourSA ürün etiketi bilgisi](https://www.carrefoursa.com/tadim-cig-badem-180-g-p-30126004) | [Barcode listing](https://toptanexpress.com/urun/tadim-cig-badem-ici-180-gr) |
| 8690787181232 | Tadım Çiğ Karışık Kuruyemiş Naturel 75 g | [Market Karşılaştır ürün etiketi kaydı](https://marketkarsilastir.com/fiyat/8690787181232-tadim-naturel-75-g) | [Barcode listing](https://tadser.com.tr/tr/urun/Cig-Karisik-Kuruyemis-Naturel/) |
| 8690787511015 | Tadım Tadımca Fındıklı Bar 30 g | [Özel Beslenme ürün etiketi kaydı](https://www.ozelbeslenme.com/products/tadim-tadimca-findikli-bar-30g) | [Barcode listing](https://www.ozelbeslenme.com/products/tadim-tadimca-findikli-bar-30g) |
| 8690579081931 | Filiz Burgu Makarna 500 g | [CarrefourSA ürün etiketi bilgisi](https://www.carrefoursa.com/filiz-burgu-makarna-500-g-p-30097165) | [Barcode listing](https://iyas.com.tr/filiz-burgu-makarna-500-gr-11334-p-139600) |
| 8690504119050 | Ülker Hanımeller Mahlepli Tuzlu Kurabiye 81 g | [CarrefourSA ürün etiketi bilgisi](https://www.carrefoursa.com/ulker-hanimeller-mahlepli-tuzlu-kurabiye-81-g-p-30323187) | [Barcode listing](https://iyas.com.tr/ulker-hanimeller-81-gr-mahlep-tuzlu-84829-p-132026) |
| 8690698513115 | Uno Büyük Tost Ekmeği 550 g | [CarrefourSA ürün etiketi bilgisi](https://www.carrefoursa.com/uno-buyuk-tost-ekmegi-550-g-p-30298076) | [Barcode listing](https://www.hakmarexpress.com.tr/uno-buyuk-tost-ekmegi-550-gr-1032916-p) |
| 8690526069500 | Eti Lifalif Yulaf Ezmesi 500 g | [Migros ürün etiketi bilgisi](https://www.migros.com.tr/eti-lifalif-yulaf-ezmesi-500-g-p-4db752/eti-b-206) | [Barcode listing](https://www.sariyermarket.com/eti-lifalif-yulaf-ezmesi-500-gr) |
| 8690767160189 | Sütaş Ayran 1 L | [Migros ürün etiketi bilgisi](https://www.migros.com.tr/sutas-pratik-sise-ayran-1-l-p-b03f06) | [Barcode listing](https://marketkarsilastir.com/fiyat/8690767160189-sutas-pratik-sise-ayran-1-l) |
| 8690767710469 | Sütaş Labne 200 g | [Sütaş üretici ürün bilgisi](https://www.sutas.com.tr/sutas-labne-200-g) | [Barcode listing](https://www.gurmar.com.tr/sutas-labne-200-gr-3417-p) |
| 8690624101874 | Lay's Klasik Patates Cipsi Parti Boy 150 g | [Macroonline ürün etiketi bilgisi](https://www.macrocenter.com.tr/lays-klasik-patates-cipsi-parti-boy-150-g-p-4d8bb0) | [Barcode listing](https://www.ozzmarket.com/urun/lays-klasik-parti-boy-150-gr) |


The list-submitted codes for Uno and Filiz were not copied: the verified individual packs use GTIN 8690698513115 for Uno Büyük Tost 550 g and GTIN 8690579081931 for Filiz Burgu 500 g. The submitted names/formulas or codes were not silently merged. The Lay's entry was added as a separately verified 150 g product under 8690624101874; the submitted Lay's 150 g GTIN did not establish that identity. Other checked items include Tadım products whose sizes differ from supplied candidates; they are recorded as the verified size and not as barcode aliases.

Only supplied rows with a checksum-valid code appear in the appendix below. Their checksum status is not a product match; unresolved rows remain excluded. Checksum-invalid rows are preserved in the source text files and can be counted there.

## Checksum-valid submitted rows awaiting identity/formula verification

### Kurabiye, bisküvi ve gofret

| Row | Submitted GTIN | Submitted name |
|---:|---|---|
| 186 | 8699450001013 | Biscolata Nirvana Fındıklı Gofret (26g) |
| 192 | 8690526095110 | Eti Tartini Frambuazlı Turta (114g) |
| 199 | 8690526096117 | Eti Browni Intense Fındıklı (50g) |

### Kuruyemiş, kek ve makarna

| Row | Submitted GTIN | Submitted name |
|---:|---|---|
| 26 | 8691657002015 | Peyman Nutzz Taco Soslu Yer Fıstığı |
| 27 | 8691657002053 | Peyman Nutzz Barbekü Soslu Fıstık |
| 28 | 8691657002107 | Peyman Nutzz Klasik Tuzlu Fıstık |
| 29 | 8691657003111 | Peyman Bahçeden Çiğ Karışık (150g) |
| 30 | 8691657003159 | Peyman Bahçeden Ortadoğu Güneşi |
| 31 | 8691657003203 | Peyman Bahçeden Tropikal Karışım |
| 32 | 8691657004118 | Peyman Çitliyo Kara Şimşek (180g) |
| 33 | 8691657004156 | Peyman Çitliyo Klasik Tuzlu (180g) |
| 34 | 8691657004200 | Peyman Çitliyo Duble Tuzlu (180g) |
| 35 | 8691657004255 | Peyman Çitliyo Tuzsuz (150g) |
| 36 | 8691657005115 | Peyman Doritos Soslu Akşam Güneşi |
| 37 | 8691657005153 | Peyman Doritos Soslu Gece Eğlencesi |
| 38 | 8691657006112 | Peyman Doritos Soslu Kaju (130g) |
| 39 | 8691657007126 | Peyman Bahçeden Çiğ Kabak Çekirdeği |
| 40 | 8691657008116 | Peyman Doritos Soslu Leblebi (150g) |
| 41 | 8691657009120 | Peyman Bahçeden Çiğ Ceviz İçi (150g) |
| 42 | 8691657010119 | Peyman Bahçeden Çiğ Fındık İçi (150g) |
| 43 | 8691657011123 | Peyman Bahçeden Kurutulmuş Turna Yemişi |
| 44 | 8691657012113 | Peyman Bahçeden Kuru Erik Çekirdeksiz |
| 45 | 8691657013127 | Peyman Doritos Soslu Fındık (130g) |
| 89 | 8690526003115 | Eti Adora Dilim Kek Vanilyalı (40g) |
| 90 | 8690526003153 | Eti Adora Dilim Kek Kakaolu (40g) |
| 136 | 8690623011112 | Filiz Burgu Makarna (500g) |
| 137 | 8690623011129 | Filiz Fiyonk Makarna (500g) |
| 138 | 8690623011136 | Filiz Kalem Kesme (Penne) (500g) |
| 139 | 8690623011143 | Filiz Çubuk Spagetti (500g) |
| 140 | 8690623011150 | Filiz İnce Uzun Spagetti (500g) |
| 141 | 8690623011167 | Filiz Boncuk Makarna (500g) |
| 142 | 8690623011174 | Filiz Kelebek Makarna (Farfalle) (500g) |
| 143 | 8690623011181 | Filiz Midye Kesme Makarna (500g) |
| 144 | 8690623011198 | Filiz Yüksük Kesme Makarna (500g) |
| 145 | 8690623011204 | Filiz Arpa Şehriye (500g) |
| 146 | 8690623011211 | Filiz Tel Şehriye (500g) |
| 147 | 8690623011259 | Filiz Yumurtalı Uzun Erişte (500g) |
| 148 | 8690623011303 | Filiz Tam Buğday Burgu (500g) |
| 149 | 8690623011310 | Filiz Tam Buğday Spagetti (500g) |
| 150 | 8690623011327 | Filiz Tam Buğday Kalem (Penne) (500g) |
| 151 | 8690623011402 | Filiz Sebzeli Burgu Çeşitleri (500g) |
| 152 | 8690623011457 | Filiz Vitaminli Çubuk Spagetti (500g) |
| 153 | 8690623011501 | Filiz Kuskus Makarna (500g) |
| 154 | 8690623011556 | Filiz Fırın Makarna (Bucatini) (500g) |
| 155 | 8690623011600 | Filiz Dalgalı Lazanya Yaprağı (500g) |
| 188 | 8690624111118 | Pastavilla Spagetti Klasik (500g) |
| 189 | 8690624111125 | Pastavilla Penne Rigate (Kalem) (500g) |
| 190 | 8690624111132 | Pastavilla Fusilli (Burgu) (500g) |
| 191 | 8690624111149 | Pastavilla Pipette (Salyangoz) (500g) |
| 192 | 8690624111156 | Pastavilla Tagliatelle (Erişte Yuvası) |
| 193 | 8690624111200 | Pastavilla Linguine (Yassı Spagetti) |
| 194 | 8690624111255 | Pastavilla Arpa Şehriye Premium (500g) |
| 195 | 8690624111309 | Pastavilla Veggie (Sebzeli) Burgu (500g) |
| 196 | 8690624111408 | Pastavilla Kepekli Kalem (Penne) (500g) |
| 197 | 8690624111507 | Pastavilla Gnocchi (Deniz Kabuğu) (500g) |
| 198 | 8690624111552 | Pastavilla Risoni (Pirinç Taneli Şehriye) |
| 199 | 8690624111606 | Pastavilla Stelline (Yıldız Şehriye) |
| 200 | 8690624111651 | Pastavilla Fırın Makarna Long (500g) |

### Ekmek, gevrek, peynir, ayran ve dondurma

| Row | Submitted GTIN | Submitted name |
|---:|---|---|
| 1 | 8690629201128 | Uno Tost Ekmeği Klasik (550g) |
| 2 | 8690629201159 | Uno Tam Buğday Ekmeği (350g) |
| 3 | 8690629201203 | Uno Çavdarlı ve Tahıllı (350g) |
| 4 | 8690629201258 | Uno Premium Çok Tahıllı (400g) |
| 5 | 8690629201302 | Uno Sandviç Ekmeği (6'lı 390g) |
| 6 | 8690629201357 | Uno Hamburger Ekmeği (4'lü 320g) |
| 14 | 8690629201401 | Uno Büyük Tost Ekmeği (670g) |
| 15 | 8690629201456 | Uno Dönas Lavaş Ekmek (25cm) |
| 16 | 8690629201500 | Uno Glutensiz Ekmek (300g) |
| 18 | 8690629201609 | Uno Premium Ekşi Mayalı (450g) |
| 20 | 8690629201708 | Uno Ciabatta Ekmek (2'li 250g) |
| 56 | 8691515211023 | Bahçıvan Labne Peyniri Doğal (200g) |
| 68 | 8694034001007 | Kebir Vakfıkebir Labnesi (200g) |
| 74 | 8691953046102 | Eker Taze Labne Peyniri (200g) |
| 80 | 8691953511112 | Eker Ayran Tombul Şişe Geleneksel (1 L) |
| 81 | 8691953511150 | Eker Ayran Bardak Plastik (250ml) |
| 82 | 8691953511204 | Eker Yayık Ayranı Yoğun Kıvamlı (1 L) |
| 83 | 8691953511259 | Eker Probiyotik Ayran Fonksiyonel |
| 91 | 8680006511117 | Aynes Ayran Doğal Lezzet (1 L) |
| 92 | 8693427511116 | Altınkılıç Kefir Ayranı Karma (1 L) |
| 93 | 8694034511117 | Kebir Karadeniz Yayık Ayranı (1 L) |
| 94 | 8691953511303 | Eker Nane Aromalı Ferah Ayran |
| 96 | 8690637113116 | Magnum Classic Çubuk Dondurma (100ml) |
| 97 | 8690637113154 | Magnum Bademli Çubuk Dondurma |
| 98 | 8690637113208 | Magnum Beyaz Çikolatalı (100ml) |
| 99 | 8690637113253 | Magnum Double Çikolata Haz Hazzı |
| 100 | 8690637121111 | Cornetto Classico Kaymak Çikolata |
| 101 | 8690637121159 | Cornetto Aşk Ateşi Çilekli Külah |
| 102 | 8690637121203 | Cornetto Disc Çikolata Karnavalı |
| 103 | 8690637131110 | Carte d'Or Klasik Üç Lezzet (Sade-Çikolata-Antep Fıstığı) |
| 104 | 8690637131158 | Carte d'Or Selection Çikolata Karnavalı |
| 105 | 8690637131202 | Carte d'Or Selection Meyve Şöleni |
| 106 | 8690637141119 | Algida Maraş Usulü Sade Dondurma |
| 107 | 8690637141157 | Algida Maraş Usulü Çikolatalı Ekleme |
| 108 | 8690637141201 | Algida Maraş Usulü Antep Fıstıklı |
| 109 | 8690637151118 | Algida Boom Boom Çikolata Kaplı |
| 110 | 8690637151156 | Algida Twister Mini Buz Parmak |
| 111 | 8690637151200 | Algida Fruttare Vişneli Meyveli Buz |
| 112 | 8690637113307 | Magnum Gold Karamel Çubuk |
| 113 | 8690637113352 | Magnum Matcha Yeşil Çay Aromalı |
| 114 | 8690637121302 | Cornetto Milka Çikolatalı Külah |
| 115 | 8690637131301 | Carte d'Or Geleneksel Kadayıflı |
| 116 | 8690637131356 | Carte d'Or Selection Tiramisu (850ml) |
| 117 | 8690637151309 | Algida Nogger Sandviç Dondurma |
| 118 | 8690637151354 | Algida Viennetta Pasta Çikolatalı |
| 119 | 8690637113406 | Magnum Sunlover Mango Hindistan Cevizi |
| 120 | 8690637113451 | Magnum Starchaser Patlamış Mısırlı |
| 121 | 8690637121401 | Cornetto Rose Gül Şekilli Çilekli |
| 122 | 8690637131400 | Carte d'Or Karamel Kurabiye Aşkı |
| 123 | 8690637141300 | Algida Maraş Usulü Sarma Kesme |
| 124 | 8690637151408 | Algida Calippo Cola Aromalı Buz |
| 125 | 8690637151453 | Algida Max Aslan Max Kakao Vanilya |

### Patates cipsleri

| Row | Submitted GTIN | Submitted name |
|---:|---|---|
| 1 | 8690624301113 | Lay's Klasik Patates Cipsi Sade (150g) |
| 2 | 8690624301120 | Lay's Mevsim Yeşillikleri ve Yoğurtlu |
| 3 | 8690624301151 | Lay's Fırından Yoğurt ve Mevsim Yeşillikli |
| 4 | 8690624301205 | Lay's Fırından Kurutulmuş Domatesli Soslu |
| 5 | 8690624301250 | Lay's Baharat Çeşnili Patates Cipsi (107g) |
| 6 | 8690624301304 | Lay's Tulum Peyniri ve Zeytinyağlı (107g) |
| 7 | 8690624301359 | Lay's Barbekü Soslu Patates Cipsi |
| 8 | 8690624301403 | Lay's Fırından Sade Deniz Tuzlu (95g) |
| 9 | 8690624301458 | Lay's Izgara Soğan Aromalı Patates Cipsi |
| 10 | 8690624301502 | Lay's Cheddar Peynirli Patates Cipsi |
| 11 | 8690624301557 | Lay's Hardal ve Ballı Patates Cipsi |
| 12 | 8690624301601 | Lay's Acı Biberli ve Limonlu (Salsa) |
| 13 | 8690624301656 | Lay's Sweet Chili Tatlı Acı Biberli |
| 14 | 8690624301700 | Lay's Trüf Mantarı ve Parmesan Aromalı |
| 15 | 8690624301755 | Lay's Kekikli ve Zeytin Aromalı |
| 16 | 8690624301809 | Lay's Deniz Tuzu ve Sirkeli (Salt & Vinegar) |
| 17 | 8690624301854 | Lay's Fırından Enginar Kalbi ve Otlu |
| 18 | 8690624301908 | Lay's Dalgalı Tırtıklı Sade (150g) |
| 19 | 8690624301953 | Lay's Kumpir Lezzeti Karışık Çeşnili |
| 20 | 8690624302011 | Lay's Yoğurtlu Nane Aromalı Party Boy |
| 21 | 8690624302103 | Lay's Fırından Haşhaş ve Taneli |
| 22 | 8690624302158 | Lay's Baharatlı Mega Boy (193g) |
| 23 | 8690624302202 | Lay's Deniz Tuzlu Karabiberli Gurme |
| 24 | 8690624302257 | Lay's Fırından Humus Çeşnili (95g) |
| 25 | 8690624302301 | Lay's Labne Peynirli ve Köz Biberli |
| 65 | 8695077045119 | Masternut Vakumda Kızarmış Kıtır Patates |
| 66 | 8695077045157 | Masternut Kıtır Patates Trüf Aromalı |
| 67 | 8690624302400 | Lay's Light %50 Az Yağlı Fırınlanmış |
| 71 | 8690624101119 | Doritos Taco Baharat Aromalı Mısır Cipsi |
| 72 | 8690624101126 | Doritos Nacho Peynir Aromalı Mısır Cipsi |
| 73 | 8690624101157 | Doritos Hot Wave Acı Biber Aromalı |
| 74 | 8690624101201 | Doritos Extreme Wasabi Aromalı (113g) |
| 75 | 8690624101256 | Doritos Flamin' Hot Ekstrem Acılı |
| 76 | 8690624101300 | Doritos Turco Haşhaşlı ve Domatesli |
| 77 | 8690624101355 | Doritos Risk 5.0 Ekstrem Dil Boyayan |
| 78 | 8690624101409 | Doritos BBQ Füme Barbekü Soslu |
| 79 | 8690624101454 | Doritos Sweet Chili Tatlı ve Acılı |
| 80 | 8690624101508 | Doritos Süzme Yoğurtlu ve Naneli Mısır |
| 81 | 8690624101553 | Doritos Guacamole Avokado Aromalı |
| 82 | 8690624101607 | Doritos Cheddar Jalapeno Acılı Peynirli |
| 83 | 8690624101652 | Doritos Kumpir Soslu Tereyağlı Mısır |
| 84 | 8690624101706 | Doritos Sriracha Soslu Yoğun Acılı |
| 85 | 8690624101751 | Doritos Cool Ranch Ferah Soslu Mısır |
| 86 | 8690624101805 | Doritos Pizza Pepperoni Sucuk Aromalı |
| 87 | 8690624101850 | Doritos Nacho Mega Boy Peynirli (193g) |
| 88 | 8690624101904 | Doritos Taco Party Boy Baharatlı (218g) |
| 9 | 8690624101959 | Doritos Buffalo Wings Acı Kanat Aromalı |
| 90 | 8690624102017 | Doritos Flamin' Hot Lime Limonlu Acılı |
| 91 | 8690624102109 | Doritos Extreme Hamburger Lezzeti |
| 92 | 8690624102154 | Doritos Turco Domatesli Haşhaşlı Midi |
| 93 | 8690624102208 | Doritos Hot Wave Mega Boy Acı Biberli |
| 94 | 8690624102253 | Doritos Cheddar Crunch Yoğun Peynirli |
| 95 | 8690624102307 | Doritos Tangy Cheese Ekşi Peynirli |
| 96 | 8690624401110 | Cheetos Peynirli Şekilli Mısır Çerezi |
| 97 | 8690624401127 | Cheetos Fıstıklı Kıtır Mısır Çerezi |
| 98 | 8690624401158 | Cheetos Ketçap Aromalı Mısır Çerezi |
| 99 | 8690624401202 | Cheetos Taş Makas Kağıt Sütlü Peynirli |
| 100 | 8690624401257 | Cheetos Shots Peynirli Granül Çerez |
| 101 | 8690624401301 | Cheetos Crunchetos Ekstra Çıtır Peynir |
| 102 | 8690624401356 | Cheetos Flamin' Hot Acılı Mısır Çerezi |
| 108 | 8694034001007 | Çerezos Sütlü Peynirli Tombik Çerez |
| 109 | 8694034001021 | Çerezos Ketçaplı Kıvırcık Mısır Çerezi |
| 110 | 8694034001151 | Çerezos Fıstıklı Tombik Çerez (100g) |
| 111 | 8690624401400 | Cheetos Biftek Aromalı Şekilli Çerez |
| 112 | 8690624401455 | Cheetos Pizza Aromalı Çıtır Çerez |
| 113 | 8690624401509 | Cheetos Sweet Chili Tatlı Acı Halkalar |
| 114 | 8690624401554 | Cheetos Mini Peynirli 4'lü Paket |
| 117 | 8694034001205 | Çerezos Acılı Tombik Çerez (80g) |
| 118 | 8690624102352 | Doritos Risk 6.0 Dil Boyayan Ekstrem |
| 119 | 8690624401608 | Cheetos Cheddar Soslu Çıtır Çubuklar |

### Protein ve bakliyat cipsleri

| Row | Submitted GTIN | Submitted name |
|---:|---|---|
| 12 | 8699413627014 | Mayi Tuz fırınlanmış Karabağday Cipsi Sade |
| 13 | 8699413627021 | Mayi Tuz fırınlanmış Karabağday Cipsi Chia & Keten Tohumlu |
| 17 | 8690623051118 | Wasa Glutensiz Humus Cipsi Deniz Tuzlu |
| 18 | 8690623051125 | Wasa Glutensiz Humus Cipsi Paprika & Biber |

### Ek protein ve bakliyat cipsleri

| Row | Submitted GTIN | Submitted name |
|---:|---|---|
| 39 | 8690623051132 | Wasa Glutensiz Humus Cipsi Ekşi Krema & Frenk Soğanı |
| 44 | 8682341250119 | RawLove Fırınlanmış Proteinli Nohut Cipsi Chia Tohumlu |
| 45 | 8682341250126 | RawLove Fırınlanmış Proteinli Nohut Cipsi Haşhaşlı |
| 46 | 8699413627038 | Mayi Tuz fırınlanmış Karabağday Cipsi Kekikli |
| 47 | 8699413627045 | Mayi Tuz fırınlanmış Karabağday Cipsi Karabiberli |
| 68 | 8682341120016 | Vitality Havayla Kurutulmuş Kabak Cipsi Parmesan Aromalı |
| 69 | 8682341120023 | Vitality Havayla Kurutulmuş Tatlı Patates Cipsi |
| 75 | 8699413627052 | Mayi Tuz fırınlanmış Karabağday Cipsi Acı Biberli |

## Sources and limits

Ingredient evidence comes from the product pages linked above: CarrefourSA/Migros product label records, Tadım product/retailer records, Uno/Filiz retailer ingredient records and the Sütaş manufacturer page. Barcode pages are linked separately where they differ. The checked evidence shows product name, package size or barcode and ingredient text, but does not guarantee the current package in every market; users should compare their package label. No product images or free-from labels were inferred. Empty traces fields mean no trace warning was transcribed, not that cross-contact is absent.

## Labne listeleri

Dört eklenebilir kayıt doğrulandı: Pınar Labne 180 g, 400 g ve 750 g ile Sütaş Labne 400 g. İki gönderideki 155 barkodun tamamı EAN-13 kontrol basamağından geçmedi; eşleşmeyen labne varyantları dahil edilmedi. Ayrıntılar ve kaynaklar için [labne listesi denetimine](SUBMITTED_LABNE_LISTS_AUDIT_20261013.md) bakın.

