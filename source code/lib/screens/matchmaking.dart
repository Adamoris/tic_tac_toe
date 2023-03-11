import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:tic_tac_toe/shared/loading.dart';
import 'package:tic_tac_toe/size_config.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:tic_tac_toe/services/services.dart';

class MatchmakingScreen extends StatelessWidget {
  MatchmakingScreen({super.key});

  final Singleton _singleton = Singleton();
  StreamSubscription<DatabaseEvent>? queueListener;
  StreamSubscription<DatabaseEvent>? statusListener;

  Future joinQueue() async {
    // TO BE REPLACED WITH CLOUD FUNCTION
    if (Auth().user != null && statusListener == null) {
      DatabaseReference ref =
          FirebaseDatabase.instance.ref("matchmaking/${Auth().user!.uid}");
      await ref.set({
        "status": "pending",
        "username": Auth().user?.displayName,
      }).then(
        (value) {
          statusListener = ref.onChildChanged.listen(
            (event) {
              if (event.snapshot.key == "status" &&
                  event.snapshot.value != "pending") {
                print("Game found! ${event.snapshot.value}");
                _singleton.currentGame = event.snapshot.value as String;
                leaveQueue();
              }
            },
          );
        },
      );
    }
  }

  Future leaveQueue() async {
    DatabaseReference ref =
        FirebaseDatabase.instance.ref("matchmaking/${Auth().user!.uid}");
    await ref.remove().then((value) {
      queueListener?.cancel().then(
            (value) => statusListener?.cancel(),
          );
      return null;
    });
  }

  Future findMatch(BuildContext context) async {
    // TO BE REPLACED WITH CLOUD FUNCTION
    if (Auth().user != null && queueListener == null) {
      DatabaseReference ref = FirebaseDatabase.instance.ref("matchmaking");
      queueListener = ref.onValue.listen((event) async {
        for (final child in event.snapshot.children) {
          if (Auth().user?.uid != child.key) {
            for (final node in child.children) {
              if (node.key == "status" && node.value == "pending") {
                print("THE PATH: matchmaking/${Auth().user!.uid}");
                DatabaseReference myRef = FirebaseDatabase.instance
                    .ref("matchmaking/${Auth().user!.uid}");
                DatabaseReference theirRef =
                    FirebaseDatabase.instance.ref("matchmaking/${child.key}");

                if (_singleton.currentGame == null) {
                  print("I am the initiator.");
                  String gameID = generateGameID();
                  _singleton.currentGame = gameID;

                  theirRef.update({"status": gameID}).then((value) {
                    myRef.update({"status": gameID}).then(
                      (value) {
                        localStartMatch(gameID, child.key!).then((value) {
                          Navigator.pushNamed(context, '/gameScreen');
                          return null;
                        });
                      },
                    );
                  });
                } else {
                  print("Someone else added me.");
                  Navigator.pushNamed(context, '/gameScreen');
                }
              }
            }
          }
        }
      }, onError: (error) {});
    }
  }

  Future localStartMatch(String gameId, String opponent) async {
    // TO BE REPLACED WITH CLOUD FUNCTION
    DatabaseReference ref = FirebaseDatabase.instance.ref("games/$gameId");
    var rng = Random();
    int myTurn = rng.nextInt(2);
    print("I am starting the match.");
    await ref.set({
      "buttons": {
        "0": " ",
        "1": " ",
        "2": " ",
        "3": " ",
        "4": " ",
        "5": " ",
        "6": " ",
        "7": " ",
        "8": " ",
      },
      "win": "pending",
      "turn": myTurn == 0 ? Auth().user?.uid : opponent,
      "players": {
        Auth().user?.uid: myTurn == 0 ? "X" : "O",
        opponent: myTurn == 0 ? "O" : "X"
      }
    }).then((value) => leaveQueue());
  }

  String generateGameID() {
    const String possibleChars =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
    String gameId = "";
    var rng = Random();
    for (int i = 0; i < 20; i++) {
      gameId += possibleChars[rng.nextInt(possibleChars.length)];
    }
    return gameId;
  }

  @override
  Widget build(BuildContext context) {
    joinQueue();
    findMatch(context);
    return Scaffold(
      body: Container(
        alignment: Alignment.center,
        child:
            Column(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          const Text("Finding opponent...",
              style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 240, 217, 181))),
          const LoadingWheel(),
          SizedBox(
              width: SizeConfig.blockSizeHorizontal! * 75,
              height: 60,
              child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      backgroundColor:
                          const Color.fromARGB(255, 236, 135, 115)),
                  onPressed: () {
                    leaveQueue().then((value) {
                      Navigator.pop(context);
                    });
                  },
                  child: const Text('Cancel',
                      style: TextStyle(
                          fontSize: 30,
                          color: Color.fromARGB(255, 255, 255, 255))))),
        ]),
      ),
    );
  }
}
