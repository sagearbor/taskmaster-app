/// Bundled trivia question bank.
///
/// This is a `const` list compiled into the app, so Trivia Buzzer works fully
/// OFFLINE — there is no network fetch. The pure [TriviaSession] model
/// references questions by [TriviaQuestion.id] (only the ids are persisted /
/// synced); the full text is looked up here on every device, keeping the synced
/// document small and identical for everyone.
///
/// Family-friendly mix of easy/medium questions across a handful of categories.
library;

import 'package:equatable/equatable.dart';

/// A single multiple-choice trivia question. Always exactly four [choices];
/// [correctIndex] is the 0-based index of the right answer.
class TriviaQuestion extends Equatable {
  final String id;
  final String category;
  final String question;
  final List<String> choices;
  final int correctIndex;

  const TriviaQuestion({
    required this.id,
    required this.category,
    required this.question,
    required this.choices,
    required this.correctIndex,
  });

  /// The text of the correct choice.
  String get correctAnswer => choices[correctIndex];

  bool isCorrect(int choiceIndex) => choiceIndex == correctIndex;

  @override
  List<Object?> get props => [id, category, question, choices, correctIndex];
}

/// Look up a bundled question by id, or null if the id is unknown (e.g. the
/// bank changed under an in-flight session). Callers must tolerate null.
TriviaQuestion? triviaQuestionById(String id) => _byId[id];

final Map<String, TriviaQuestion> _byId = {
  for (final q in kTriviaQuestions) q.id: q,
};

