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

  group('isEquationNumber', () {
    for (final text in [
      '(1)',
      '(12b)',
      '(2.64)',
      '(2.103)',
      '(3.16a)',
      // The math font of Springer books prints the period as a colon.
      '(2:64)',
      '( 2.5 )',
    ]) {
      test('"$text" is an equation number', () {
        expect(isEquationNumber(text), isTrue);
      });
    }

    for (final text in ['(see 2.3)', '(2.5 mm)', '(a)', '2.64', '(1, 2)']) {
      test('"$text" is not an equation number', () {
        expect(isEquationNumber(text), isFalse);
      });
    }
  });

  group('longWordCount', () {
    test('symbols that read like short words are no long words', () {
      expect(longWordCount('Re = Wg - Wp dp qp gg;'), 0);
      expect(longWordCount('dT dr2 = dr dT if DTr'), 0);
      expect(longWordCount('C = 2 sin a cos b'), 0);
      expect(longWordCount('T2 = Tk erfc x + cosh y'), 0);
    });

    test('counts the words of a sentence', () {
      expect(longWordCount('Thus, for every t ∈ [0, T],'), 2);
      expect(longWordCount('where a is the first term'), 3);
    });
  });
}
