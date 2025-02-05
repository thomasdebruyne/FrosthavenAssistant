import 'package:flutter/material.dart';
import 'package:frosthaven_assistant/Layout/menus/numpad_menu.dart';
import 'package:frosthaven_assistant/Layout/menus/status_menu.dart';
import 'package:frosthaven_assistant/Resource/commands/set_init_command.dart';
import 'package:frosthaven_assistant/Resource/game_methods.dart';
import 'package:frosthaven_assistant/Resource/scaling.dart';
import '../Resource/color_matrices.dart';
import '../Resource/commands/next_turn_command.dart';
import '../Resource/enums.dart';
import '../Resource/game_state.dart';
import '../Resource/settings.dart';
import '../Resource/ui_utils.dart';
import '../services/service_locator.dart';
import 'menus/add_summon_menu.dart';
import 'monster_box.dart';

class CharacterWidget extends StatefulWidget {
  static final Set<String> localCharacterInitChanges =
      {}; //if it's been changed locally then it's not hidden
  final String characterId;
  final int? initPreset;

  const CharacterWidget(
      {required this.characterId, required this.initPreset, Key? key})
      : super(key: key);

  @override
  CharacterWidgetState createState() => CharacterWidgetState();
}

class CharacterWidgetState extends State<CharacterWidget> {
  final GameState _gameState = getIt<GameState>();
  late bool isCharacter = true;
  final _initTextFieldController = TextEditingController();
  late List<MonsterInstance> lastList = [];
  late Character character;
  final focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    for (var item in _gameState.currentList) {
      if (item.id == widget.characterId) {
        character = item as Character;
      }
    }
    lastList = character.characterState.summonList.value;

    if (widget.initPreset != null) {
      _initTextFieldController.text = widget.initPreset.toString();
    }
    _initTextFieldController.addListener(() {
      for (var item in _gameState.currentList) {
        if (item is Character) {
          if (item.id == character.id) {
            if (_initTextFieldController.value.text.isNotEmpty &&
                _initTextFieldController.value.text !=
                    character.characterState.initiative.value.toString() &&
                _initTextFieldController.value.text.isNotEmpty &&
                _initTextFieldController.value.text != "??") {
              int? init = int.tryParse(_initTextFieldController.value.text);
              if (init != null && init != 0) {
                CharacterWidget.localCharacterInitChanges.add(character.id);
                _gameState.action(
                    SetInitCommand(character.id, init));
              }
            }
            break;
          }
        }
      }
    });

