/*
 * Copyright (C) 2022 Canonical Ltd
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 3 as
 * published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 */

import 'package:flutter/material.dart';
import 'package:packagekit/packagekit.dart';
import 'package:provider/provider.dart';
import 'package:snapd/snapd.dart';
import 'package:software/l10n/l10n.dart';
import 'package:software/snapx.dart';
import 'package:software/store_app/common/animated_scroll_view_item.dart';
import 'package:software/store_app/common/constants.dart';
import 'package:software/store_app/explore/explore_model.dart';
import 'package:yaru_icons/yaru_icons.dart';
import 'package:yaru_widgets/yaru_widgets.dart';

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return YaruTabbedPage(
      tabIcons: const [YaruIcons.package_snap, YaruIcons.package_deb],
      tabTitles: [
        context.l10n.snapPackages,
        context.l10n.debianPackages,
      ],
      views: const [
        _SnapSearchPage(),
        _PackageKitSearchPage(),
      ],
    );
  }
}

class _SnapSearchPage extends StatelessWidget {
  // ignore: unused_element
  const _SnapSearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    final model = context.watch<ExploreModel>();

    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: FutureBuilder<List<Snap>>(
        future: model.findSnapsByQuery(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _WaitPage(message: '');
          }

          return snapshot.hasData && snapshot.data!.isNotEmpty
              ? GridView.builder(
                  controller: ScrollController(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  gridDelegate: kGridDelegate,
                  shrinkWrap: true,
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    final snap = snapshot.data![index];
                    return AnimatedScrollViewItem(
                      child: YaruBanner(
                        name: snap.name,
                        summary: snap.summary,
                        url: snap.iconUrl,
                        onTap: () => model.selectedSnap = snap,
                        fallbackIconData: YaruIcons.package_snap,
                      ),
                    );
                  },
                )
              : _NoSearchResultPage(message: context.l10n.noSnapFound);
        },
      ),
    );
  }
}

class _PackageKitSearchPage extends StatefulWidget {
  // ignore: unused_element
  const _PackageKitSearchPage({super.key});

  @override
  State<_PackageKitSearchPage> createState() => _PackageKitSearchPageState();
}

class _PackageKitSearchPageState extends State<_PackageKitSearchPage> {
  @override
  void initState() {
    context.read<ExploreModel>().init();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final model = context.watch<ExploreModel>();

    if (!model.packageKitReady) {
      return _WaitPage(
        message: model.updatesState != null
            ? model.updatesState!.localize(context.l10n)
            : '',
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: FutureBuilder<List<PackageKitPackageId>>(
        future: model.findPackageKitPackageIds(
          filter: {PackageKitFilter.newest, PackageKitFilter.notDevelopment},
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _WaitPage(message: '');
          }
          return snapshot.hasData && snapshot.data!.isNotEmpty
              ? GridView.builder(
                  controller: ScrollController(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  gridDelegate: kGridDelegate,
                  shrinkWrap: true,
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    final id = snapshot.data![index];
                    return YaruBanner(
                      name: id.name,
                      summary: id.version,
                      icon: const Icon(
                        YaruIcons.package_deb,
                        size: 50,
                      ),
                      onTap: () => model.selectedPackage = id,
                      fallbackIconData: YaruIcons.package_deb,
                    );
                  },
                )
              : _NoSearchResultPage(message: context.l10n.noPackageFound);
        },
      ),
    );
  }
}

class _WaitPage extends StatelessWidget {
  const _WaitPage({
    Key? key,
    required this.message,
  }) : super(key: key);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const YaruCircularProgressIndicator(),
          const SizedBox(
            height: 10,
          ),
          SizedBox(
            width: 400,
            child: Text(
              message,
              style:
                  Theme.of(context).textTheme.headline4?.copyWith(fontSize: 25),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(
            height: 200,
          ),
        ],
      ),
    );
  }
}

class _NoSearchResultPage extends StatelessWidget {
  const _NoSearchResultPage({
    Key? key,
    required this.message,
  }) : super(key: key);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '🐣❓',
            style: TextStyle(fontSize: 40),
          ),
          const SizedBox(
            height: 10,
          ),
          SizedBox(
            width: 400,
            child: Text(
              message,
              style:
                  Theme.of(context).textTheme.headline4?.copyWith(fontSize: 25),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(
            height: 200,
          ),
        ],
      ),
    );
  }
}
