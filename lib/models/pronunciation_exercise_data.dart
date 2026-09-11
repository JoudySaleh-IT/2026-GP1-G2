class PronunciationExerciseData {
  final String id;
  final String letter;
  final String level;
  final int order;

  final String displayWord;
  final String targetWord;

  final String imagePath;
  final String audioPath;

  const PronunciationExerciseData({
    required this.id,
    required this.letter,
    required this.level,
    required this.order,
    required this.displayWord,
    required this.targetWord,
    required this.imagePath,
    required this.audioPath,
  });

  factory PronunciationExerciseData.fromJson(Map<String, dynamic> json) {
    return PronunciationExerciseData(
      id: json['id'] as String,
      letter: json['letter'] as String,
      level: json['level'] as String,
      order: json['order'] as int,
      displayWord: json['displayWord'] as String,
      targetWord: json['targetWord'] as String,
      imagePath: json['imagePath'] as String,
      audioPath: json['audioPath'] as String,
    );
  }
}
