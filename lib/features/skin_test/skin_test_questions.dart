import 'skin_type.dart';

class SkinOption {
  const SkinOption(this.text, this.points, {this.sensitivity = 0});

  final String text;

  /// Bu seçeneğin cilt tiplerine eklediği puanlar.
  final Map<SkinType, int> points;

  /// Hassasiyet sorusu için ayrı skor (cilt tipini etkilemez).
  final int sensitivity;
}

class SkinQuestion {
  const SkinQuestion(this.text, this.options, {this.hint});

  final String text;
  final String? hint;
  final List<SkinOption> options;
}

const skinQuestions = <SkinQuestion>[
  SkinQuestion(
    'Yüzünü yıkayıp hiçbir ürün sürmeden 30-60 dakika beklersen cildin nasıl hisseder?',
    [
      SkinOption('Gergin, çekilmiş, bazen kaşıntılı', {SkinType.dry: 3}),
      SkinOption('Rahat; ne gergin ne yağlı', {SkinType.normal: 3}),
      SkinOption('Alın ve burun yağlanır, yanaklar rahat ya da hafif gergin',
          {SkinType.combination: 3}),
      SkinOption('Tüm yüz yağlı ve parlak', {SkinType.oily: 3}),
    ],
    hint: 'Sabah yıkadıktan sonraki hissi düşün.',
  ),
  SkinQuestion(
    'Gün ortasında yüzünde parlama nerede oluyor?',
    [
      SkinOption('Neredeyse hiç parlamıyor, mat görünüyor',
          {SkinType.dry: 2, SkinType.normal: 1}),
      SkinOption('Çok hafif, belli belirsiz', {SkinType.normal: 3}),
      SkinOption('Sadece alın, burun ve çenede (T bölgesi)',
          {SkinType.combination: 3}),
      SkinOption('Yüzün büyük bölümünde', {SkinType.oily: 3}),
    ],
  ),
  SkinQuestion(
    'Gözeneklerin nasıl görünüyor?',
    [
      SkinOption('Her yerde belirgin ve geniş', {SkinType.oily: 3}),
      SkinOption('Sadece burun çevresinde belirgin', {SkinType.combination: 3}),
      SkinOption('Çok az görünür', {SkinType.normal: 3}),
      SkinOption('Neredeyse görünmez; cilt ince ve mat',
          {SkinType.dry: 2, SkinType.normal: 1}),
    ],
  ),
  SkinQuestion(
    'Cildinde pullanma, çatlama ya da kuru yamalar oluyor mu?',
    [
      SkinOption('Sık sık', {SkinType.dry: 3}),
      SkinOption('Özellikle yanaklarda ara sıra',
          {SkinType.combination: 2, SkinType.dry: 1}),
      SkinOption('Çok nadir', {SkinType.normal: 2, SkinType.oily: 1}),
      SkinOption('Hayır, tam tersine yağlanma sorunum var', {SkinType.oily: 3}),
    ],
  ),
  SkinQuestion(
    'Sivilce ve siyah nokta durumun nasıl?',
    [
      SkinOption('Yüzün birçok yerinde sık sık', {SkinType.oily: 3}),
      SkinOption('Çoğunlukla T bölgesinde', {SkinType.combination: 3}),
      SkinOption('Nadiren', {SkinType.normal: 3}),
      SkinOption('Nadiren; asıl sorunum kuruluk', {SkinType.dry: 2}),
    ],
  ),
  SkinQuestion(
    'Nemlendirici sürdükten sonra cildin nasıl hissediyor?',
    [
      SkinOption(
          'Hemen çekilir, kısa sürede tekrar nem ister', {SkinType.dry: 3}),
      SkinOption('Rahat ve dengeli', {SkinType.normal: 3}),
      SkinOption('T bölgesi yağlı, yanaklar iyi', {SkinType.combination: 3}),
      SkinOption(
          'Hafif kremler bile yağlı ve ağır hissettirir', {SkinType.oily: 3}),
    ],
  ),
  SkinQuestion(
    'Gün sonunda yüzüne temiz bir mendil ya da yağ emici kağıt bastırsan ne olur?',
    [
      SkinOption(
          'Neredeyse hiç iz kalmaz', {SkinType.dry: 2, SkinType.normal: 1}),
      SkinOption('Hafif bir iz kalır', {SkinType.normal: 3}),
      SkinOption(
          'Alın ve burun bölgesinde yoğun iz kalır', {SkinType.combination: 3}),
      SkinOption('Her bölgeden yoğun iz kalır', {SkinType.oily: 3}),
    ],
  ),
  SkinQuestion(
    'Mevsim değişince cildin nasıl tepki veriyor?',
    [
      SkinOption('Kışın belirgin şekilde kuruyor ve pullanıyor',
          {SkinType.dry: 2, SkinType.normal: 1}),
      SkinOption('Mevsime göre pek değişmez', {SkinType.normal: 3}),
      SkinOption('Yazın T bölgesi yağlanıyor, kışın yanaklar kuruyor',
          {SkinType.combination: 3}),
      SkinOption('Yazın çok yağlanıyor, kışın da yağlılık sürüyor',
          {SkinType.oily: 3}),
    ],
  ),
  SkinQuestion(
    'Yeni bir ürün sürdüğünde kızarıklık, yanma ya da batma yaşar mısın?',
    [
      SkinOption('Sık sık', {}, sensitivity: 2),
      SkinOption('Ara sıra', {}, sensitivity: 1),
      SkinOption('Nadiren ya da hiç', {}),
    ],
    hint: 'Bu soru cilt tipini değil, hassasiyet notunu belirler.',
  ),
];
