import 'package:flutter_test/flutter_test.dart';

import 'package:up04_01_flutter_web/models/app_user.dart';

void main() {
  const viewer = AppUser(
    id: 'viewer-1',
    username: 'viewer',
    fullName: 'Viewer',
    role: Role.viewer,
  );

  const manager = AppUser(
    id: 'manager-1',
    username: 'manager',
    fullName: 'Manager',
    role: Role.manager,
  );

  const admin = AppUser(
    id: 'admin-1',
    username: 'admin',
    fullName: 'Admin',
    role: Role.admin,
  );

  group('Иерархические права', () {
    test('viewer имеет права viewer', () {
      expect(viewer.hasRole(Role.viewer), isTrue);
    });

    test('viewer не имеет права manager', () {
      expect(viewer.hasRole(Role.manager), isFalse);
    });

    test('viewer не имеет права admin', () {
      expect(viewer.hasRole(Role.admin), isFalse);
    });

    test('manager имеет права viewer', () {
      expect(manager.hasRole(Role.viewer), isTrue);
    });

    test('manager имеет права manager', () {
      expect(manager.hasRole(Role.manager), isTrue);
    });

    test('manager не имеет права admin', () {
      expect(manager.hasRole(Role.admin), isFalse);
    });

    test('admin имеет права viewer', () {
      expect(admin.hasRole(Role.viewer), isTrue);
    });

    test('admin имеет права manager', () {
      expect(admin.hasRole(Role.manager), isTrue);
    });

    test('admin имеет права admin', () {
      expect(admin.hasRole(Role.admin), isTrue);
    });
  });

  group('Эксклюзивные экраны', () {
    test('viewer имеет только viewer-only экран', () {
      expect(viewer.isExactly(Role.viewer), isTrue);
      expect(viewer.isExactly(Role.manager), isFalse);
      expect(viewer.isExactly(Role.admin), isFalse);
    });

    test('manager имеет только manager-only экран', () {
      expect(manager.isExactly(Role.viewer), isFalse);
      expect(manager.isExactly(Role.manager), isTrue);
      expect(manager.isExactly(Role.admin), isFalse);
    });

    test('admin имеет только admin-only экран', () {
      expect(admin.isExactly(Role.viewer), isFalse);
      expect(admin.isExactly(Role.manager), isFalse);
      expect(admin.isExactly(Role.admin), isTrue);
    });
  });
}