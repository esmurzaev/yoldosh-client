import 'dart:collection';
import 'dart:math';

class BitapMatch {
  BitapMatch._();
  // Defaults.
  // Set these on your diff_match_patch instance to override the defaults.

  /*
   * At what point is no match declared (0.0 = perfection, 1.0 = very loose).
   */
  static const double threshold = 0.4; // 0.5;
  /*
   * How far to search for a match (0 = exact location, 1000+ = broad match).
   * A match this many characters away from the expected location will add
   * 1.0 to the score (0.0 is a perfect match).
   */
  static const int distance = 100; // 1000;

  /*
   * The number of bits in an int.
   */
  static const int maxBits = 64;

  /*
   * Locate the best instance of 'pattern' in 'text' near 'loc' using the
   * Bitap algorithm.  Returns -1 if no match found.
   * [text] is the the text to search.
   * [pattern] is the pattern to search for.
   * [loc] is the location to search around.
   * Returns the best match index or -1.
   */
  static List<int> matchAll(List<String> placeNames, String pattern) {
    // Pattern too long for this application.
    // assert(pattern.length <= maxBits);
    final List<int> matchedPlaceIndexes = [];
    // Initialise the alphabet.
    final Map<String, int> s = _alphabet(pattern);
    // Highest score beyond which we give up.
    double scoreThreshold = threshold;
    // double bestScoreThreshold = 0;
    final int patternLength = pattern.length;
    // Initialise the bit arrays.
    final matchMask = 1 << (patternLength - 1);
    // distance = placeList.length;
    int pos = 0;
    int loc;
    int bestLoc;
    int binMin, binMid, binMax;
    List<int> lastRd;
    // distance = 100;
    // threshold = 0.4;

    for (int i = 0, len = placeNames.length; i < len; i++) {
      String text = placeNames[i];
      if (text.startsWith(pattern)) {
        matchedPlaceIndexes.insert(pos, i);
        pos++;
        continue;
      }
      loc = text.length;
      /*
      // Is there a nearby exact match? (speedup)
      int bestLoc = text.indexOf(pattern, loc);
      if (bestLoc != -1) {
				/*
        matchedPlaceIndexes.add(i);
        bestScoreThreshold = 0.1;
        continue;
        */
        scoreThreshold = min(_bitapScore(0, bestLoc, loc, patternLength), scoreThreshold);
        // What about in the other direction? (speedup)
        bestLoc = text.lastIndexOf(pattern, loc + patternLength);
        if (bestLoc != -1) {
          scoreThreshold = min(_bitapScore(0, bestLoc, loc, patternLength), scoreThreshold);
        }
      }
      */
      bestLoc = -1;
      binMax = patternLength + text.length;

      for (int d = 0; d < patternLength; d++) {
        // Scan for the best match; each iteration allows for one more error.
        // Run a binary search to determine how far from 'loc' we can stray at
        // this error level.
        binMin = 0;
        binMid = binMax;
        while (binMin < binMid) {
          if (_bitapScore(d, loc + binMid, loc, patternLength) <= scoreThreshold) {
            binMin = binMid;
          } else {
            binMax = binMid;
          }
          binMid = ((binMax - binMin) / 2 + binMin).toInt();
        }
        // Use the result from this iteration as the maximum for the next.
        binMax = binMid;
        int start = max(1, loc - binMid + 1);
        int finish = min(loc + binMid, text.length) + patternLength;

        final rd = List<int>(finish + 2);
        rd[finish + 1] = (1 << d) - 1;
        for (int j = finish; j >= start; j--) {
          int charMatch;
          if (text.length <= j - 1 || !s.containsKey(text[j - 1])) {
            // Out of range.
            charMatch = 0;
          } else {
            charMatch = s[text[j - 1]];
          }
          if (d == 0) {
            // First pass: exact match.
            rd[j] = ((rd[j + 1] << 1) | 1) & charMatch;
          } else {
            // Subsequent passes: fuzzy match.
            rd[j] = ((rd[j + 1] << 1) | 1) & charMatch | (((lastRd[j + 1] | lastRd[j]) << 1) | 1) | lastRd[j + 1];
          }
          if ((rd[j] & matchMask) != 0) {
            double score = _bitapScore(d, j - 1, loc, patternLength);
            // This match will almost certainly be better than any existing
            // match.  But check anyway.
            if (score <= scoreThreshold) {
              // Told you so.
              scoreThreshold = score;
              bestLoc = j - 1;
              if (bestLoc > loc) {
                // When passing loc, don't exceed our current distance from loc.
                start = max(1, 2 * loc - bestLoc);
              } else {
                // Already passed loc, downhill from here on in.
                // if (bestScoreThreshold < scoreThreshold) {
                matchedPlaceIndexes.add(i);
                // } else {
                // matchedPlaceIndexes.insert(pos, i);
                // pos++;
                // bestScoreThreshold = scoreThreshold;
                // }
                break;
              }
            }
          }
        }
        /*
        if (_bitapScore(d + 1, loc, loc, patternLength) > scoreThreshold) {
          // No hope for a (better) match at greater error levels.
          break;
        }
        */
        lastRd = rd;
      }
    }
    if (matchedPlaceIndexes.length > 40) {
      matchedPlaceIndexes.removeRange(40, matchedPlaceIndexes.length);
    }
    return matchedPlaceIndexes;
  }

  /*
   * Compute and return the score for a match with e errors and x location.
   * [e] is the number of errors in match.
   * [x] is the location of match.
   * [loc] is the expected location of match.
   * [pattern] is the pattern being sought.
   * Returns the overall score for match (0.0 = good, 1.0 = bad).
   */
  static double _bitapScore(int e, int x, int loc, int patternLength) {
    final accuracy = e / patternLength;
    final proximity = (loc - x).abs();
    /*
    if (distance == 0) {
      // Dodge divide by zero error.
      return proximity == 0 ? accuracy : 1.0;
    }
		*/
    return accuracy + proximity / distance;
  }

  /*
   * Initialise the alphabet for the Bitap algorithm.
   * [pattern] is the the text to encode.
   * Returns a Map of character locations.
   */
  static Map<String, int> _alphabet(String pattern) {
    final s = HashMap<String, int>();
    for (int i = 0; i < pattern.length; i++) {
      s[pattern[i]] = 0;
    }
    for (int i = 0; i < pattern.length; i++) {
      s[pattern[i]] = s[pattern[i]] | (1 << (pattern.length - i - 1));
    }
    return s;
  }
}
