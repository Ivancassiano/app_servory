import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:servory/features/members/data/members_api.dart';

import '../../support/stub_dio.dart';

void main() {
  test('OrgMember.fromJson mapeia campos e status', () {
    final m = OrgMember.fromJson(const {
      'user_id': 'u1',
      'email': 'a@b.com',
      'name': 'Alice',
      'user_status': 'active',
      'membership_status': 'suspended',
      'role_id': 'r1',
      'role_key': 'technician',
      'role_name': 'Técnico',
      'is_default': true,
    });
    expect(m.name, 'Alice');
    expect(m.suspended, isTrue);
    expect(m.roleName, 'Técnico');
  });

  test('listMembers lê a chave "users"', () async {
    final stub = StubDio(
      (_) => (
        status: 200,
        body: {
          'users': [
            {'user_id': 'u1', 'email': 'a@b.com', 'name': 'Alice'},
            {'user_id': 'u2', 'email': 'b@b.com', 'name': ''},
          ],
        },
      ),
    );
    final members = await MembersApi(stub.dio).listMembers();
    expect(members, hasLength(2));
    expect(members.first.userId, 'u1');
  });

  test('createInvitation manda email + role_id no corpo', () async {
    final stub = StubDio((_) => (status: 201, body: <String, Object>{}));
    await MembersApi(
      stub.dio,
    ).createInvitation(email: 'novo@b.com', roleId: 'r9');

    final req = stub.lastRequest;
    expect(req.method, 'POST');
    expect(req.path, '/v1/users/invitations');
    expect(jsonDecode(jsonEncode(req.data)), {
      'email': 'novo@b.com',
      'role_id': 'r9',
    });
  });

  test('updateMember só inclui os campos passados', () async {
    final stub = StubDio((_) => (status: 200, body: <String, Object>{}));
    await MembersApi(stub.dio).updateMember('u1', roleId: 'r2');

    expect(jsonDecode(jsonEncode(stub.lastRequest.data)), {'role_id': 'r2'});
  });

  test('removeMember bate no endpoint de membership', () async {
    final stub = StubDio((_) => (status: 204, body: <String, Object>{}));
    await MembersApi(stub.dio).removeMember('u7');
    expect(stub.lastRequest.method, 'DELETE');
    expect(stub.lastRequest.path, '/v1/users/u7/membership');
  });
}
