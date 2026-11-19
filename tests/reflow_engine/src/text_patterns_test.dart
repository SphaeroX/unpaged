import 'package:reflow_engine/src/text_patterns.dart';
import 'package:test/test.dart';

void main() {
  group('isCaption', () {
    for (final text in [
      'Figure 1: The pipeline.',
      'Fig. 2. Device structures.',
      'FIG. 3. Band diagram.',
      'Table 1. Results per field.',
      'Abb. 4: Aufbau.',
      'Fig. 1.3 Scheme of coating',
      'Fig. 2.10 Changing of the',
      'Table 2.2 Calculating results',
      'Fig. 2.44 Oxidant content in gas. Jet Core.',
      'Table 3.1 (continued)',
      'Fig. 4.2 a Microstructure of the coating',
      'Table IV: Parameters.',
    ]) {
      test('"$text" starts a caption', () => expect(isCaption(text), isTrue));
    }

    // Body text that merely begins with a reference to a figure or table.
    for (final text in [
      'Fig. 2.19).',
      'Fig. 2.22). Proportional to it according to Eq. (2.66) is the',
      'Figure 2.50 shows the physical model of oxygen delivery to a',
      'Fig. 2.6 as a solid, test).',
      'Table 2.11, the velocities in the gap are higher',
      'Figure 3 shows the results.',
      'Fig. 2.45) and the calculation does not show any difference',
    ]) {
      test('"$text" is body text', () => expect(isCaption(text), isFalse));
    }
  });
}
