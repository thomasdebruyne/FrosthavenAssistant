import 'package:flutter/material.dart';
import 'package:frosthaven_assistant/Layout/modifier_deck_widget.dart';
import 'package:frosthaven_assistant/Layout/top_bar.dart';
import 'package:frosthaven_assistant/Resource/game_methods.dart';
import 'package:frosthaven_assistant/Resource/game_state.dart';

import '../Model/campaign.dart';
import '../Resource/scaling.dart';
import '../Resource/settings.dart';
import '../services/service_locator.dart';
import 'bottom_bar.dart';
import 'main_list.dart';
import 'menus/main_menu.dart';

Widget createMainScaffold(BuildContext context) {
  return ValueListenableBuilder<double>(
      valueListenable: getIt<Settings>().userScalingBars,
      builder: (context, value, child) {
        bool modFitsOnBar = modifiersFitOnBar(context);
        return SafeArea(
            maintainBottomViewPadding: true,
            child: Scaffold(
              resizeToAvoidBottomInset: false,
              //drawerScrimColor: Colors.yellow,
              bottomNavigationBar: createBottomBar(context),
              appBar: createTopBar(),
              drawer: createMainMenu(context),
              body: Stack(
                children: [
                  const MainList(),
                  ValueListenableBuilder<Map<String, CampaignModel>>(
                      valueListenable: getIt<GameState>().modelData,
                      builder: (context, value, child) {
                        return ValueListenableBuilder<int>(
                            valueListenable: getIt<GameState>().commandIndex,
                            builder: (context, value, child) {
                              return GameMethods.hasAllies()
                                  ? Positioned(
                                      bottom: modFitsOnBar
                                          ? 4
                                          : 40 *
                                                  getIt<Settings>()
                                                      .userScalingBars
                                                      .value +
                                              8,
                                      right: 0,
                                      child: const ModifierDeckWidget(
                                          name: 'Allies'))
                                  : Container();
                            });
                      }),
                  modFitsOnBar
                      ? Container()
                      : const Positioned(
                          bottom: 4,
                          right: 0,
                          child: ModifierDeckWidget(
                            name: '',
                          ))
                ],
              ),
              //floatingActionButton: const ModifierDeckWidget()
            ));
      });
}
