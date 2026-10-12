/// Navilo - Cilt tipi tanımları
enum SkinType { oily, combination, dry, normal }

extension SkinTypeInfo on SkinType {
  String get label => switch (this) {
        SkinType.oily => 'Yağlı',
        SkinType.combination => 'Karma',
        SkinType.dry => 'Kuru',
        SkinType.normal => 'Normal',
      };

  String get description => switch (this) {
        SkinType.oily =>
          'Cildin gün içinde yüzün büyük bölümünde yağlanma ve parlama eğiliminde. Gözenekler daha belirgin olabilir.',
        SkinType.combination =>
          'Alın, burun ve çene (T bölgesi) yağlanırken yanaklar normal ya da kuru kalıyor.',
        SkinType.dry =>
          'Cildin yeterince yağ ve nem tutmakta zorlanıyor. Gerginlik, mat görünüm ve pullanma görülebilir.',
        SkinType.normal =>
          'Cildin genel olarak dengeli: aşırı yağlı ya da kuru değil, belirgin bir sorun göstermiyor.',
      };

  List<String> get tips => switch (this) {
        SkinType.oily => [
            'Hafif dokulu nemlendiricileri değerlendirebilirsin.',
            'Ürün etiketinde yağsız veya komedojenik olmayan beyanını kontrol et.',
            'Yağlanmayı azaltmak için cildini sertçe ovalama.'
          ],
        SkinType.combination => [
            'T bölgesi ve yanaklarının farklı ihtiyaçlarını gözle.',
            'Bölgelere göre nemlendirici dokusunu ayarlayabilirsin.',
            'Yeni ürünleri tek tek dene.'
          ],
        SkinType.dry => [
            'Gliserin veya seramid içeren nemlendiricileri değerlendirebilirsin.',
            'Parfümsüz ve nazik temizleyiciler seçmeyi düşün.',
            'Nemlendiriciyi hafif nemli cilde uygulayabilirsin.'
          ],
        SkinType.normal => [
            'Nazik temizleme ve nemlendirme rutinini koru.',
            'Yeni ürünleri tek tek dene ve tepkiyi gözle.',
            'Mevsim değiştiğinde cildinin ihtiyacını yeniden değerlendir.'
          ],
      };
}
