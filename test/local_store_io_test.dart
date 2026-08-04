import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:savetep/data/local/local_store_io.dart';

void main() {
  test(
    'native local storage uses the writable application support path',
    () async {
      final Directory supportDirectory = await Directory.systemTemp.createTemp(
        'savetep-local-store-test-',
      );
      addTearDown(() => supportDirectory.delete(recursive: true));

      await writeLocalValue(
        'transactions',
        '{"saved":true}',
        directoryProvider: () async => supportDirectory,
      );

      final File file = await localStoreFile(
        'transactions',
        directoryProvider: () async => supportDirectory,
      );
      expect(file.path, isNot(contains('Directory:')));
      expect(file.parent.path, isNotEmpty);
      expect(await file.exists(), isTrue);
      expect(
        await readLocalValue(
          'transactions',
          directoryProvider: () async => supportDirectory,
        ),
        '{"saved":true}',
      );
    },
  );
}