/// The full bundled bank. ~40 questions across several categories.
const List<TriviaQuestion> kTriviaQuestions = [
  // ---- General knowledge --------------------------------------------------
  TriviaQuestion(
    id: 'gen1',
    category: 'General',
    question: 'How many days are there in a leap year?',
    choices: ['364', '365', '366', '367'],
    correctIndex: 2,
  ),
  TriviaQuestion(
    id: 'gen2',
    category: 'General',
    question: 'What colour do you get by mixing blue and yellow?',
    choices: ['Green', 'Purple', 'Orange', 'Brown'],
    correctIndex: 0,
  ),
  TriviaQuestion(
    id: 'gen3',
    category: 'General',
    question: 'How many sides does a hexagon have?',
    choices: ['5', '6', '7', '8'],
    correctIndex: 1,
  ),
  TriviaQuestion(
    id: 'gen4',
    category: 'General',
    question: 'Which of these is a primary colour?',
    choices: ['Green', 'Orange', 'Red', 'Purple'],
    correctIndex: 2,
  ),
  TriviaQuestion(
    id: 'gen5',
    category: 'General',
    question: 'How many minutes are there in one hour?',
    choices: ['30', '60', '90', '100'],
    correctIndex: 1,
  ),

  // ---- Science ------------------------------------------------------------
  TriviaQuestion(
    id: 'sci1',
    category: 'Science',
    question: 'What planet is known as the Red Planet?',
    choices: ['Venus', 'Jupiter', 'Mars', 'Saturn'],
    correctIndex: 2,
  ),
  TriviaQuestion(
    id: 'sci2',
    category: 'Science',
    question: 'What gas do plants absorb from the air?',
    choices: ['Oxygen', 'Carbon dioxide', 'Hydrogen', 'Nitrogen'],
    correctIndex: 1,
  ),
  TriviaQuestion(
    id: 'sci3',
    category: 'Science',
    question: 'How many legs does a spider have?',
    choices: ['6', '8', '10', '12'],
    correctIndex: 1,
  ),
  TriviaQuestion(
    id: 'sci4',
    category: 'Science',
    question: 'What is the largest planet in our solar system?',
    choices: ['Earth', 'Saturn', 'Neptune', 'Jupiter'],
    correctIndex: 3,
  ),
  TriviaQuestion(
    id: 'sci5',
    category: 'Science',
    question: 'What is H2O more commonly known as?',
    choices: ['Salt', 'Water', 'Oxygen', 'Hydrogen'],
    correctIndex: 1,
  ),
  TriviaQuestion(
    id: 'sci6',
    category: 'Science',
    question: 'Which organ pumps blood around the body?',
    choices: ['Lungs', 'Brain', 'Heart', 'Liver'],
    correctIndex: 2,
  ),
  TriviaQuestion(
    id: 'sci7',
    category: 'Science',
    question: 'At what temperature (Celsius) does water freeze?',
    choices: ['0', '10', '32', '100'],
    correctIndex: 0,
  ),

  // ---- Geography ----------------------------------------------------------
  TriviaQuestion(
    id: 'geo1',
    category: 'Geography',
    question: 'What is the capital of France?',
    choices: ['London', 'Berlin', 'Paris', 'Madrid'],
    correctIndex: 2,
  ),
  TriviaQuestion(
    id: 'geo2',
    category: 'Geography',
    question: 'Which is the largest ocean on Earth?',
    choices: ['Atlantic', 'Indian', 'Arctic', 'Pacific'],
    correctIndex: 3,
  ),
  TriviaQuestion(
    id: 'geo3',
    category: 'Geography',
    question: 'On which continent is the Sahara Desert?',
    choices: ['Asia', 'Africa', 'Australia', 'South America'],
    correctIndex: 1,
  ),
  TriviaQuestion(
    id: 'geo4',
    category: 'Geography',
    question: 'Which country is shaped like a boot?',
    choices: ['Spain', 'Greece', 'Italy', 'Portugal'],
    correctIndex: 2,
  ),
  TriviaQuestion(
    id: 'geo5',
    category: 'Geography',
    question: 'What is the tallest mountain in the world?',
    choices: ['K2', 'Mount Everest', 'Kilimanjaro', 'Mont Blanc'],
    correctIndex: 1,
  ),
  TriviaQuestion(
    id: 'geo6',
    category: 'Geography',
    question: 'How many continents are there on Earth?',
    choices: ['5', '6', '7', '8'],
    correctIndex: 2,
  ),

  // ---- History ------------------------------------------------------------
  TriviaQuestion(
    id: 'his1',
    category: 'History',
    question: 'Who was the first President of the United States?',
    choices: ['Abraham Lincoln', 'George Washington', 'Thomas Jefferson',
        'John Adams'],
    correctIndex: 1,
  ),
  TriviaQuestion(
    id: 'his2',
    category: 'History',
    question: 'The Great Wall is located in which country?',
    choices: ['Japan', 'India', 'China', 'Mongolia'],
    correctIndex: 2,
  ),
  TriviaQuestion(
    id: 'his3',
    category: 'History',
    question: 'Which ancient civilization built the pyramids of Giza?',
    choices: ['Romans', 'Greeks', 'Egyptians', 'Aztecs'],
    correctIndex: 2,
  ),
  TriviaQuestion(
    id: 'his4',
    category: 'History',
    question: 'In which country did the Olympic Games begin?',
    choices: ['Italy', 'Greece', 'Egypt', 'England'],
    correctIndex: 1,
  ),

  // ---- Animals ------------------------------------------------------------
  TriviaQuestion(
    id: 'ani1',
    category: 'Animals',
    question: 'What is the largest land animal?',
    choices: ['Giraffe', 'Elephant', 'Rhino', 'Hippo'],
    correctIndex: 1,
  ),
  TriviaQuestion(
    id: 'ani2',
    category: 'Animals',
    question: 'Which bird is famous for being unable to fly?',
    choices: ['Penguin', 'Eagle', 'Sparrow', 'Robin'],
    correctIndex: 0,
  ),
  TriviaQuestion(
    id: 'ani3',
    category: 'Animals',
    question: 'What do bees collect and use to make honey?',
    choices: ['Pollen', 'Nectar', 'Water', 'Leaves'],
    correctIndex: 1,
  ),
  TriviaQuestion(
    id: 'ani4',
    category: 'Animals',
    question: 'How many hearts does an octopus have?',
    choices: ['1', '2', '3', '4'],
    correctIndex: 2,
  ),
  TriviaQuestion(
    id: 'ani5',
    category: 'Animals',
    question: 'What is a group of lions called?',
    choices: ['A pack', 'A herd', 'A pride', 'A flock'],
    correctIndex: 2,
  ),
  TriviaQuestion(
    id: 'ani6',
    category: 'Animals',
    question: 'Which animal is known as the "king of the jungle"?',
    choices: ['Tiger', 'Lion', 'Gorilla', 'Bear'],
    correctIndex: 1,
  ),

  // ---- Movies & entertainment --------------------------------------------
  TriviaQuestion(
    id: 'ent1',
    category: 'Movies',
    question: 'In the movie "Frozen", what is the name of the snowman?',
    choices: ['Sven', 'Olaf', 'Kristoff', 'Hans'],
    correctIndex: 1,
  ),
  TriviaQuestion(
    id: 'ent2',
    category: 'Movies',
    question: 'What kind of animal is Pixar\'s Nemo?',
    choices: ['Dolphin', 'Shark', 'Clownfish', 'Turtle'],
    correctIndex: 2,
  ),
  TriviaQuestion(
    id: 'ent3',
    category: 'Movies',
    question: 'Which superhero is known as the "Caped Crusader"?',
    choices: ['Superman', 'Spider-Man', 'Batman', 'Iron Man'],
    correctIndex: 2,
  ),
  TriviaQuestion(
    id: 'ent4',
    category: 'Movies',
    question: 'In "The Lion King", what is the name of the young lion?',
    choices: ['Simba', 'Mufasa', 'Scar', 'Nala'],
    correctIndex: 0,
  ),
  TriviaQuestion(
    id: 'ent5',
    category: 'Movies',
    question: 'What colour is the popular cartoon character SpongeBob?',
    choices: ['Blue', 'Green', 'Yellow', 'Pink'],
    correctIndex: 2,
  ),

  // ---- Food ---------------------------------------------------------------
  TriviaQuestion(
    id: 'food1',
    category: 'Food',
    question: 'Which fruit is traditionally used to make wine?',
    choices: ['Apple', 'Grape', 'Orange', 'Cherry'],
    correctIndex: 1,
  ),
  TriviaQuestion(
    id: 'food2',
    category: 'Food',
    question: 'What is the main ingredient in guacamole?',
    choices: ['Tomato', 'Avocado', 'Pepper', 'Onion'],
    correctIndex: 1,
  ),
  TriviaQuestion(
    id: 'food3',
    category: 'Food',
    question: 'Which country is famous for inventing pizza?',
    choices: ['France', 'Italy', 'Greece', 'Spain'],
    correctIndex: 1,
  ),
  TriviaQuestion(
    id: 'food4',
    category: 'Food',
    question: 'Which spice is the most expensive in the world by weight?',
    choices: ['Cinnamon', 'Saffron', 'Pepper', 'Vanilla'],
    correctIndex: 1,
  ),

  // ---- Sports -------------------------------------------------------------
  TriviaQuestion(
    id: 'spo1',
    category: 'Sports',
    question: 'How many players from one team are on a soccer field?',
    choices: ['9', '10', '11', '12'],
    correctIndex: 2,
  ),
  TriviaQuestion(
    id: 'spo2',
    category: 'Sports',
    question: 'In which sport would you perform a "slam dunk"?',
    choices: ['Tennis', 'Basketball', 'Golf', 'Cricket'],
    correctIndex: 1,
  ),
  TriviaQuestion(
    id: 'spo3',
    category: 'Sports',
    question: 'How often are the Summer Olympic Games held?',
    choices: ['Every 2 years', 'Every 3 years', 'Every 4 years',
        'Every 5 years'],
    correctIndex: 2,
  ),
  TriviaQuestion(
    id: 'spo4',
    category: 'Sports',
    question: 'In tennis, what is a score of zero called?',
    choices: ['Nil', 'Love', 'Duck', 'Blank'],
    correctIndex: 1,
  ),

  // ---- Math ---------------------------------------------------------------
  TriviaQuestion(
    id: 'mat1',
    category: 'Math',
    question: 'What is 7 multiplied by 8?',
    choices: ['54', '56', '63', '64'],
    correctIndex: 1,
  ),
  TriviaQuestion(
    id: 'mat2',
    category: 'Math',
    question: 'What is the value of pi rounded to two decimal places?',
    choices: ['3.12', '3.14', '3.16', '3.41'],
    correctIndex: 1,
  ),
  TriviaQuestion(
    id: 'mat3',
    category: 'Math',
    question: 'How many zeros are there in the number one thousand?',
    choices: ['2', '3', '4', '5'],
    correctIndex: 1,
  ),
];
