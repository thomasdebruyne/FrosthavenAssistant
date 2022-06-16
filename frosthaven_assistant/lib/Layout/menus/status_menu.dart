import 'dart:math';

import 'package:flutter/material.dart';
import 'package:frosthaven_assistant/Layout/menus/set_character_level_menu.dart';
import 'package:frosthaven_assistant/Layout/menus/set_level_menu.dart';
import 'package:frosthaven_assistant/Resource/scaling.dart';

import '../../Resource/commands.dart';
import '../../Resource/game_methods.dart';
import '../../Resource/game_state.dart';
import '../../services/service_locator.dart';
import 'main_menu.dart';

class StatusMenu extends StatefulWidget {
  const StatusMenu({Key? key, required this.figure, this.character})
      : super(key: key);

  final Figure figure;
  final Character? character;

  @override
  _StatusMenuState createState() => _StatusMenuState();
}

class _StatusMenuState extends State<StatusMenu> {
  final GameState _gameState = getIt<GameState>();

  @override
  initState() {
    // at the beginning, all items are shown
    super.initState();
  }

  bool isConditionActive(Condition condition, Figure figure) {
    bool isActive = false;
    for (var item in figure.conditions.value) {
      if (item == condition) {
        isActive = true;
        break;
      }
    }
    return isActive;
  }

  void activateCondition(Condition condition, Figure figure) {
    //TODO: handle special case for chill
    List<Condition> newList = [];
    newList.addAll(figure.conditions.value);
    newList.add(condition);
    figure.conditions.value = newList;
  }

  Widget buildCounterButtons(
      ValueNotifier<int> notifier, int maxValue, String image) {
    return Row(children: [
      Container(
          width: 42,
          height: 42,
          child: IconButton(
            icon: Image.asset('assets/images/psd/sub.png'),
            //iconSize: 30,
            onPressed: () {
              if (notifier.value > 0) {
                _gameState.action(ChangeStatCommand(-1, notifier));
              }
              //increment
            },
          )),
      Container(
        width: 42,
        height: 42,
        child: Image(
          image: AssetImage(image),
        ),
      ),
      Container(
          width: 42,
          height: 42,
          child: IconButton(
            icon: Image.asset('assets/images/psd/add.png'),
            //iconSize: 30,
            onPressed: () {
              print("kuken");
              print(maxValue);
              if (notifier.value < maxValue) {
                _gameState.action(ChangeStatCommand(1, notifier));
              }
              //increment
            },
          )),
    ]);
  }

  Widget buildConditionButton(Condition condition) {
    return ValueListenableBuilder<List<Condition>>(
        valueListenable: widget.figure.conditions,
        builder: (context, value, child) {
          Color color = Colors.transparent;
          bool isActive = isConditionActive(condition, widget.figure);
          if (isActive) {
            color = Colors.black;
          }
          return SizedBox(
              width: 42,
              height: 42,
              child: Container(
                  decoration: BoxDecoration(
                      border: Border.all(
                        color: color,
                      ),
                      borderRadius:
                          const BorderRadius.all(Radius.circular(30))),
                  child: IconButton(
                    icon: Image.asset(
                        'assets/images/conditions/${condition.name}.png'),
                    //iconSize: 30,
                    onPressed: () {
                      if (!isActive) {
                        _gameState.action(AddConditionCommand(condition, widget.figure));
                      } else {
                        _gameState.action(RemoveConditionCommand(condition, widget.figure));
                      }
                    },
                  )));
        });
  }

