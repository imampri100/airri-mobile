import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:airri_mobile/application/irrigation/connectivity_cubit.dart';
import 'package:airri_mobile/application/irrigation/dashboard_cubit.dart';
import 'package:airri_mobile/application/irrigation/history_cubit.dart';
import 'package:airri_mobile/application/irrigation/restriction_form_cubit.dart';
import 'package:airri_mobile/application/irrigation/statistik_cubit.dart';
import 'package:airri_mobile/application/irrigation/sync_service.dart';
import 'package:airri_mobile/application/irrigation/trigger_form_cubit.dart';
import 'package:airri_mobile/domain/irrigation/i_irrigation_repository.dart';
import 'package:airri_mobile/infrastructure/irrigation/device_settings_service.dart';
import 'package:airri_mobile/infrastructure/irrigation/logging_settings_service.dart';
import 'package:airri_mobile/presentation/theme/irrigation_colors.dart';

import 'dashboard_page.dart';
import 'device_address_dialog.dart';
import 'history_page.dart';
import 'restriction_page.dart';
import 'statistik_page.dart';
import 'trigger_page.dart';
import 'widgets/confirm_dialog.dart';

/// Root widget fitur Smart Irrigation: app bar + 5 tab bottom nav, sesuai
/// smart-irrigation-prototype_final.html.
class IrrigationShell extends StatelessWidget {
  final IIrrigationRepository repository;
  final DeviceSettingsService deviceSettings;
  final LoggingSettingsService loggingSettings;
  final SyncService syncService;

  const IrrigationShell({
    super.key,
    required this.repository,
    required this.deviceSettings,
    required this.loggingSettings,
    required this.syncService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => ConnectivityCubit(repository)),
        BlocProvider(create: (_) => DashboardCubit(repository, syncService)),
        BlocProvider(create: (_) => HistoryCubit(syncService)),
        BlocProvider(create: (_) => StatistikCubit(syncService)),
        BlocProvider(create: (_) => TriggerFormCubit(repository)),
        BlocProvider(create: (_) => RestrictionFormCubit(repository)),
      ],
      child: _IrrigationShellBody(
        repository: repository,
        deviceSettings: deviceSettings,
        loggingSettings: loggingSettings,
      ),
    );
  }
}

class _IrrigationShellBody extends StatefulWidget {
  final IIrrigationRepository repository;
  final DeviceSettingsService deviceSettings;
  final LoggingSettingsService loggingSettings;
  const _IrrigationShellBody({
    required this.repository,
    required this.deviceSettings,
    required this.loggingSettings,
  });

  @override
  State<_IrrigationShellBody> createState() => _IrrigationShellBodyState();
}

class _IrrigationShellBodyState extends State<_IrrigationShellBody> {
  int _index = 0;

  List<String> get _titles => [
        'app.name'.tr(),
        'nav.history'.tr(),
        'nav.statistik'.tr(),
        'nav.trigger'.tr(),
        'nav.restriction'.tr(),
      ];

