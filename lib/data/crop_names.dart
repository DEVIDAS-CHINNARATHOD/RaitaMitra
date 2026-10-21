/// Display translations; canonical API names are kept for price matching.
const cropKannada = <String, String>{
  'Tomato': 'ಟೊಮೇಟೊ',
  'Alasande Gram': 'ಅಲಸಂದೆ',
  'Arecanut(Betelnut/Supari)': 'ಅಡಿಕೆ',
  'Ashgourd': 'ಬೂದು ಕುಂಬಳಕಾಯಿ',
  'Paddy': 'ಭತ್ತ',
  'Maize': 'ಮೆಕ್ಕೆಜೋಳ',
  'Ragi': 'ರಾಗಿ',
  'Groundnut': 'ಕಡಲೆಕಾಯಿ',
  'Ground Nut Seed': 'ಕಡಲೆಕಾಯಿ ಬೀಜ',
  'Onion': 'ಈರುಳ್ಳಿ',
  'Potato': 'ಆಲೂಗಡ್ಡೆ',
  'Green Gram': 'ಹೆಸರುಕಾಳು',
  'Green Gram Dal(Moong Dal)': 'ಹೆಸರು ಬೇಳೆ',
  'Arecanut': 'ಅಡಿಕೆ',
  'Coconut': 'ತೆಂಗಿನಕಾಯಿ',
  'Bengal Gram': 'ಕಡಲೆ',
  'Black Gram Dal(Urd Dal)': 'ಉದ್ದಿನ ಬೇಳೆ',
  'Beans': 'ಹುರಳಿಕಾಯಿ',
  'Beetroot': 'ಬೀಟ್ರೂಟ್',
  'Bitter gourd': 'ಹಾಗಲಕಾಯಿ',
  'Bottle gourd': 'ಸೋರೆಕಾಯಿ',
  'Cabbage': 'ಎಲೆಕೋಸು',
  'Capsicum': 'ದೊಣ್ಣೆ ಮೆಣಸಿನಕಾಯಿ',
  'Chilly Capsicum': 'ದೊಣ್ಣೆ ಮೆಣಸಿನಕಾಯಿ',
  'Carrot': 'ಕ್ಯಾರೆಟ್',
  'Cauliflower': 'ಹೂಕೋಸು',
  'Cucumbar(Kheera)': 'ಸೌತೆಕಾಯಿ',
  'Drumstick': 'ನುಗ್ಗೆಕಾಯಿ',
  'Foxtail Millet(Navane)': 'ನವಣೆ',
  'Garlic': 'ಬೆಳ್ಳುಳ್ಳಿ',
  'Ginger(Green)': 'ಶುಂಠಿ',
  'Green Chilli': 'ಹಸಿಮೆಣಸಿನಕಾಯಿ',
  'Knool Khol': 'ನವಿಲುಕೋಸು',
  'Ladies Finger': 'ಬೆಂಡೆಕಾಯಿ',
  'Raddish': 'ಮೂಲಂಗಿ',
  'Ridgeguard(Tori)': 'ಹೀರೆಕಾಯಿ',
  'Snakeguard': 'ಪಡವಲಕಾಯಿ',
  'Seemebadnekai': 'ಸೀಮೆ ಬದನೆಕಾಯಿ',
  'Brinjal': 'ಬದನೆಕಾಯಿ',
  'Jowar(Sorghum)': 'ಜೋಳ',
  'Turmeric': 'ಅರಿಶಿನ',
  'Cotton': 'ಹತ್ತಿ',
  'Sugarcane': 'ಕಬ್ಬು',
  'Sunflower': 'ಸೂರ್ಯಕಾಂತಿ',
};
String cropLabel(String name) {
  final entry = cropKannada.entries.where(
    (e) => e.key.toLowerCase() == name.toLowerCase(),
  );
  return entry.isEmpty ? name : '$name · ${entry.first.value}';
}

String canonicalCrop(String input, Iterable<String> options) {
  final query = input.trim().toLowerCase();
  for (final name in options) {
    if (name.toLowerCase() == query || cropLabel(name).toLowerCase() == query) {
      return name;
    }
  }
  final matches = cropKannada.entries
      .where((e) => e.value == input.trim())
      .toList();
  return matches.length == 1 ? matches.single.key : input.trim();
}
