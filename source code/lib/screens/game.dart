import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tic_tac_toe/services/services.dart';
import 'package:tic_tac_toe/size_config.dart';
import 'package:firebase_database/firebase_database.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  final ScrollController _scrollController = ScrollController(
    initialScrollOffset: 50.0,
    keepScrollOffset: false,
  );

  final Singleton _singleton = Singleton();

  bool myTurn = false;
  String mySymbol = 'O';
  StreamSubscription<DatabaseEvent>? gameListener;
  List<Object?> tiles = [" ", " ", " ", " ", " ", " ", " ", " ", " "];
  String opponent = "";
  String winner = "";

  void checkWin() {
    // TO BE REPLACED BY CLOUD FUNCTIONS
    String result = "pending";
    String winningSymbol = "";
    if (tiles[0] != " " && tiles[0] == tiles[1] && tiles[1] == tiles[2] ||
        tiles[0] != " " && tiles[0] == tiles[3] && tiles[3] == tiles[6] ||
        tiles[0] != " " && tiles[0] == tiles[4] && tiles[4] == tiles[8]) {
      winningSymbol = tiles[0] as String;
    }
    if (tiles[2] != " " && tiles[2] == tiles[5] && tiles[5] == tiles[8] ||
        tiles[2] != " " && tiles[2] == tiles[4] && tiles[4] == tiles[6]) {
      winningSymbol = tiles[2] as String;
    }
    if (tiles[1] != " " && tiles[1] == tiles[4] && tiles[4] == tiles[7]) {
      winningSymbol = tiles[1] as String;
    }
    if (tiles[3] != " " && tiles[3] == tiles[4] && tiles[4] == tiles[5]) {
      winningSymbol = tiles[3] as String;
    }
    if (tiles[6] != " " && tiles[6] == tiles[7] && tiles[7] == tiles[8]) {
      winningSymbol = tiles[6] as String;
    }

    if (winningSymbol != "") {
      if (mySymbol == winningSymbol) {
        result = (Auth().user != null) ? Auth().user!.uid : "Player";
      } else {
        result = opponent;
      }
    }

    if (result != "pending") {
      print("$result is the winner!");
      DatabaseReference ref =
          FirebaseDatabase.instance.ref("games/${_singleton.currentGame}");
      ref.update({"win": result}).then(
          (value) => Timer(const Duration(seconds: 3), () {
                gameListener?.cancel().then((value) => closeGame());
              }));
    }
  }

  Future closeGame() async {
    // TO BE REPLACED BY CLOUD FUNCTIONS
    _singleton.currentGame = null;
    DatabaseReference ref =
        FirebaseDatabase.instance.ref("games/${_singleton.currentGame}");
    await ref.remove().then(
      (value) {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (gameListener == null) {
      DatabaseReference ref =
          FirebaseDatabase.instance.ref("games/${_singleton.currentGame}");

      gameListener = ref.onValue.listen((event) async {
        setState(() {
          for (final child in event.snapshot.children) {
            if (child.key == "buttons") {
              tiles = child.value as List<Object?>;
            } else if (child.key == "turn") {
              if (child.value == Auth().user?.uid) {
                myTurn = true;
              } else {
                myTurn = false;
              }
            } else if (child.key == "players") {
              var players = child.value as Map;
              players.forEach((key, value) {
                if (key == Auth().user?.uid) {
                  mySymbol = value;
                } else {
                  opponent = key;
                }
              });
            } else if (child.key == "win" && child.value != "pending") {
              if (child.value == Auth().user?.uid) {
                print("YOU WON!");
                winner = Auth().user?.displayName as String;
              } else if (child.value == opponent) {
                print("YOU LOST!");
                winner = "Opponent";
              }
            }
          }
        });
      });
    }

    checkWin();

    return Scaffold(
      body: SafeArea(
        child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                height: 150,
                width: SizeConfig.blockSizeHorizontal! * 100,
                child: Container(
                  color: const Color.fromARGB(255, 74, 70, 72),
                  child: InkWell(
                    onTap: () {},
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text("Opponent",
                                style: TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.bold,
                                    color: Color.fromARGB(255, 240, 217, 181))),
                            Text(mySymbol == 'X' ? "O" : 'X',
                                style: const TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.bold,
                                    color: Color.fromARGB(255, 240, 217, 181))),
                          ],
                        ),
                        SizedBox(
                          width: SizeConfig.blockSizeHorizontal! * 5,
                        ),
                        Container(
                          width: 100,
                          height: 100,
                          decoration: const BoxDecoration(
                              color: Color.fromARGB(255, 45, 41, 43),
                              shape: BoxShape.circle),
                        ),
                        SizedBox(
                          width: SizeConfig.blockSizeHorizontal! * 5,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: SizeConfig.blockSizeVertical! * 2),
              winner == ""
                  ? Text(
                      myTurn
                          ? "${Auth().user?.displayName}'s Turn:"
                          : "Opponent's Turn",
                      style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 240, 217, 181)))
                  : Text("$winner wins!",
                      style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 240, 217, 181))),
              SizedBox(
                  height: SizeConfig.blockSizeVertical! * 48,
                  child: Stack(alignment: Alignment.center, children: [
                    Container(
                      width: SizeConfig.blockSizeHorizontal! * 95,
                      height: SizeConfig.blockSizeVertical! * 45,
                      color: const Color.fromARGB(255, 240, 217, 181),
                    ),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      controller: _scrollController,
                      crossAxisCount: 3,
                      crossAxisSpacing: 15,
                      mainAxisSpacing: 15,
                      children: List.generate(9, (index) {
                        return tiles[index] == " " && myTurn
                            ? TicTacToeButton(
                                index: index,
                                mySymbol: mySymbol,
                                tiles: tiles,
                                opponent: opponent,
                              )
                            : TextButton(
                                style: ButtonStyle(
                                  overlayColor: MaterialStateColor.resolveWith(
                                      (states) => Colors.transparent),
                                  backgroundColor: MaterialStateProperty.all(
                                      const Color.fromARGB(255, 45, 41, 43)),
                                ),
                                onPressed: () {},
                                child: Center(
                                  child: Text(
                                    tiles[index] as String,
                                    style: const TextStyle(
                                        fontSize: 75,
                                        fontWeight: FontWeight.bold,
                                        color:
                                            Color.fromARGB(255, 240, 217, 181)),
                                  ),
                                ));
                      }),
                    )
                  ])),
              SizedBox(height: SizeConfig.blockSizeVertical! * 2),
              SizedBox(
                height: 150,
                width: SizeConfig.blockSizeHorizontal! * 100,
                child: Container(
                  color: const Color.fromARGB(255, 74, 70, 72),
                  child: InkWell(
                    onTap: () {},
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: SizeConfig.blockSizeHorizontal! * 5,
                        ),
                        Container(
                          width: 100,
                          height: 100,
                          decoration: const BoxDecoration(
                              color: Color.fromARGB(255, 45, 41, 43),
                              shape: BoxShape.circle),
                        ),
                        SizedBox(
                          width: SizeConfig.blockSizeHorizontal! * 5,
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                Auth().user != null
                                    ? Auth().user!.displayName as String
                                    : "Player",
                                style: const TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.bold,
                                    color: Color.fromARGB(255, 240, 217, 181))),
                            Text(mySymbol,
                                style: const TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.bold,
                                    color: Color.fromARGB(255, 240, 217, 181))),
                          ],
                        ),
                        Expanded(
                          child: Container(),
                        ),
                        SizedBox(
                          height: SizeConfig.blockSizeHorizontal! * 15,
                          width: SizeConfig.blockSizeHorizontal! * 15,
                          child: TextButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    const Color.fromARGB(255, 128, 128, 128)),
                            child: Icon(
                              Icons.settings,
                              size: SizeConfig.blockSizeHorizontal! * 10,
                              color: const Color.fromARGB(255, 240, 217, 181),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: SizeConfig.blockSizeHorizontal! * 5,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ]),
      ),
    );
  }
}

class TicTacToeButton extends StatelessWidget {
  TicTacToeButton(
      {super.key,
      required this.index,
      required this.mySymbol,
      required this.tiles,
      required this.opponent});
  final int index;
  final String mySymbol;
  final List<Object?> tiles;
  final String opponent;

  final Singleton _singleton = Singleton();

  void makeMove() {
    DatabaseReference ref =
        FirebaseDatabase.instance.ref("games/${_singleton.currentGame}");
    tiles[index] = mySymbol;
    ref.update({"buttons": tiles, "turn": opponent});
  }

  @override
  Widget build(BuildContext context) {
    return TextButton(
        style: ButtonStyle(
          overlayColor:
              MaterialStateColor.resolveWith((states) => Colors.transparent),
          backgroundColor:
              MaterialStateProperty.all(const Color.fromARGB(255, 45, 41, 43)),
        ),
        onPressed: () {
          makeMove();
        },
        child: Center(
          child: Text(
            tiles[index] as String,
            style: const TextStyle(
                fontSize: 75,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 240, 217, 181)),
          ),
        ));
  }
}
