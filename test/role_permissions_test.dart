import 'package:flutter_test/flutter_test.dart';

import 'package:up04_01_flutter_web/models/app_user.dart';

void main() {
  const reader = AppUser(
    id: 1,
    username: 'reader',
    fullName: 'Reader',
    role: Role.reader,
  );

  const librarian = AppUser(
    id: 2,
    username: 'librarian',
    fullName: 'Librarian',
    role: Role.librarian,
  );

  const admin = AppUser(
    id: 3,
    username: 'admin',
    fullName: 'Admin',
    role: Role.admin,
  );

  group('Иерархические права', () {
    test('reader имеет права reader', () {
      expect(reader.hasRole(Role.reader), isTrue);
    });

    test('reader не имеет права librarian', () {
      expect(reader.hasRole(Role.librarian), isFalse);
    });

    test('reader не имеет права admin', () {
      expect(reader.hasRole(Role.admin), isFalse);
    });

    test('librarian имеет права reader', () {
      expect(librarian.hasRole(Role.reader), isTrue);
    });

    test('librarian имеет права librarian', () {
      expect(librarian.hasRole(Role.librarian), isTrue);
    });

    test('librarian не имеет права admin', () {
      expect(librarian.hasRole(Role.admin), isFalse);
    });

    test('admin имеет права reader', () {
      expect(admin.hasRole(Role.reader), isTrue);
    });

    test('admin имеет права librarian', () {
      expect(admin.hasRole(Role.librarian), isTrue);
    });

    test('admin имеет права admin', () {
      expect(admin.hasRole(Role.admin), isTrue);
    });
  });

  group('Эксклюзивные экраны', () {
    test('reader имеет только reader-only экран', () {
      expect(reader.isExactly(Role.reader), isTrue);
      expect(reader.isExactly(Role.librarian), isFalse);
      expect(reader.isExactly(Role.admin), isFalse);
    });

    test('librarian имеет только librarian-only экран', () {
      expect(librarian.isExactly(Role.reader), isFalse);
      expect(librarian.isExactly(Role.librarian), isTrue);
      expect(librarian.isExactly(Role.admin), isFalse);
    });

    test('admin имеет только admin-only экран', () {
      expect(admin.isExactly(Role.reader), isFalse);
      expect(admin.isExactly(Role.librarian), isFalse);
      expect(admin.isExactly(Role.admin), isTrue);
    });
  });
}