import 'package:comfy_list/features/settings/presentation/providers/app_version_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() {
  test('la versión del pie es año.mes.dia.commits, sin paréntesis', () async {
    PackageInfo.setMockInitialValues(
      appName: 'ComfyList',
      packageName: 'andypr.comfylist',
      version: '2026.10.11',
      buildNumber: '221',
      buildSignature: '',
    );

    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(
      await container.read(appVersionLabelProvider.future),
      '2026.10.11.221',
    );
  });
}