    if (character.characterClass.name == "Objective" ||
        character.characterClass.name == "Escort") {
      isCharacter = false;
      //widget.character.characterState.initiative = widget.initPreset!;
    }
    if (isCharacter) {
      _initTextFieldController.clear();
    }
    if (_gameState.roundState.value == RoundState.playTurns) {
      CharacterWidget.localCharacterInitChanges.clear();
    }
  }

  //TODO: try wrap
  List<Image> createConditionList(double scale) {
    List<Image> list = [];
    String suffix = "";
    if (GameMethods.isFrosthavenStyle()) {
      suffix = "_fh";
    }
    for (var item in character.characterState.conditions.value) {
      String imagePath = "assets/images/abilities/${item.name}.png";
      if (suffix.isNotEmpty && hasGHVersion(item.name)) {
        imagePath = "assets/images/abilities/${item.name}$suffix.png";
      }
      Image image = Image(
        height: 16 * scale,
        image: AssetImage(imagePath),
      );
      list.add(image);
    }
    return list;
  }

  Widget summonsButton(double scale) {
    return SizedBox(
        width: 30 * scale,
        height: 30 * scale,
        child: IconButton(
          padding: EdgeInsets.zero,
          icon: Image.asset(
              fit: BoxFit.fitHeight,
              color: Colors.white24,
              colorBlendMode: BlendMode.modulate,
              'assets/images/psd/add.png'),
          onPressed: () {
            openDialog(
              context,
              //problem: context is of stat card widget, not the + button
              AddSummonMenu(
                character: character,
              ),
            );
          },
        ));
  }

  Widget buildMonsterBoxGrid(double scale) {
    String displayStartAnimation = "";

    if (lastList.length < character.characterState.summonList.value.length) {
      //find which is new - always the last one
      displayStartAnimation =
          character.characterState.summonList.value.last.getId();
    }

    final generatedChildren = List<Widget>.generate(
        character.characterState.summonList.value.length,
        (index) => AnimatedSize(
              //not really needed now
              key: Key(index.toString()),
              duration: const Duration(milliseconds: 300),
              child: MonsterBox(
                  key: Key(
                      character.characterState.summonList.value[index].getId()),
                  figureId: character
                          .characterState.summonList.value[index].name +
                      character.characterState.summonList.value[index].gfx +
                      character.characterState.summonList.value[index].standeeNr
                          .toString(),
                  ownerId: character.id,
                  displayStartAnimation: displayStartAnimation),
            ));
    lastList = character.characterState.summonList.value;
    return Wrap(
      runSpacing: 2.0 * scale,
      spacing: 2.0 * scale,
      children: generatedChildren,
    );
  }

  @override
  Widget build(BuildContext context) {
    double scale = getScaleByReference(context);
    double scaledHeight = 60 * scale;

    for (var item in _gameState.currentList) {
      if (item.id == widget.characterId) {
        character = item as Character;
      }
    }

    return InkWell(
        onTap: () {
          //open stats menu
          openDialog(
            context,
            StatusMenu(figureId: character.id, characterId: character.id),
          );
        },
        child: ValueListenableBuilder<dynamic>(
            valueListenable: getIt<GameState>().updateList,
            //TODO: is this even needed?
            builder: (context, value, child) {
              bool frosthavenStyle = GameMethods.isFrosthavenStyle();

              var shadow = Shadow(
                offset: Offset(1 * scale, 1 * scale),
                color: Colors.black87,
                blurRadius: 1 * scale,
              );
              return ColorFiltered(
                  colorFilter: character.characterState.health.value != 0 &&
                          (character.turnState != TurnsState.done ||
                              getIt<GameState>().roundState.value ==
                                  RoundState.chooseInitiative)
                      ? ColorFilter.matrix(identity)
                      : ColorFilter.matrix(grayScale),
                  child: Column(mainAxisSize: MainAxisSize.max, children: [
                    Container(
                      //padding: EdgeInsets.zero,
                      // color: Colors.amber,
                      //height: 50,
                      margin: EdgeInsets.only(
                          left: 4 * scale * 0.8, right: 4 * scale * 0.8),
                      width: getMainListWidth(context) - 8 * scale * 0.8,
                      child: ValueListenableBuilder<int>(
                          valueListenable:
                              getIt<GameState>().killMonsterStandee,
                          // widget.data.monsterInstances,
                          builder: (context, value, child) {
                            return buildMonsterBoxGrid(scale);
                          }),
                    ),
                    PhysicalShape(
                        //TODO: needs to be more shiny
                        color: character.turnState == TurnsState.current
                            ? Colors.tealAccent
                            : Colors.transparent,
                        shadowColor: Colors.black,
                        elevation: 8,
                        clipper: const ShapeBorderClipper(
                            shape: RoundedRectangleBorder()),
                        child: SizedBox(
                            width: getMainListWidth(context),
                            // 408 * scale,
                            height: 60 * scale,
                            child: Stack(
                              //alignment: Alignment.centerLeft,
                              children: [
                                Container(
                                  //background
                                  margin: EdgeInsets.all(2 * scale),
                                  width: 408 * scale,
                                  height: 58 * scale,
                                  decoration: BoxDecoration(
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black45,
                                        blurRadius: 4 * scale,
                                        offset: Offset(2 * scale,
                                            4 * scale), // Shadow position
                                      ),
                                    ],
                                    image: DecorationImage(
                                        fit: BoxFit.fill,
                                        colorFilter: ColorFilter.mode(
                                            character.characterClass.color,
                                            BlendMode.color),
                                        image: const AssetImage(
                                            "assets/images/psd/character-bar.png")),
                                    shape: BoxShape.rectangle,
                                    color: character.characterClass.color,
                                  ),
                                ),
                                Row(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.6),
                                            spreadRadius: 4,
                                            blurRadius: 13.0 * scale,
                                            //offset: Offset(1* settings.userScalingBars.value, 1* settings.userScalingBars.value), // changes position of shadow
                                          ),
                                        ],
                                      ),
                                      margin: EdgeInsets.only(
                                          left: 26 * scale,
                                          top: 5 * scale,
                                          bottom: 5 * scale),
                                      child: Image(
                                        fit: BoxFit.contain,
                                        height: scaledHeight * 0.6,
                                        color: isCharacter
                                            ? character.characterClass.color
                                            : null,
                                        filterQuality: FilterQuality.medium,
                                        image: AssetImage(
                                          "assets/images/class-icons/${character.characterClass.name}.png",
                                        ),
                                        width: scaledHeight * 0.6,
                                      ),
                                    ),
                                    Column(children: [
                                      Container(
                                        margin: EdgeInsets.only(
                                            top: scaledHeight / 6,
                                            left: 10 * scale),
                                        child: Image(
                                          //fit: BoxFit.contain,
                                          height: scaledHeight * 0.1,
                                          image: const AssetImage(
                                              "assets/images/init.png"),
                                        ),
                                      ),
                                      ValueListenableBuilder<int>(
                                          valueListenable: character
                                              .characterState.initiative,
                                          builder: (context, value, child) {
                                            bool secret = (getIt<Settings>()
                                                .server
                                                .value ||
                                                getIt<Settings>()
                                                    .client
                                                    .value) &&
                                                (!CharacterWidget
                                                    .localCharacterInitChanges
                                                    .contains(character.id));
                                            if (_initTextFieldController.text !=
                                                    character.characterState
                                                        .initiative.value
                                                        .toString() &&
                                                character.characterState
                                                        .initiative.value !=
                                                    0 && (_initTextFieldController.text.isNotEmpty || secret)) {
                                              //handle secret if originating from other device

                                              if (secret) {
                                                _initTextFieldController.text =
                                                    "??";
                                              } else {
                                                _initTextFieldController.text =
                                                    character.characterState
                                                        .initiative.value
                                                        .toString();
                                              }
                                            }
                                            if (_gameState.roundState.value ==
                                                    RoundState.playTurns &&
                                                isCharacter) {
                                              _initTextFieldController.clear();
                                            }

                                            /*if (isCharacter && _gameState.commandIndex.value >= 0 &&
                                                _gameState.commands[_gameState.commandIndex.value] is DrawCommand) {
                                              _initTextFieldController.clear();
                                            }*/

                                            if (_gameState.roundState.value ==
                                                    RoundState
                                                        .chooseInitiative &&
                                                character.characterState.health
                                                        .value >
                                                    0) {
                                              return Container(
                                                margin: EdgeInsets.only(
                                                    left: 11 * scale,
                                                    top: scaledHeight * 0.11),
                                                height: scaledHeight * 0.5,
                                                //33 * scale,
                                                width: 25 * scale,
                                                padding: EdgeInsets.zero,
                                                alignment: Alignment.topCenter,
                                                child: TextField(
                                                    focusNode: focusNode,

                                                    //scrollPadding: EdgeInsets.zero,
                                                    onTap: () {
                                                      //clear on enter focus
                                                      _initTextFieldController
                                                          .clear();
                                                      if (getIt<Settings>()
                                                          .softNumpadInput
                                                          .value) {
                                                        openDialog(
                                                            context,
                                                            NumpadMenu(
                                                              controller:
                                                                  _initTextFieldController,
                                                              maxLength: 2,
                                                            ));
                                                      }
                                                    },
                                                    onChanged: (String str) {
                                                      //close soft keyboard on 2 chars entered
                                                      if (str.length == 2) {
                                                        FocusManager.instance
                                                            .primaryFocus
                                                            ?.unfocus();
                                                      }
                                                    },

                                                    //expands: true,
                                                    textAlign: TextAlign.center,
                                                    cursorColor: Colors.white,
                                                    maxLength: 2,
                                                    style: TextStyle(
                                                        height: 1,
                                                        //quick fix for web-phone disparity.
                                                        fontFamily:
                                                            frosthavenStyle
                                                                ? 'GermaniaOne'
                                                                : 'Pirata',
                                                        color: Colors.white,
                                                        fontSize: 24 * scale,
                                                        shadows: [shadow]),
                                                    decoration:
                                                        const InputDecoration(
                                                      isDense: true,
                                                      //this is what fixes the height issue
                                                      counterText: '',
                                                      contentPadding:
                                                          EdgeInsets.zero,
                                                      enabledBorder:
                                                          UnderlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius.zero,
                                                        borderSide: BorderSide(
                                                            width: 0,
                                                            color: Colors
                                                                .transparent),
                                                      ),
                                                      focusedBorder:
                                                          UnderlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius.zero,
                                                        borderSide: BorderSide(
                                                            width: 0,
                                                            color: Colors
                                                                .transparent),
                                                      ),
                                                      // border: UnderlineInputBorder(
                                                      //   borderSide:
                                                      //      BorderSide(color: Colors.pink),
                                                      // ),
                                                    ),
                                                    controller:
                                                        _initTextFieldController,
                                                    keyboardType:
                                                        getIt<Settings>()
                                                                .softNumpadInput
                                                                .value
                                                            ? TextInputType.none
                                                            : TextInputType
                                                                .number),
                                              );
                                            } else {
                                              if (isCharacter) {
                                                _initTextFieldController
                                                    .clear();
                                              }
                                              return Container(
                                                  height: 33 * scale,
                                                  width: 25 * scale,
                                                  margin: EdgeInsets.only(
                                                      left: 10 * scale),
                                                  child: Text(
                                                    character.characterState.health
                                                                    .value >
                                                                0 &&
                                                            character
                                                                    .characterState
                                                                    .initiative
                                                                    .value >
                                                                0
                                                        ? character
                                                            .characterState
                                                            .initiative
                                                            .value
                                                            .toString()
                                                        : "",
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                        fontFamily:
                                                            frosthavenStyle
                                                                ? 'GermaniaOne'
                                                                : 'Pirata',
                                                        color: Colors.white,
                                                        fontSize: 24 * scale,
                                                        shadows: [shadow]),
                                                  ));
                                            }
                                          }),
                                    ]),
                                    Column(
                                        //mainAxisAlignment: MainAxisAlignment.start,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        //align children to the left
                                        children: [
                                          Container(
                                            margin: EdgeInsets.only(
                                                top: 10 * scale,
                                                left: 10 * scale),
                                            child: Text(
                                              character.characterState.display,
                                              style: TextStyle(
                                                  fontFamily: frosthavenStyle
                                                      ? 'GermaniaOne'
                                                      : 'Pirata',
                                                  color: Colors.white,
                                                  fontSize: frosthavenStyle
                                                      ? 15 * scale
                                                      : 16 * scale,
                                                  shadows: [shadow]),
                                            ),
                                          ),
                                          ValueListenableBuilder<int>(
                                              valueListenable: character
                                                  .characterState.health,
                                              //not working?
                                              builder: (context, value, child) {
                                                return Container(
                                                    margin: EdgeInsets.only(
                                                        left: 10 * scale),
                                                    child: Row(children: [
                                                      Image(
                                                        fit: BoxFit.contain,
                                                        height:
                                                            scaledHeight * 0.2,
                                                        image: const AssetImage(
                                                            "assets/images/blood.png"),
                                                      ),
                                                      Text(
                                                        frosthavenStyle
                                                            ? '${character.characterState.health.value.toString()}/${character.characterState.maxHealth.value.toString()}'
                                                            : '${character.characterState.health.value.toString()} / ${character.characterState.maxHealth.value.toString()}',
                                                        style: TextStyle(
                                                            fontFamily:
                                                                frosthavenStyle
                                                                    ? 'GermaniaOne'
                                                                    : 'Pirata',
                                                            color: Colors.white,
                                                            fontSize: frosthavenStyle ? 16 * scale : 16 * scale,
                                                            shadows: [shadow]),
                                                      ),
                                                      //add conditions here
                                                      ValueListenableBuilder<
                                                              List<Condition>>(
                                                          valueListenable:
                                                              character
                                                                  .characterState
                                                                  .conditions,
                                                          builder: (context,
                                                              value, child) {
                                                            return Row(
                                                              children:
                                                                  createConditionList(
                                                                      scale),
                                                            );
                                                          }),
                                                    ]));
                                              })
                                        ])
                                  ],
                                ),
                                isCharacter
                                    ? Positioned(
                                        top: 10 * scale,
                                        left: 314 * scale,
                                        child: Row(
                                          children: [
                                            Image(
                                              height: 20.0 * scale * 0.8,
                                              color: Colors.blue,
                                              colorBlendMode:
                                                  BlendMode.modulate,
                                              image: const AssetImage(
                                                  "assets/images/psd/xp.png"),
                                            ),
                                            ValueListenableBuilder<int>(
                                                valueListenable:
                                                    character.characterState.xp,
                                                builder:
                                                    (context, value, child) {
                                                  return Text(
                                                    character
                                                        .characterState.xp.value
                                                        .toString(),
                                                    style: TextStyle(
                                                        fontFamily:
                                                            frosthavenStyle
                                                                ? 'GermaniaOne'
                                                                : 'Pirata',
                                                        color: Colors.blue,
                                                        fontSize: 14 * scale,
                                                        shadows: [shadow]),
                                                  );
                                                }),
                                          ],
                                        ))
                                    : Container(),
                                isCharacter
                                    ? Positioned(
                                        top: 28 * scale,
                                        left: 316 * scale,
                                        child: Row(
                                          children: [
                                            Image(
                                              height: 12.0 * scale,
                                              image: const AssetImage(
                                                  "assets/images/psd/level.png"),
                                            ),
                                            ValueListenableBuilder<int>(
                                                valueListenable: character
                                                    .characterState.level,
                                                builder:
                                                    (context, value, child) {
                                                  return Text(
                                                    character.characterState
                                                        .level.value
                                                        .toString(),
                                                    style: TextStyle(
                                                        fontFamily:
                                                            frosthavenStyle
                                                                ? 'GermaniaOne'
                                                                : 'Pirata',
                                                        color: Colors.white,
                                                        fontSize: 14 * scale,
                                                        shadows: [shadow]),
                                                  );
                                                }),
                                          ],
                                        ))
                                    : Container(),
                                isCharacter
                                    ? Positioned(
                                        right: 29 * scale,
                                        top: 14 * scale,
                                        child: summonsButton(scale),
                                      )
                                    : Container(),
                                if (character.characterState.health.value > 0)
                                  InkWell(
                                      onTap: () {
                                        if (_gameState.roundState.value ==
                                            RoundState.chooseInitiative) {
                                          //if in choose mode - focus the input or open the soft numpad if that option is on
                                          if (getIt<Settings>()
                                                  .softNumpadInput
                                                  .value ==
                                              true) {
                                            openDialog(
                                                context,
                                                NumpadMenu(
                                                  controller:
                                                      _initTextFieldController,
                                                  maxLength: 2,
                                                ));
                                          } else {
                                            //focus on
                                            focusNode.requestFocus();
                                          }
                                        } else {
                                          getIt<GameState>().action(
                                              TurnDoneCommand(character.id));
                                        }
                                        //if in choose mode - focus the input or open the soft numpad if that option is on
                                        //else: mark as done
                                      },
                                      child: SizedBox(
                                        height: 60 * scale,
                                        width: 70 * scale,
                                      )),
                              ],
                            ))),
                  ]));
            }));
  }
}