  @override
  Widget build(BuildContext context) {
    //for use with ColorFiltered widget
    /*Map<String, List<double>> predefinedFilters = {
      'Identity': [
        //R  G   B    A  Const
        1, 0, 0, 0, 0, //
        0, 1, 0, 0, 0, //
        0, 0, 1, 0, 0, //
        0, 0, 0, 1, 0, //
      ],
      'Grey Scale': [
        //R  G   B    A  Const
        0.33, 0.59, 0.11, 0, 0, //
        0.33, 0.59, 0.11, 0, 0, //
        0.33, 0.59, 0.11, 0, 0, //
        0, 0, 0, 1, 0, //
      ],
      'Inverse': [
        //R  G   B    A  Const
        -1, 0, 0, 0, 255, //
        0, -1, 0, 0, 255, //
        0, 0, -1, 0, 255, //
        0, 0, 0, 1, 0, //
      ],
      'Sepia': [
        //R  G   B    A  Const
        0.393, 0.769, 0.189, 0, 0, //
        0.349, 0.686, 0.168, 0, 0, //
        0.272, 0.534, 0.131, 0, 0, //
        0, 0, 0, 1, 0, //
      ],
    };*/
    return Container(
        width: 320,
        height: 210,
        decoration: const BoxDecoration(
          //color: Colors.black,
          //borderRadius: BorderRadius.all(Radius.circular(8)),

          /*border: Border.fromBorderSide(BorderSide(
            color: Colors.blueGrey,
            width: 10
          )),*/
          image: DecorationImage(
            image: AssetImage('assets/images/bg/white_bg.png'),
            fit: BoxFit.fitWidth,
          ),
        ),
        child: Row(children: [
          ValueListenableBuilder<int>(
              valueListenable: widget.figure.maxHealth,
              builder: (context, value, child) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    buildCounterButtons(
                        widget.figure.health,
                        widget.figure.maxHealth.value,
                        "assets/images/blood.png"),
                    widget.character != null
                        ? buildCounterButtons(
                            widget.character!.characterState.xp,
                            900,
                            "assets/images/psd/xp.png")
                        : Container(),
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          child: IconButton(
                            icon: Image.asset('assets/images/psd/skull.png'),
                            //iconSize: 10,
                            onPressed: () {
                              widget.figure.health.value = 0;
                            },
                          ),
                        ),
                        Container(
                            width: 42,
                            height: 42,
                            child: IconButton(
                              icon: Image.asset(
                                  colorBlendMode: BlendMode.multiply,
                                  'assets/images/psd/level.png'),
                              //iconSize: 10,
                              onPressed: () {
                                if (widget.figure is CharacterState) {
                                  openDialog(
                                    context,
                                    Dialog(
                                      child: SetCharacterLevelMenu(
                                          character: widget.character!),
                                    ),
                                  );
                                } else {
                                  openDialog(
                                    context,
                                    const Dialog(
                                      child:
                                          SetLevelMenu(), //TODO: add figure to this menu so that monster types can be leveled separately from scenario leve
                                    ),
                                  );
                                }
                              },
                            )),
                      ],
                    )
                  ], //three +/- button groups and then kill/setlevel buttons
                );
              }),
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(
                height: 20,
              ),
              //const Text("Set Scenario Level", style: TextStyle(fontSize: 18)),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  buildConditionButton(Condition.stun),
                  buildConditionButton(Condition.immobilize),
                  buildConditionButton(Condition.disarm),
                  buildConditionButton(Condition.wound),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  buildConditionButton(Condition.muddle),
                  buildConditionButton(Condition.poison),
                  buildConditionButton(Condition.bane),
                  buildConditionButton(Condition.brittle),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  buildConditionButton(Condition.infect),
                  buildConditionButton(Condition.impair),
                  buildConditionButton(Condition.rupture),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  buildConditionButton(Condition.strengthen),
                  buildConditionButton(Condition.invisible),
                  buildConditionButton(Condition.regenerate),
                  buildConditionButton(Condition.ward),
                ],
              ),
            ],
          ),
        ]));
  }
}

//- hp +      4x4 columns of status (different for enemies. can depend on certain character or certain scenario/monster (but not for jotl. so not need implement yet)
//- xp +
//or
//- bless +
//- curse +
// kill, set level