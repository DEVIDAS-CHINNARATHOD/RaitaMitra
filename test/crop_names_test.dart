import 'package:flutter_test/flutter_test.dart';
import 'package:raitha_mitra/data/crop_names.dart';

void main() {
  test('Kannada crop entry maps back to canonical price name', () {
    expect(canonicalCrop('ಟೊಮೇಟೊ', cropKannada.keys), 'Tomato');
    expect(canonicalCrop('tomato', cropKannada.keys), 'Tomato');
    expect(cropLabel('Tomato'), 'Tomato · ಟೊಮೇಟೊ');
  });
  test('unlisted crop names are preserved without a false match', () {
    expect(canonicalCrop('My local crop', cropKannada.keys), 'My local crop');
  });
}
