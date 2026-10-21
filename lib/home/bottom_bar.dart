part of '../main.dart';

// Alt gezinme çubuğu.
extension _BottomBar on _HomePageState {
  Widget navigationItem({
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) =>
      Expanded(
          child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(icon,
                        size: 22,
                        color: selected
                            ? NaviloColors.forest
                            : NaviloColors.muted),
                    const SizedBox(height: 3),
                    Text(label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight:
                                selected ? FontWeight.w700 : FontWeight.w500,
                            color: selected
                                ? NaviloColors.forest
                                : NaviloColors.muted)),
                  ]))));

  Widget scanNavigationItem() => Expanded(
      child: Semantics(
          button: true,
          label: copy('Ana sayfa', 'Home'),
          child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => _update(() {
                    page = 0;
                    stage = ScanStage.start;
                  }),
              child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                        width: 43,
                        height: 38,
                        decoration: BoxDecoration(
                            color: NaviloColors.forest,
                            borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.center_focus_strong_rounded,
                            color: Colors.white, size: 21)),
                    const SizedBox(height: 3),
                    Text(copy('Ana sayfa', 'Home'),
                        style: const TextStyle(
                            fontSize: 10, fontWeight: FontWeight.w700)),
                  ])))));

  Widget naviloBottomBar() => SafeArea(
      top: false,
      child: Container(
          height: MediaQuery.textScalerOf(context).scale(1) > 1.3 ? 112 : 68,
          decoration: const BoxDecoration(
              color: NaviloColors.paper,
              border: Border(top: BorderSide(color: NaviloColors.line))),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(children: [
            navigationItem(
                icon: Icons.bookmarks_outlined,
                label: copy('Kütüphane', 'Library'),
                selected: page == 3,
                onTap: () => _update(() => page = 3)),
            scanNavigationItem(),
            navigationItem(
                icon: Icons.tune_rounded,
                label: copy('Profilim', 'Profile'),
                selected: page == 1 || page == 2,
                onTap: () => _update(() => page = 1)),
          ])));
}
