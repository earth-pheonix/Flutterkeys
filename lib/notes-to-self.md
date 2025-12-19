
  void subscribeWordStream() {
    print('subscribing');

    if (V4rs.useWPM.value) {
      final interval = Duration(milliseconds: (60000 / V4rs.currentWPM).round());
      final words = V4rs.message.value.split(' ');
print('WORDS: $words');
print('WORD COUNT: ${words.length}');
      int currentHighlightStart = 0;

      V4rs.theStream = Stream.periodic(interval, (i) {
        if (i >= words.length) return null;
        String word = words[i];
        int start = V4rs.message.value.indexOf(word, currentHighlightStart);
        currentHighlightStart = start + word.length; 
        
        return {
          'start': start, 
          'length': word.length
        };
      }).take(words.length);

    } else {
      if (synth?.wordStream == null) return;
      V4rs.theStream = synth!.wordStream;
    }
    
    print('pre null check');
    if (V4rs.theStream == null) return;
    _wordSub = V4rs.theStream?.listen((event) {
      if (!mounted) return;

      setState(() {
        V4rs.highlightAdd.value = event['start'] as int? ?? 0;
        
        V4rs.highlightLength.value = event['length'] as int?;
      });

      print(
          'HIGHLIGHT start=${event['start']} '
          'len=${event['length']} '
          'text="${V4rs.message.value.substring(
            event['start'],
            event['start'] + event['length'],
          )}"'
        );
    });
  }