  void _openMenu(BuildContext context) async {
    final selected = await showMenu<String>(
      context: context,
      position: const RelativeRect.fromLTRB(1000, 80, 16, 0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(IrrigationColors.radiusSm),
      ),
      items: [
        PopupMenuItem(value: 'about', child: Text('menu.about_device'.tr())),
        PopupMenuItem(value: 'delete_logs', child: Text('menu.delete_logs'.tr())),
        PopupMenuItem(
          value: 'device_address',
          child: Text('menu.device_address'.tr()),
        ),
        PopupMenuItem(
          value: 'toggle_logging',
          child: Text('menu.request_logging'.tr(namedArgs: {
            'status': widget.loggingSettings.enabled
                ? 'menu.logging_on'.tr()
                : 'menu.logging_off'.tr(),
          })),
        ),
        PopupMenuItem(
          value: 'toggle_language',
          child: Text(context.locale.languageCode == 'id'
              ? '🌐  Language: English'
              : '🌐  Bahasa: Indonesia'),
        ),
        PopupMenuItem(
          value: 'factory_reset',
          child: Text('menu.factory_reset'.tr(),
              style: const TextStyle(color: IrrigationColors.red600)),
        ),
      ],
    );

    if (!context.mounted || selected == null) return;

    switch (selected) {
      case 'about':
        showAboutDialog(
          context: context,
          applicationName: 'app.name'.tr(),
          applicationVersion: '1.0.0',
          children: [
            Text('about.connected_to'
                .tr(namedArgs: {'url': widget.deviceSettings.baseUrl})),
          ],
        );
        break;
      case 'device_address':
        showDeviceAddressDialog(
          context,
          widget.deviceSettings,
          onSaved: () {
            context.read<DashboardCubit>().refresh();
          },
        );
        break;
      case 'toggle_logging':
        final next = !widget.loggingSettings.enabled;
        await widget.loggingSettings.setEnabled(next);
        if (!context.mounted) return;
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(next
                  ? 'snackbar.logging_enabled'.tr()
                  : 'snackbar.logging_disabled'.tr())),
        );
        break;
      case 'toggle_language':
        final next =
            context.locale.languageCode == 'id' ? const Locale('en', 'US') : const Locale('id', 'ID');
        await context.setLocale(next);
        // Best-effort saja, menyinkronkan bahasa decision.reason &
        // layar TFT device ke bahasa app. Device offline tidak
        // masalah, app tetap ganti bahasa; beda bahasa sampai sempat
        // disinkron lagi.
        unawaited(widget.repository.updateDeviceLanguage(next.languageCode));
        break;
      case 'delete_logs':
        final confirmed = await showIrrigationConfirmDialog(
          context,
          title: 'dialog.delete_logs_title'.tr(),
          message: 'dialog.delete_logs_message'.tr(),
          confirmLabel: 'common.delete'.tr(),
        );
        if (confirmed && context.mounted) {
          final error = await context.read<DashboardCubit>().deleteLogs();
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error ?? 'snackbar.logs_deleted'.tr())),
          );
          context.read<HistoryCubit>().refresh();
        }
        break;
      case 'factory_reset':
        final confirmed = await showIrrigationConfirmDialog(
          context,
          title: 'dialog.factory_reset_title'.tr(),
          message: 'dialog.factory_reset_message'.tr(),
          confirmLabel: 'common.reset'.tr(),
        );
        if (confirmed && context.mounted) {
          final error = await context.read<DashboardCubit>().factoryReset();
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error ?? 'snackbar.factory_reset_done'.tr())),
          );
          context.read<TriggerFormCubit>().load();
          context.read<RestrictionFormCubit>().load();
          context.read<HistoryCubit>().refresh();
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: IrrigationColors.canvas,
      appBar: AppBar(
        backgroundColor: IrrigationColors.canvas,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 16,
        title: Text(_titles[_index],
            style: const TextStyle(
                color: IrrigationColors.ink900,
                fontWeight: FontWeight.w700,
                fontSize: 17)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Center(child: _ConnectionPill()),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: IrrigationColors.ink700),
            onPressed: () => _openMenu(context),
          ),
        ],
      ),
      body: IndexedStack(
        index: _index,
        // Sengaja tidak dibuat const. Kalau const, Flutter menganggap
        // widgetnya sama terus (child.widget == newWidget), rebuild
        // jadi ter-skip walaupun ancestornya rebuild. Akibatnya
        // halaman yang tidak membaca context.locale sendiri
        // (TriggerPage/RestrictionPage yang hanya memakai .tr()) tidak
        // ikut refresh saat ganti bahasa, teksnya tertinggal di bahasa
        // lama.
        children: [
          DashboardPage(),
          HistoryPage(),
          StatistikPage(),
          TriggerPage(),
          RestrictionPage(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        backgroundColor: IrrigationColors.surface,
        indicatorColor: IrrigationColors.green100,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined, color: IrrigationColors.ink300),
            selectedIcon:
                const Icon(Icons.home, color: IrrigationColors.green600),
            label: 'nav.dashboard'.tr(),
          ),
          NavigationDestination(
            icon: const Icon(Icons.history, color: IrrigationColors.ink300),
            selectedIcon:
                const Icon(Icons.history, color: IrrigationColors.green600),
            label: 'nav.history'.tr(),
          ),
          NavigationDestination(
            icon: const Icon(Icons.bar_chart_outlined, color: IrrigationColors.ink300),
            selectedIcon:
                const Icon(Icons.bar_chart, color: IrrigationColors.green600),
            label: 'nav.statistik'.tr(),
          ),
          NavigationDestination(
            icon: const Icon(Icons.tune_outlined, color: IrrigationColors.ink300),
            selectedIcon:
                const Icon(Icons.tune, color: IrrigationColors.green600),
            label: 'nav.trigger'.tr(),
          ),
          NavigationDestination(
            icon: const Icon(Icons.block_outlined, color: IrrigationColors.ink300),
            selectedIcon:
                const Icon(Icons.block, color: IrrigationColors.green600),
            label: 'nav.restriction'.tr(),
          ),
        ],
      ),
    );
  }
}

class _ConnectionPill extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConnectivityCubit, ConnectivityState>(
      builder: (context, state) {
        Color color;
        String label;
        switch (state.phase) {
          case ConnectivityPhase.checking:
            color = IrrigationColors.ink500;
            label = 'connection.connecting'.tr();
            break;
          case ConnectivityPhase.connected:
            color = IrrigationColors.green600;
            label = 'connection.connected'.tr();
            break;
          case ConnectivityPhase.offline:
            color = IrrigationColors.red600;
            label = 'connection.offline'.tr();
            break;
        }
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 5),
            Text(label,
                style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w600, color: color)),
          ],
        );
      },
    );
  }
}
