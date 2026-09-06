// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $LocalClientsTable extends LocalClients
    with TableInfo<$LocalClientsTable, LocalClient> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalClientsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _organizationIdMeta = const VerificationMeta(
    'organizationId',
  );
  @override
  late final GeneratedColumn<String> organizationId = GeneratedColumn<String>(
    'organization_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('synced'),
  );
  static const VerificationMeta _localUpdatedAtMeta = const VerificationMeta(
    'localUpdatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> localUpdatedAt =
      GeneratedColumn<DateTime>(
        'local_updated_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _lastSyncedAtMeta = const VerificationMeta(
    'lastSyncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSyncedAt = GeneratedColumn<DateTime>(
    'last_synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncErrorMeta = const VerificationMeta(
    'syncError',
  );
  @override
  late final GeneratedColumn<String> syncError = GeneratedColumn<String>(
    'sync_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deletedMeta = const VerificationMeta(
    'deleted',
  );
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
    'deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _legalNameMeta = const VerificationMeta(
    'legalName',
  );
  @override
  late final GeneratedColumn<String> legalName = GeneratedColumn<String>(
    'legal_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _taxIdMeta = const VerificationMeta('taxId');
  @override
  late final GeneratedColumn<String> taxId = GeneratedColumn<String>(
    'tax_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
    'phone',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _contactPersonMeta = const VerificationMeta(
    'contactPerson',
  );
  @override
  late final GeneratedColumn<String> contactPerson = GeneratedColumn<String>(
    'contact_person',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _internalNotesMeta = const VerificationMeta(
    'internalNotes',
  );
  @override
  late final GeneratedColumn<String> internalNotes = GeneratedColumn<String>(
    'internal_notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    organizationId,
    version,
    syncStatus,
    localUpdatedAt,
    lastSyncedAt,
    syncError,
    deleted,
    id,
    kind,
    name,
    legalName,
    taxId,
    phone,
    email,
    contactPerson,
    internalNotes,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_clients';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalClient> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('organization_id')) {
      context.handle(
        _organizationIdMeta,
        organizationId.isAcceptableOrUnknown(
          data['organization_id']!,
          _organizationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_organizationIdMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('local_updated_at')) {
      context.handle(
        _localUpdatedAtMeta,
        localUpdatedAt.isAcceptableOrUnknown(
          data['local_updated_at']!,
          _localUpdatedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_localUpdatedAtMeta);
    }
    if (data.containsKey('last_synced_at')) {
      context.handle(
        _lastSyncedAtMeta,
        lastSyncedAt.isAcceptableOrUnknown(
          data['last_synced_at']!,
          _lastSyncedAtMeta,
        ),
      );
    }
    if (data.containsKey('sync_error')) {
      context.handle(
        _syncErrorMeta,
        syncError.isAcceptableOrUnknown(data['sync_error']!, _syncErrorMeta),
      );
    }
    if (data.containsKey('deleted')) {
      context.handle(
        _deletedMeta,
        deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta),
      );
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('legal_name')) {
      context.handle(
        _legalNameMeta,
        legalName.isAcceptableOrUnknown(data['legal_name']!, _legalNameMeta),
      );
    }
    if (data.containsKey('tax_id')) {
      context.handle(
        _taxIdMeta,
        taxId.isAcceptableOrUnknown(data['tax_id']!, _taxIdMeta),
      );
    }
    if (data.containsKey('phone')) {
      context.handle(
        _phoneMeta,
        phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta),
      );
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    }
    if (data.containsKey('contact_person')) {
      context.handle(
        _contactPersonMeta,
        contactPerson.isAcceptableOrUnknown(
          data['contact_person']!,
          _contactPersonMeta,
        ),
      );
    }
    if (data.containsKey('internal_notes')) {
      context.handle(
        _internalNotesMeta,
        internalNotes.isAcceptableOrUnknown(
          data['internal_notes']!,
          _internalNotesMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalClient map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalClient(
      organizationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}organization_id'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      ),
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
      localUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}local_updated_at'],
      )!,
      lastSyncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_synced_at'],
      ),
      syncError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_error'],
      ),
      deleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}deleted'],
      )!,
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      legalName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}legal_name'],
      )!,
      taxId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tax_id'],
      )!,
      phone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phone'],
      )!,
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      )!,
      contactPerson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}contact_person'],
      )!,
      internalNotes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}internal_notes'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      ),
    );
  }

  @override
  $LocalClientsTable createAlias(String alias) {
    return $LocalClientsTable(attachedDatabase, alias);
  }
}

class LocalClient extends DataClass implements Insertable<LocalClient> {
  final String organizationId;
  final int? version;
  final String syncStatus;
  final DateTime localUpdatedAt;
  final DateTime? lastSyncedAt;
  final String? syncError;
  final bool deleted;
  final String id;
  final String kind;
  final String name;
  final String legalName;
  final String taxId;
  final String phone;
  final String email;
  final String contactPerson;
  final String? internalNotes;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  const LocalClient({
    required this.organizationId,
    this.version,
    required this.syncStatus,
    required this.localUpdatedAt,
    this.lastSyncedAt,
    this.syncError,
    required this.deleted,
    required this.id,
    required this.kind,
    required this.name,
    required this.legalName,
    required this.taxId,
    required this.phone,
    required this.email,
    required this.contactPerson,
    this.internalNotes,
    this.createdAt,
    this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['organization_id'] = Variable<String>(organizationId);
    if (!nullToAbsent || version != null) {
      map['version'] = Variable<int>(version);
    }
    map['sync_status'] = Variable<String>(syncStatus);
    map['local_updated_at'] = Variable<DateTime>(localUpdatedAt);
    if (!nullToAbsent || lastSyncedAt != null) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt);
    }
    if (!nullToAbsent || syncError != null) {
      map['sync_error'] = Variable<String>(syncError);
    }
    map['deleted'] = Variable<bool>(deleted);
    map['id'] = Variable<String>(id);
    map['kind'] = Variable<String>(kind);
    map['name'] = Variable<String>(name);
    map['legal_name'] = Variable<String>(legalName);
    map['tax_id'] = Variable<String>(taxId);
    map['phone'] = Variable<String>(phone);
    map['email'] = Variable<String>(email);
    map['contact_person'] = Variable<String>(contactPerson);
    if (!nullToAbsent || internalNotes != null) {
      map['internal_notes'] = Variable<String>(internalNotes);
    }
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<DateTime>(createdAt);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    return map;
  }

  LocalClientsCompanion toCompanion(bool nullToAbsent) {
    return LocalClientsCompanion(
      organizationId: Value(organizationId),
      version: version == null && nullToAbsent
          ? const Value.absent()
          : Value(version),
      syncStatus: Value(syncStatus),
      localUpdatedAt: Value(localUpdatedAt),
      lastSyncedAt: lastSyncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncedAt),
      syncError: syncError == null && nullToAbsent
          ? const Value.absent()
          : Value(syncError),
      deleted: Value(deleted),
      id: Value(id),
      kind: Value(kind),
      name: Value(name),
      legalName: Value(legalName),
      taxId: Value(taxId),
      phone: Value(phone),
      email: Value(email),
      contactPerson: Value(contactPerson),
      internalNotes: internalNotes == null && nullToAbsent
          ? const Value.absent()
          : Value(internalNotes),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory LocalClient.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalClient(
      organizationId: serializer.fromJson<String>(json['organizationId']),
      version: serializer.fromJson<int?>(json['version']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      localUpdatedAt: serializer.fromJson<DateTime>(json['localUpdatedAt']),
      lastSyncedAt: serializer.fromJson<DateTime?>(json['lastSyncedAt']),
      syncError: serializer.fromJson<String?>(json['syncError']),
      deleted: serializer.fromJson<bool>(json['deleted']),
      id: serializer.fromJson<String>(json['id']),
      kind: serializer.fromJson<String>(json['kind']),
      name: serializer.fromJson<String>(json['name']),
      legalName: serializer.fromJson<String>(json['legalName']),
      taxId: serializer.fromJson<String>(json['taxId']),
      phone: serializer.fromJson<String>(json['phone']),
      email: serializer.fromJson<String>(json['email']),
      contactPerson: serializer.fromJson<String>(json['contactPerson']),
      internalNotes: serializer.fromJson<String?>(json['internalNotes']),
      createdAt: serializer.fromJson<DateTime?>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'organizationId': serializer.toJson<String>(organizationId),
      'version': serializer.toJson<int?>(version),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'localUpdatedAt': serializer.toJson<DateTime>(localUpdatedAt),
      'lastSyncedAt': serializer.toJson<DateTime?>(lastSyncedAt),
      'syncError': serializer.toJson<String?>(syncError),
      'deleted': serializer.toJson<bool>(deleted),
      'id': serializer.toJson<String>(id),
      'kind': serializer.toJson<String>(kind),
      'name': serializer.toJson<String>(name),
      'legalName': serializer.toJson<String>(legalName),
      'taxId': serializer.toJson<String>(taxId),
      'phone': serializer.toJson<String>(phone),
      'email': serializer.toJson<String>(email),
      'contactPerson': serializer.toJson<String>(contactPerson),
      'internalNotes': serializer.toJson<String?>(internalNotes),
      'createdAt': serializer.toJson<DateTime?>(createdAt),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
    };
  }

  LocalClient copyWith({
    String? organizationId,
    Value<int?> version = const Value.absent(),
    String? syncStatus,
    DateTime? localUpdatedAt,
    Value<DateTime?> lastSyncedAt = const Value.absent(),
    Value<String?> syncError = const Value.absent(),
    bool? deleted,
    String? id,
    String? kind,
    String? name,
    String? legalName,
    String? taxId,
    String? phone,
    String? email,
    String? contactPerson,
    Value<String?> internalNotes = const Value.absent(),
    Value<DateTime?> createdAt = const Value.absent(),
    Value<DateTime?> updatedAt = const Value.absent(),
  }) => LocalClient(
    organizationId: organizationId ?? this.organizationId,
    version: version.present ? version.value : this.version,
    syncStatus: syncStatus ?? this.syncStatus,
    localUpdatedAt: localUpdatedAt ?? this.localUpdatedAt,
    lastSyncedAt: lastSyncedAt.present ? lastSyncedAt.value : this.lastSyncedAt,
    syncError: syncError.present ? syncError.value : this.syncError,
    deleted: deleted ?? this.deleted,
    id: id ?? this.id,
    kind: kind ?? this.kind,
    name: name ?? this.name,
    legalName: legalName ?? this.legalName,
    taxId: taxId ?? this.taxId,
    phone: phone ?? this.phone,
    email: email ?? this.email,
    contactPerson: contactPerson ?? this.contactPerson,
    internalNotes: internalNotes.present
        ? internalNotes.value
        : this.internalNotes,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
  );
  LocalClient copyWithCompanion(LocalClientsCompanion data) {
    return LocalClient(
      organizationId: data.organizationId.present
          ? data.organizationId.value
          : this.organizationId,
      version: data.version.present ? data.version.value : this.version,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      localUpdatedAt: data.localUpdatedAt.present
          ? data.localUpdatedAt.value
          : this.localUpdatedAt,
      lastSyncedAt: data.lastSyncedAt.present
          ? data.lastSyncedAt.value
          : this.lastSyncedAt,
      syncError: data.syncError.present ? data.syncError.value : this.syncError,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
      id: data.id.present ? data.id.value : this.id,
      kind: data.kind.present ? data.kind.value : this.kind,
      name: data.name.present ? data.name.value : this.name,
      legalName: data.legalName.present ? data.legalName.value : this.legalName,
      taxId: data.taxId.present ? data.taxId.value : this.taxId,
      phone: data.phone.present ? data.phone.value : this.phone,
      email: data.email.present ? data.email.value : this.email,
      contactPerson: data.contactPerson.present
          ? data.contactPerson.value
          : this.contactPerson,
      internalNotes: data.internalNotes.present
          ? data.internalNotes.value
          : this.internalNotes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalClient(')
          ..write('organizationId: $organizationId, ')
          ..write('version: $version, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('localUpdatedAt: $localUpdatedAt, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('syncError: $syncError, ')
          ..write('deleted: $deleted, ')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('name: $name, ')
          ..write('legalName: $legalName, ')
          ..write('taxId: $taxId, ')
          ..write('phone: $phone, ')
          ..write('email: $email, ')
          ..write('contactPerson: $contactPerson, ')
          ..write('internalNotes: $internalNotes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    organizationId,
    version,
    syncStatus,
    localUpdatedAt,
    lastSyncedAt,
    syncError,
    deleted,
    id,
    kind,
    name,
    legalName,
    taxId,
    phone,
    email,
    contactPerson,
    internalNotes,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalClient &&
          other.organizationId == this.organizationId &&
          other.version == this.version &&
          other.syncStatus == this.syncStatus &&
          other.localUpdatedAt == this.localUpdatedAt &&
          other.lastSyncedAt == this.lastSyncedAt &&
          other.syncError == this.syncError &&
          other.deleted == this.deleted &&
          other.id == this.id &&
          other.kind == this.kind &&
          other.name == this.name &&
          other.legalName == this.legalName &&
          other.taxId == this.taxId &&
          other.phone == this.phone &&
          other.email == this.email &&
          other.contactPerson == this.contactPerson &&
          other.internalNotes == this.internalNotes &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class LocalClientsCompanion extends UpdateCompanion<LocalClient> {
  final Value<String> organizationId;
  final Value<int?> version;
  final Value<String> syncStatus;
  final Value<DateTime> localUpdatedAt;
  final Value<DateTime?> lastSyncedAt;
  final Value<String?> syncError;
  final Value<bool> deleted;
  final Value<String> id;
  final Value<String> kind;
  final Value<String> name;
  final Value<String> legalName;
  final Value<String> taxId;
  final Value<String> phone;
  final Value<String> email;
  final Value<String> contactPerson;
  final Value<String?> internalNotes;
  final Value<DateTime?> createdAt;
  final Value<DateTime?> updatedAt;
  final Value<int> rowid;
  const LocalClientsCompanion({
    this.organizationId = const Value.absent(),
    this.version = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.localUpdatedAt = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.syncError = const Value.absent(),
    this.deleted = const Value.absent(),
    this.id = const Value.absent(),
    this.kind = const Value.absent(),
    this.name = const Value.absent(),
    this.legalName = const Value.absent(),
    this.taxId = const Value.absent(),
    this.phone = const Value.absent(),
    this.email = const Value.absent(),
    this.contactPerson = const Value.absent(),
    this.internalNotes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalClientsCompanion.insert({
    required String organizationId,
    this.version = const Value.absent(),
    this.syncStatus = const Value.absent(),
    required DateTime localUpdatedAt,
    this.lastSyncedAt = const Value.absent(),
    this.syncError = const Value.absent(),
    this.deleted = const Value.absent(),
    required String id,
    required String kind,
    required String name,
    this.legalName = const Value.absent(),
    this.taxId = const Value.absent(),
    this.phone = const Value.absent(),
    this.email = const Value.absent(),
    this.contactPerson = const Value.absent(),
    this.internalNotes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : organizationId = Value(organizationId),
       localUpdatedAt = Value(localUpdatedAt),
       id = Value(id),
       kind = Value(kind),
       name = Value(name);
  static Insertable<LocalClient> custom({
    Expression<String>? organizationId,
    Expression<int>? version,
    Expression<String>? syncStatus,
    Expression<DateTime>? localUpdatedAt,
    Expression<DateTime>? lastSyncedAt,
    Expression<String>? syncError,
    Expression<bool>? deleted,
    Expression<String>? id,
    Expression<String>? kind,
    Expression<String>? name,
    Expression<String>? legalName,
    Expression<String>? taxId,
    Expression<String>? phone,
    Expression<String>? email,
    Expression<String>? contactPerson,
    Expression<String>? internalNotes,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (organizationId != null) 'organization_id': organizationId,
      if (version != null) 'version': version,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (localUpdatedAt != null) 'local_updated_at': localUpdatedAt,
      if (lastSyncedAt != null) 'last_synced_at': lastSyncedAt,
      if (syncError != null) 'sync_error': syncError,
      if (deleted != null) 'deleted': deleted,
      if (id != null) 'id': id,
      if (kind != null) 'kind': kind,
      if (name != null) 'name': name,
      if (legalName != null) 'legal_name': legalName,
      if (taxId != null) 'tax_id': taxId,
      if (phone != null) 'phone': phone,
      if (email != null) 'email': email,
      if (contactPerson != null) 'contact_person': contactPerson,
      if (internalNotes != null) 'internal_notes': internalNotes,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalClientsCompanion copyWith({
    Value<String>? organizationId,
    Value<int?>? version,
    Value<String>? syncStatus,
    Value<DateTime>? localUpdatedAt,
    Value<DateTime?>? lastSyncedAt,
    Value<String?>? syncError,
    Value<bool>? deleted,
    Value<String>? id,
    Value<String>? kind,
    Value<String>? name,
    Value<String>? legalName,
    Value<String>? taxId,
    Value<String>? phone,
    Value<String>? email,
    Value<String>? contactPerson,
    Value<String?>? internalNotes,
    Value<DateTime?>? createdAt,
    Value<DateTime?>? updatedAt,
    Value<int>? rowid,
  }) {
    return LocalClientsCompanion(
      organizationId: organizationId ?? this.organizationId,
      version: version ?? this.version,
      syncStatus: syncStatus ?? this.syncStatus,
      localUpdatedAt: localUpdatedAt ?? this.localUpdatedAt,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      syncError: syncError ?? this.syncError,
      deleted: deleted ?? this.deleted,
      id: id ?? this.id,
      kind: kind ?? this.kind,
      name: name ?? this.name,
      legalName: legalName ?? this.legalName,
      taxId: taxId ?? this.taxId,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      contactPerson: contactPerson ?? this.contactPerson,
      internalNotes: internalNotes ?? this.internalNotes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (organizationId.present) {
      map['organization_id'] = Variable<String>(organizationId.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (localUpdatedAt.present) {
      map['local_updated_at'] = Variable<DateTime>(localUpdatedAt.value);
    }
    if (lastSyncedAt.present) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt.value);
    }
    if (syncError.present) {
      map['sync_error'] = Variable<String>(syncError.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (legalName.present) {
      map['legal_name'] = Variable<String>(legalName.value);
    }
    if (taxId.present) {
      map['tax_id'] = Variable<String>(taxId.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (contactPerson.present) {
      map['contact_person'] = Variable<String>(contactPerson.value);
    }
    if (internalNotes.present) {
      map['internal_notes'] = Variable<String>(internalNotes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalClientsCompanion(')
          ..write('organizationId: $organizationId, ')
          ..write('version: $version, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('localUpdatedAt: $localUpdatedAt, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('syncError: $syncError, ')
          ..write('deleted: $deleted, ')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('name: $name, ')
          ..write('legalName: $legalName, ')
          ..write('taxId: $taxId, ')
          ..write('phone: $phone, ')
          ..write('email: $email, ')
          ..write('contactPerson: $contactPerson, ')
          ..write('internalNotes: $internalNotes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalLocationsTable extends LocalLocations
    with TableInfo<$LocalLocationsTable, LocalLocation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalLocationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _organizationIdMeta = const VerificationMeta(
    'organizationId',
  );
  @override
  late final GeneratedColumn<String> organizationId = GeneratedColumn<String>(
    'organization_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('synced'),
  );
  static const VerificationMeta _localUpdatedAtMeta = const VerificationMeta(
    'localUpdatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> localUpdatedAt =
      GeneratedColumn<DateTime>(
        'local_updated_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _lastSyncedAtMeta = const VerificationMeta(
    'lastSyncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSyncedAt = GeneratedColumn<DateTime>(
    'last_synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncErrorMeta = const VerificationMeta(
    'syncError',
  );
  @override
  late final GeneratedColumn<String> syncError = GeneratedColumn<String>(
    'sync_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deletedMeta = const VerificationMeta(
    'deleted',
  );
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
    'deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _clientIdMeta = const VerificationMeta(
    'clientId',
  );
  @override
  late final GeneratedColumn<String> clientId = GeneratedColumn<String>(
    'client_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _parentLocationIdMeta = const VerificationMeta(
    'parentLocationId',
  );
  @override
  late final GeneratedColumn<String> parentLocationId = GeneratedColumn<String>(
    'parent_location_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _postalCodeMeta = const VerificationMeta(
    'postalCode',
  );
  @override
  late final GeneratedColumn<String> postalCode = GeneratedColumn<String>(
    'postal_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _streetMeta = const VerificationMeta('street');
  @override
  late final GeneratedColumn<String> street = GeneratedColumn<String>(
    'street',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _numberMeta = const VerificationMeta('number');
  @override
  late final GeneratedColumn<String> number = GeneratedColumn<String>(
    'number',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _complementMeta = const VerificationMeta(
    'complement',
  );
  @override
  late final GeneratedColumn<String> complement = GeneratedColumn<String>(
    'complement',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _districtMeta = const VerificationMeta(
    'district',
  );
  @override
  late final GeneratedColumn<String> district = GeneratedColumn<String>(
    'district',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _cityMeta = const VerificationMeta('city');
  @override
  late final GeneratedColumn<String> city = GeneratedColumn<String>(
    'city',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  @override
  late final GeneratedColumn<String> state = GeneratedColumn<String>(
    'state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _contactPersonMeta = const VerificationMeta(
    'contactPerson',
  );
  @override
  late final GeneratedColumn<String> contactPerson = GeneratedColumn<String>(
    'contact_person',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
    'phone',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _accessInstructionsMeta =
      const VerificationMeta('accessInstructions');
  @override
  late final GeneratedColumn<String> accessInstructions =
      GeneratedColumn<String>(
        'access_instructions',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant(''),
      );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    organizationId,
    version,
    syncStatus,
    localUpdatedAt,
    lastSyncedAt,
    syncError,
    deleted,
    id,
    clientId,
    parentLocationId,
    name,
    postalCode,
    street,
    number,
    complement,
    district,
    city,
    state,
    contactPerson,
    phone,
    accessInstructions,
    notes,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_locations';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalLocation> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('organization_id')) {
      context.handle(
        _organizationIdMeta,
        organizationId.isAcceptableOrUnknown(
          data['organization_id']!,
          _organizationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_organizationIdMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('local_updated_at')) {
      context.handle(
        _localUpdatedAtMeta,
        localUpdatedAt.isAcceptableOrUnknown(
          data['local_updated_at']!,
          _localUpdatedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_localUpdatedAtMeta);
    }
    if (data.containsKey('last_synced_at')) {
      context.handle(
        _lastSyncedAtMeta,
        lastSyncedAt.isAcceptableOrUnknown(
          data['last_synced_at']!,
          _lastSyncedAtMeta,
        ),
      );
    }
    if (data.containsKey('sync_error')) {
      context.handle(
        _syncErrorMeta,
        syncError.isAcceptableOrUnknown(data['sync_error']!, _syncErrorMeta),
      );
    }
    if (data.containsKey('deleted')) {
      context.handle(
        _deletedMeta,
        deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta),
      );
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('client_id')) {
      context.handle(
        _clientIdMeta,
        clientId.isAcceptableOrUnknown(data['client_id']!, _clientIdMeta),
      );
    } else if (isInserting) {
      context.missing(_clientIdMeta);
    }
    if (data.containsKey('parent_location_id')) {
      context.handle(
        _parentLocationIdMeta,
        parentLocationId.isAcceptableOrUnknown(
          data['parent_location_id']!,
          _parentLocationIdMeta,
        ),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('postal_code')) {
      context.handle(
        _postalCodeMeta,
        postalCode.isAcceptableOrUnknown(data['postal_code']!, _postalCodeMeta),
      );
    }
    if (data.containsKey('street')) {
      context.handle(
        _streetMeta,
        street.isAcceptableOrUnknown(data['street']!, _streetMeta),
      );
    }
    if (data.containsKey('number')) {
      context.handle(
        _numberMeta,
        number.isAcceptableOrUnknown(data['number']!, _numberMeta),
      );
    }
    if (data.containsKey('complement')) {
      context.handle(
        _complementMeta,
        complement.isAcceptableOrUnknown(data['complement']!, _complementMeta),
      );
    }
    if (data.containsKey('district')) {
      context.handle(
        _districtMeta,
        district.isAcceptableOrUnknown(data['district']!, _districtMeta),
      );
    }
    if (data.containsKey('city')) {
      context.handle(
        _cityMeta,
        city.isAcceptableOrUnknown(data['city']!, _cityMeta),
      );
    }
    if (data.containsKey('state')) {
      context.handle(
        _stateMeta,
        state.isAcceptableOrUnknown(data['state']!, _stateMeta),
      );
    }
    if (data.containsKey('contact_person')) {
      context.handle(
        _contactPersonMeta,
        contactPerson.isAcceptableOrUnknown(
          data['contact_person']!,
          _contactPersonMeta,
        ),
      );
    }
    if (data.containsKey('phone')) {
      context.handle(
        _phoneMeta,
        phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta),
      );
    }
    if (data.containsKey('access_instructions')) {
      context.handle(
        _accessInstructionsMeta,
        accessInstructions.isAcceptableOrUnknown(
          data['access_instructions']!,
          _accessInstructionsMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalLocation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalLocation(
      organizationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}organization_id'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      ),
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
      localUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}local_updated_at'],
      )!,
      lastSyncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_synced_at'],
      ),
      syncError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_error'],
      ),
      deleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}deleted'],
      )!,
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      clientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_id'],
      )!,
      parentLocationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parent_location_id'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      postalCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}postal_code'],
      )!,
      street: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}street'],
      )!,
      number: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}number'],
      )!,
      complement: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}complement'],
      )!,
      district: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}district'],
      )!,
      city: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}city'],
      )!,
      state: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}state'],
      )!,
      contactPerson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}contact_person'],
      )!,
      phone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phone'],
      )!,
      accessInstructions: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}access_instructions'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      ),
    );
  }

  @override
  $LocalLocationsTable createAlias(String alias) {
    return $LocalLocationsTable(attachedDatabase, alias);
  }
}

class LocalLocation extends DataClass implements Insertable<LocalLocation> {
  final String organizationId;
  final int? version;
  final String syncStatus;
  final DateTime localUpdatedAt;
  final DateTime? lastSyncedAt;
  final String? syncError;
  final bool deleted;
  final String id;
  final String clientId;
  final String? parentLocationId;
  final String name;
  final String postalCode;
  final String street;
  final String number;
  final String complement;
  final String district;
  final String city;
  final String state;
  final String contactPerson;
  final String phone;
  final String accessInstructions;
  final String notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  const LocalLocation({
    required this.organizationId,
    this.version,
    required this.syncStatus,
    required this.localUpdatedAt,
    this.lastSyncedAt,
    this.syncError,
    required this.deleted,
    required this.id,
    required this.clientId,
    this.parentLocationId,
    required this.name,
    required this.postalCode,
    required this.street,
    required this.number,
    required this.complement,
    required this.district,
    required this.city,
    required this.state,
    required this.contactPerson,
    required this.phone,
    required this.accessInstructions,
    required this.notes,
    this.createdAt,
    this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['organization_id'] = Variable<String>(organizationId);
    if (!nullToAbsent || version != null) {
      map['version'] = Variable<int>(version);
    }
    map['sync_status'] = Variable<String>(syncStatus);
    map['local_updated_at'] = Variable<DateTime>(localUpdatedAt);
    if (!nullToAbsent || lastSyncedAt != null) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt);
    }
    if (!nullToAbsent || syncError != null) {
      map['sync_error'] = Variable<String>(syncError);
    }
    map['deleted'] = Variable<bool>(deleted);
    map['id'] = Variable<String>(id);
    map['client_id'] = Variable<String>(clientId);
    if (!nullToAbsent || parentLocationId != null) {
      map['parent_location_id'] = Variable<String>(parentLocationId);
    }
    map['name'] = Variable<String>(name);
    map['postal_code'] = Variable<String>(postalCode);
    map['street'] = Variable<String>(street);
    map['number'] = Variable<String>(number);
    map['complement'] = Variable<String>(complement);
    map['district'] = Variable<String>(district);
    map['city'] = Variable<String>(city);
    map['state'] = Variable<String>(state);
    map['contact_person'] = Variable<String>(contactPerson);
    map['phone'] = Variable<String>(phone);
    map['access_instructions'] = Variable<String>(accessInstructions);
    map['notes'] = Variable<String>(notes);
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<DateTime>(createdAt);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    return map;
  }

  LocalLocationsCompanion toCompanion(bool nullToAbsent) {
    return LocalLocationsCompanion(
      organizationId: Value(organizationId),
      version: version == null && nullToAbsent
          ? const Value.absent()
          : Value(version),
      syncStatus: Value(syncStatus),
      localUpdatedAt: Value(localUpdatedAt),
      lastSyncedAt: lastSyncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncedAt),
      syncError: syncError == null && nullToAbsent
          ? const Value.absent()
          : Value(syncError),
      deleted: Value(deleted),
      id: Value(id),
      clientId: Value(clientId),
      parentLocationId: parentLocationId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentLocationId),
      name: Value(name),
      postalCode: Value(postalCode),
      street: Value(street),
      number: Value(number),
      complement: Value(complement),
      district: Value(district),
      city: Value(city),
      state: Value(state),
      contactPerson: Value(contactPerson),
      phone: Value(phone),
      accessInstructions: Value(accessInstructions),
      notes: Value(notes),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory LocalLocation.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalLocation(
      organizationId: serializer.fromJson<String>(json['organizationId']),
      version: serializer.fromJson<int?>(json['version']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      localUpdatedAt: serializer.fromJson<DateTime>(json['localUpdatedAt']),
      lastSyncedAt: serializer.fromJson<DateTime?>(json['lastSyncedAt']),
      syncError: serializer.fromJson<String?>(json['syncError']),
      deleted: serializer.fromJson<bool>(json['deleted']),
      id: serializer.fromJson<String>(json['id']),
      clientId: serializer.fromJson<String>(json['clientId']),
      parentLocationId: serializer.fromJson<String?>(json['parentLocationId']),
      name: serializer.fromJson<String>(json['name']),
      postalCode: serializer.fromJson<String>(json['postalCode']),
      street: serializer.fromJson<String>(json['street']),
      number: serializer.fromJson<String>(json['number']),
      complement: serializer.fromJson<String>(json['complement']),
      district: serializer.fromJson<String>(json['district']),
      city: serializer.fromJson<String>(json['city']),
      state: serializer.fromJson<String>(json['state']),
      contactPerson: serializer.fromJson<String>(json['contactPerson']),
      phone: serializer.fromJson<String>(json['phone']),
      accessInstructions: serializer.fromJson<String>(
        json['accessInstructions'],
      ),
      notes: serializer.fromJson<String>(json['notes']),
      createdAt: serializer.fromJson<DateTime?>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'organizationId': serializer.toJson<String>(organizationId),
      'version': serializer.toJson<int?>(version),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'localUpdatedAt': serializer.toJson<DateTime>(localUpdatedAt),
      'lastSyncedAt': serializer.toJson<DateTime?>(lastSyncedAt),
      'syncError': serializer.toJson<String?>(syncError),
      'deleted': serializer.toJson<bool>(deleted),
      'id': serializer.toJson<String>(id),
      'clientId': serializer.toJson<String>(clientId),
      'parentLocationId': serializer.toJson<String?>(parentLocationId),
      'name': serializer.toJson<String>(name),
      'postalCode': serializer.toJson<String>(postalCode),
      'street': serializer.toJson<String>(street),
      'number': serializer.toJson<String>(number),
      'complement': serializer.toJson<String>(complement),
      'district': serializer.toJson<String>(district),
      'city': serializer.toJson<String>(city),
      'state': serializer.toJson<String>(state),
      'contactPerson': serializer.toJson<String>(contactPerson),
      'phone': serializer.toJson<String>(phone),
      'accessInstructions': serializer.toJson<String>(accessInstructions),
      'notes': serializer.toJson<String>(notes),
      'createdAt': serializer.toJson<DateTime?>(createdAt),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
    };
  }

  LocalLocation copyWith({
    String? organizationId,
    Value<int?> version = const Value.absent(),
    String? syncStatus,
    DateTime? localUpdatedAt,
    Value<DateTime?> lastSyncedAt = const Value.absent(),
    Value<String?> syncError = const Value.absent(),
    bool? deleted,
    String? id,
    String? clientId,
    Value<String?> parentLocationId = const Value.absent(),
    String? name,
    String? postalCode,
    String? street,
    String? number,
    String? complement,
    String? district,
    String? city,
    String? state,
    String? contactPerson,
    String? phone,
    String? accessInstructions,
    String? notes,
    Value<DateTime?> createdAt = const Value.absent(),
    Value<DateTime?> updatedAt = const Value.absent(),
  }) => LocalLocation(
    organizationId: organizationId ?? this.organizationId,
    version: version.present ? version.value : this.version,
    syncStatus: syncStatus ?? this.syncStatus,
    localUpdatedAt: localUpdatedAt ?? this.localUpdatedAt,
    lastSyncedAt: lastSyncedAt.present ? lastSyncedAt.value : this.lastSyncedAt,
    syncError: syncError.present ? syncError.value : this.syncError,
    deleted: deleted ?? this.deleted,
    id: id ?? this.id,
    clientId: clientId ?? this.clientId,
    parentLocationId: parentLocationId.present
        ? parentLocationId.value
        : this.parentLocationId,
    name: name ?? this.name,
    postalCode: postalCode ?? this.postalCode,
    street: street ?? this.street,
    number: number ?? this.number,
    complement: complement ?? this.complement,
    district: district ?? this.district,
    city: city ?? this.city,
    state: state ?? this.state,
    contactPerson: contactPerson ?? this.contactPerson,
    phone: phone ?? this.phone,
    accessInstructions: accessInstructions ?? this.accessInstructions,
    notes: notes ?? this.notes,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
  );
  LocalLocation copyWithCompanion(LocalLocationsCompanion data) {
    return LocalLocation(
      organizationId: data.organizationId.present
          ? data.organizationId.value
          : this.organizationId,
      version: data.version.present ? data.version.value : this.version,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      localUpdatedAt: data.localUpdatedAt.present
          ? data.localUpdatedAt.value
          : this.localUpdatedAt,
      lastSyncedAt: data.lastSyncedAt.present
          ? data.lastSyncedAt.value
          : this.lastSyncedAt,
      syncError: data.syncError.present ? data.syncError.value : this.syncError,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
      id: data.id.present ? data.id.value : this.id,
      clientId: data.clientId.present ? data.clientId.value : this.clientId,
      parentLocationId: data.parentLocationId.present
          ? data.parentLocationId.value
          : this.parentLocationId,
      name: data.name.present ? data.name.value : this.name,
      postalCode: data.postalCode.present
          ? data.postalCode.value
          : this.postalCode,
      street: data.street.present ? data.street.value : this.street,
      number: data.number.present ? data.number.value : this.number,
      complement: data.complement.present
          ? data.complement.value
          : this.complement,
      district: data.district.present ? data.district.value : this.district,
      city: data.city.present ? data.city.value : this.city,
      state: data.state.present ? data.state.value : this.state,
      contactPerson: data.contactPerson.present
          ? data.contactPerson.value
          : this.contactPerson,
      phone: data.phone.present ? data.phone.value : this.phone,
      accessInstructions: data.accessInstructions.present
          ? data.accessInstructions.value
          : this.accessInstructions,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalLocation(')
          ..write('organizationId: $organizationId, ')
          ..write('version: $version, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('localUpdatedAt: $localUpdatedAt, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('syncError: $syncError, ')
          ..write('deleted: $deleted, ')
          ..write('id: $id, ')
          ..write('clientId: $clientId, ')
          ..write('parentLocationId: $parentLocationId, ')
          ..write('name: $name, ')
          ..write('postalCode: $postalCode, ')
          ..write('street: $street, ')
          ..write('number: $number, ')
          ..write('complement: $complement, ')
          ..write('district: $district, ')
          ..write('city: $city, ')
          ..write('state: $state, ')
          ..write('contactPerson: $contactPerson, ')
          ..write('phone: $phone, ')
          ..write('accessInstructions: $accessInstructions, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    organizationId,
    version,
    syncStatus,
    localUpdatedAt,
    lastSyncedAt,
    syncError,
    deleted,
    id,
    clientId,
    parentLocationId,
    name,
    postalCode,
    street,
    number,
    complement,
    district,
    city,
    state,
    contactPerson,
    phone,
    accessInstructions,
    notes,
    createdAt,
    updatedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalLocation &&
          other.organizationId == this.organizationId &&
          other.version == this.version &&
          other.syncStatus == this.syncStatus &&
          other.localUpdatedAt == this.localUpdatedAt &&
          other.lastSyncedAt == this.lastSyncedAt &&
          other.syncError == this.syncError &&
          other.deleted == this.deleted &&
          other.id == this.id &&
          other.clientId == this.clientId &&
          other.parentLocationId == this.parentLocationId &&
          other.name == this.name &&
          other.postalCode == this.postalCode &&
          other.street == this.street &&
          other.number == this.number &&
          other.complement == this.complement &&
          other.district == this.district &&
          other.city == this.city &&
          other.state == this.state &&
          other.contactPerson == this.contactPerson &&
          other.phone == this.phone &&
          other.accessInstructions == this.accessInstructions &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class LocalLocationsCompanion extends UpdateCompanion<LocalLocation> {
  final Value<String> organizationId;
  final Value<int?> version;
  final Value<String> syncStatus;
  final Value<DateTime> localUpdatedAt;
  final Value<DateTime?> lastSyncedAt;
  final Value<String?> syncError;
  final Value<bool> deleted;
  final Value<String> id;
  final Value<String> clientId;
  final Value<String?> parentLocationId;
  final Value<String> name;
  final Value<String> postalCode;
  final Value<String> street;
  final Value<String> number;
  final Value<String> complement;
  final Value<String> district;
  final Value<String> city;
  final Value<String> state;
  final Value<String> contactPerson;
  final Value<String> phone;
  final Value<String> accessInstructions;
  final Value<String> notes;
  final Value<DateTime?> createdAt;
  final Value<DateTime?> updatedAt;
  final Value<int> rowid;
  const LocalLocationsCompanion({
    this.organizationId = const Value.absent(),
    this.version = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.localUpdatedAt = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.syncError = const Value.absent(),
    this.deleted = const Value.absent(),
    this.id = const Value.absent(),
    this.clientId = const Value.absent(),
    this.parentLocationId = const Value.absent(),
    this.name = const Value.absent(),
    this.postalCode = const Value.absent(),
    this.street = const Value.absent(),
    this.number = const Value.absent(),
    this.complement = const Value.absent(),
    this.district = const Value.absent(),
    this.city = const Value.absent(),
    this.state = const Value.absent(),
    this.contactPerson = const Value.absent(),
    this.phone = const Value.absent(),
    this.accessInstructions = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalLocationsCompanion.insert({
    required String organizationId,
    this.version = const Value.absent(),
    this.syncStatus = const Value.absent(),
    required DateTime localUpdatedAt,
    this.lastSyncedAt = const Value.absent(),
    this.syncError = const Value.absent(),
    this.deleted = const Value.absent(),
    required String id,
    required String clientId,
    this.parentLocationId = const Value.absent(),
    required String name,
    this.postalCode = const Value.absent(),
    this.street = const Value.absent(),
    this.number = const Value.absent(),
    this.complement = const Value.absent(),
    this.district = const Value.absent(),
    this.city = const Value.absent(),
    this.state = const Value.absent(),
    this.contactPerson = const Value.absent(),
    this.phone = const Value.absent(),
    this.accessInstructions = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : organizationId = Value(organizationId),
       localUpdatedAt = Value(localUpdatedAt),
       id = Value(id),
       clientId = Value(clientId),
       name = Value(name);
  static Insertable<LocalLocation> custom({
    Expression<String>? organizationId,
    Expression<int>? version,
    Expression<String>? syncStatus,
    Expression<DateTime>? localUpdatedAt,
    Expression<DateTime>? lastSyncedAt,
    Expression<String>? syncError,
    Expression<bool>? deleted,
    Expression<String>? id,
    Expression<String>? clientId,
    Expression<String>? parentLocationId,
    Expression<String>? name,
    Expression<String>? postalCode,
    Expression<String>? street,
    Expression<String>? number,
    Expression<String>? complement,
    Expression<String>? district,
    Expression<String>? city,
    Expression<String>? state,
    Expression<String>? contactPerson,
    Expression<String>? phone,
    Expression<String>? accessInstructions,
    Expression<String>? notes,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (organizationId != null) 'organization_id': organizationId,
      if (version != null) 'version': version,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (localUpdatedAt != null) 'local_updated_at': localUpdatedAt,
      if (lastSyncedAt != null) 'last_synced_at': lastSyncedAt,
      if (syncError != null) 'sync_error': syncError,
      if (deleted != null) 'deleted': deleted,
      if (id != null) 'id': id,
      if (clientId != null) 'client_id': clientId,
      if (parentLocationId != null) 'parent_location_id': parentLocationId,
      if (name != null) 'name': name,
      if (postalCode != null) 'postal_code': postalCode,
      if (street != null) 'street': street,
      if (number != null) 'number': number,
      if (complement != null) 'complement': complement,
      if (district != null) 'district': district,
      if (city != null) 'city': city,
      if (state != null) 'state': state,
      if (contactPerson != null) 'contact_person': contactPerson,
      if (phone != null) 'phone': phone,
      if (accessInstructions != null) 'access_instructions': accessInstructions,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalLocationsCompanion copyWith({
    Value<String>? organizationId,
    Value<int?>? version,
    Value<String>? syncStatus,
    Value<DateTime>? localUpdatedAt,
    Value<DateTime?>? lastSyncedAt,
    Value<String?>? syncError,
    Value<bool>? deleted,
    Value<String>? id,
    Value<String>? clientId,
    Value<String?>? parentLocationId,
    Value<String>? name,
    Value<String>? postalCode,
    Value<String>? street,
    Value<String>? number,
    Value<String>? complement,
    Value<String>? district,
    Value<String>? city,
    Value<String>? state,
    Value<String>? contactPerson,
    Value<String>? phone,
    Value<String>? accessInstructions,
    Value<String>? notes,
    Value<DateTime?>? createdAt,
    Value<DateTime?>? updatedAt,
    Value<int>? rowid,
  }) {
    return LocalLocationsCompanion(
      organizationId: organizationId ?? this.organizationId,
      version: version ?? this.version,
      syncStatus: syncStatus ?? this.syncStatus,
      localUpdatedAt: localUpdatedAt ?? this.localUpdatedAt,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      syncError: syncError ?? this.syncError,
      deleted: deleted ?? this.deleted,
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      parentLocationId: parentLocationId ?? this.parentLocationId,
      name: name ?? this.name,
      postalCode: postalCode ?? this.postalCode,
      street: street ?? this.street,
      number: number ?? this.number,
      complement: complement ?? this.complement,
      district: district ?? this.district,
      city: city ?? this.city,
      state: state ?? this.state,
      contactPerson: contactPerson ?? this.contactPerson,
      phone: phone ?? this.phone,
      accessInstructions: accessInstructions ?? this.accessInstructions,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (organizationId.present) {
      map['organization_id'] = Variable<String>(organizationId.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (localUpdatedAt.present) {
      map['local_updated_at'] = Variable<DateTime>(localUpdatedAt.value);
    }
    if (lastSyncedAt.present) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt.value);
    }
    if (syncError.present) {
      map['sync_error'] = Variable<String>(syncError.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (clientId.present) {
      map['client_id'] = Variable<String>(clientId.value);
    }
    if (parentLocationId.present) {
      map['parent_location_id'] = Variable<String>(parentLocationId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (postalCode.present) {
      map['postal_code'] = Variable<String>(postalCode.value);
    }
    if (street.present) {
      map['street'] = Variable<String>(street.value);
    }
    if (number.present) {
      map['number'] = Variable<String>(number.value);
    }
    if (complement.present) {
      map['complement'] = Variable<String>(complement.value);
    }
    if (district.present) {
      map['district'] = Variable<String>(district.value);
    }
    if (city.present) {
      map['city'] = Variable<String>(city.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(state.value);
    }
    if (contactPerson.present) {
      map['contact_person'] = Variable<String>(contactPerson.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (accessInstructions.present) {
      map['access_instructions'] = Variable<String>(accessInstructions.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalLocationsCompanion(')
          ..write('organizationId: $organizationId, ')
          ..write('version: $version, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('localUpdatedAt: $localUpdatedAt, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('syncError: $syncError, ')
          ..write('deleted: $deleted, ')
          ..write('id: $id, ')
          ..write('clientId: $clientId, ')
          ..write('parentLocationId: $parentLocationId, ')
          ..write('name: $name, ')
          ..write('postalCode: $postalCode, ')
          ..write('street: $street, ')
          ..write('number: $number, ')
          ..write('complement: $complement, ')
          ..write('district: $district, ')
          ..write('city: $city, ')
          ..write('state: $state, ')
          ..write('contactPerson: $contactPerson, ')
          ..write('phone: $phone, ')
          ..write('accessInstructions: $accessInstructions, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalEquipmentsTable extends LocalEquipments
    with TableInfo<$LocalEquipmentsTable, LocalEquipment> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalEquipmentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _organizationIdMeta = const VerificationMeta(
    'organizationId',
  );
  @override
  late final GeneratedColumn<String> organizationId = GeneratedColumn<String>(
    'organization_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('synced'),
  );
  static const VerificationMeta _localUpdatedAtMeta = const VerificationMeta(
    'localUpdatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> localUpdatedAt =
      GeneratedColumn<DateTime>(
        'local_updated_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _lastSyncedAtMeta = const VerificationMeta(
    'lastSyncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSyncedAt = GeneratedColumn<DateTime>(
    'last_synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncErrorMeta = const VerificationMeta(
    'syncError',
  );
  @override
  late final GeneratedColumn<String> syncError = GeneratedColumn<String>(
    'sync_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deletedMeta = const VerificationMeta(
    'deleted',
  );
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
    'deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _locationIdMeta = const VerificationMeta(
    'locationId',
  );
  @override
  late final GeneratedColumn<String> locationId = GeneratedColumn<String>(
    'location_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _equipmentTypeIdMeta = const VerificationMeta(
    'equipmentTypeId',
  );
  @override
  late final GeneratedColumn<String> equipmentTypeId = GeneratedColumn<String>(
    'equipment_type_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _brandMeta = const VerificationMeta('brand');
  @override
  late final GeneratedColumn<String> brand = GeneratedColumn<String>(
    'brand',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _modelMeta = const VerificationMeta('model');
  @override
  late final GeneratedColumn<String> model = GeneratedColumn<String>(
    'model',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _serialNumberMeta = const VerificationMeta(
    'serialNumber',
  );
  @override
  late final GeneratedColumn<String> serialNumber = GeneratedColumn<String>(
    'serial_number',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _internalLocationMeta = const VerificationMeta(
    'internalLocation',
  );
  @override
  late final GeneratedColumn<String> internalLocation = GeneratedColumn<String>(
    'internal_location',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _installedAtMeta = const VerificationMeta(
    'installedAt',
  );
  @override
  late final GeneratedColumn<String> installedAt = GeneratedColumn<String>(
    'installed_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _costMeta = const VerificationMeta('cost');
  @override
  late final GeneratedColumn<String> cost = GeneratedColumn<String>(
    'cost',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    organizationId,
    version,
    syncStatus,
    localUpdatedAt,
    lastSyncedAt,
    syncError,
    deleted,
    id,
    locationId,
    equipmentTypeId,
    name,
    brand,
    model,
    serialNumber,
    internalLocation,
    installedAt,
    cost,
    notes,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_equipments';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalEquipment> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('organization_id')) {
      context.handle(
        _organizationIdMeta,
        organizationId.isAcceptableOrUnknown(
          data['organization_id']!,
          _organizationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_organizationIdMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('local_updated_at')) {
      context.handle(
        _localUpdatedAtMeta,
        localUpdatedAt.isAcceptableOrUnknown(
          data['local_updated_at']!,
          _localUpdatedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_localUpdatedAtMeta);
    }
    if (data.containsKey('last_synced_at')) {
      context.handle(
        _lastSyncedAtMeta,
        lastSyncedAt.isAcceptableOrUnknown(
          data['last_synced_at']!,
          _lastSyncedAtMeta,
        ),
      );
    }
    if (data.containsKey('sync_error')) {
      context.handle(
        _syncErrorMeta,
        syncError.isAcceptableOrUnknown(data['sync_error']!, _syncErrorMeta),
      );
    }
    if (data.containsKey('deleted')) {
      context.handle(
        _deletedMeta,
        deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta),
      );
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('location_id')) {
      context.handle(
        _locationIdMeta,
        locationId.isAcceptableOrUnknown(data['location_id']!, _locationIdMeta),
      );
    } else if (isInserting) {
      context.missing(_locationIdMeta);
    }
    if (data.containsKey('equipment_type_id')) {
      context.handle(
        _equipmentTypeIdMeta,
        equipmentTypeId.isAcceptableOrUnknown(
          data['equipment_type_id']!,
          _equipmentTypeIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_equipmentTypeIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('brand')) {
      context.handle(
        _brandMeta,
        brand.isAcceptableOrUnknown(data['brand']!, _brandMeta),
      );
    }
    if (data.containsKey('model')) {
      context.handle(
        _modelMeta,
        model.isAcceptableOrUnknown(data['model']!, _modelMeta),
      );
    }
    if (data.containsKey('serial_number')) {
      context.handle(
        _serialNumberMeta,
        serialNumber.isAcceptableOrUnknown(
          data['serial_number']!,
          _serialNumberMeta,
        ),
      );
    }
    if (data.containsKey('internal_location')) {
      context.handle(
        _internalLocationMeta,
        internalLocation.isAcceptableOrUnknown(
          data['internal_location']!,
          _internalLocationMeta,
        ),
      );
    }
    if (data.containsKey('installed_at')) {
      context.handle(
        _installedAtMeta,
        installedAt.isAcceptableOrUnknown(
          data['installed_at']!,
          _installedAtMeta,
        ),
      );
    }
    if (data.containsKey('cost')) {
      context.handle(
        _costMeta,
        cost.isAcceptableOrUnknown(data['cost']!, _costMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalEquipment map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalEquipment(
      organizationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}organization_id'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      ),
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
      localUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}local_updated_at'],
      )!,
      lastSyncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_synced_at'],
      ),
      syncError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_error'],
      ),
      deleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}deleted'],
      )!,
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      locationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}location_id'],
      )!,
      equipmentTypeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}equipment_type_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      brand: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}brand'],
      )!,
      model: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model'],
      )!,
      serialNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}serial_number'],
      ),
      internalLocation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}internal_location'],
      )!,
      installedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}installed_at'],
      ),
      cost: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cost'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      ),
    );
  }

  @override
  $LocalEquipmentsTable createAlias(String alias) {
    return $LocalEquipmentsTable(attachedDatabase, alias);
  }
}

class LocalEquipment extends DataClass implements Insertable<LocalEquipment> {
  final String organizationId;
  final int? version;
  final String syncStatus;
  final DateTime localUpdatedAt;
  final DateTime? lastSyncedAt;
  final String? syncError;
  final bool deleted;
  final String id;
  final String locationId;
  final String equipmentTypeId;
  final String name;
  final String brand;
  final String model;
  final String? serialNumber;
  final String internalLocation;
  final String? installedAt;
  final String? cost;
  final String notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  const LocalEquipment({
    required this.organizationId,
    this.version,
    required this.syncStatus,
    required this.localUpdatedAt,
    this.lastSyncedAt,
    this.syncError,
    required this.deleted,
    required this.id,
    required this.locationId,
    required this.equipmentTypeId,
    required this.name,
    required this.brand,
    required this.model,
    this.serialNumber,
    required this.internalLocation,
    this.installedAt,
    this.cost,
    required this.notes,
    this.createdAt,
    this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['organization_id'] = Variable<String>(organizationId);
    if (!nullToAbsent || version != null) {
      map['version'] = Variable<int>(version);
    }
    map['sync_status'] = Variable<String>(syncStatus);
    map['local_updated_at'] = Variable<DateTime>(localUpdatedAt);
    if (!nullToAbsent || lastSyncedAt != null) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt);
    }
    if (!nullToAbsent || syncError != null) {
      map['sync_error'] = Variable<String>(syncError);
    }
    map['deleted'] = Variable<bool>(deleted);
    map['id'] = Variable<String>(id);
    map['location_id'] = Variable<String>(locationId);
    map['equipment_type_id'] = Variable<String>(equipmentTypeId);
    map['name'] = Variable<String>(name);
    map['brand'] = Variable<String>(brand);
    map['model'] = Variable<String>(model);
    if (!nullToAbsent || serialNumber != null) {
      map['serial_number'] = Variable<String>(serialNumber);
    }
    map['internal_location'] = Variable<String>(internalLocation);
    if (!nullToAbsent || installedAt != null) {
      map['installed_at'] = Variable<String>(installedAt);
    }
    if (!nullToAbsent || cost != null) {
      map['cost'] = Variable<String>(cost);
    }
    map['notes'] = Variable<String>(notes);
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<DateTime>(createdAt);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    return map;
  }

  LocalEquipmentsCompanion toCompanion(bool nullToAbsent) {
    return LocalEquipmentsCompanion(
      organizationId: Value(organizationId),
      version: version == null && nullToAbsent
          ? const Value.absent()
          : Value(version),
      syncStatus: Value(syncStatus),
      localUpdatedAt: Value(localUpdatedAt),
      lastSyncedAt: lastSyncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncedAt),
      syncError: syncError == null && nullToAbsent
          ? const Value.absent()
          : Value(syncError),
      deleted: Value(deleted),
      id: Value(id),
      locationId: Value(locationId),
      equipmentTypeId: Value(equipmentTypeId),
      name: Value(name),
      brand: Value(brand),
      model: Value(model),
      serialNumber: serialNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(serialNumber),
      internalLocation: Value(internalLocation),
      installedAt: installedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(installedAt),
      cost: cost == null && nullToAbsent ? const Value.absent() : Value(cost),
      notes: Value(notes),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory LocalEquipment.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalEquipment(
      organizationId: serializer.fromJson<String>(json['organizationId']),
      version: serializer.fromJson<int?>(json['version']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      localUpdatedAt: serializer.fromJson<DateTime>(json['localUpdatedAt']),
      lastSyncedAt: serializer.fromJson<DateTime?>(json['lastSyncedAt']),
      syncError: serializer.fromJson<String?>(json['syncError']),
      deleted: serializer.fromJson<bool>(json['deleted']),
      id: serializer.fromJson<String>(json['id']),
      locationId: serializer.fromJson<String>(json['locationId']),
      equipmentTypeId: serializer.fromJson<String>(json['equipmentTypeId']),
      name: serializer.fromJson<String>(json['name']),
      brand: serializer.fromJson<String>(json['brand']),
      model: serializer.fromJson<String>(json['model']),
      serialNumber: serializer.fromJson<String?>(json['serialNumber']),
      internalLocation: serializer.fromJson<String>(json['internalLocation']),
      installedAt: serializer.fromJson<String?>(json['installedAt']),
      cost: serializer.fromJson<String?>(json['cost']),
      notes: serializer.fromJson<String>(json['notes']),
      createdAt: serializer.fromJson<DateTime?>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'organizationId': serializer.toJson<String>(organizationId),
      'version': serializer.toJson<int?>(version),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'localUpdatedAt': serializer.toJson<DateTime>(localUpdatedAt),
      'lastSyncedAt': serializer.toJson<DateTime?>(lastSyncedAt),
      'syncError': serializer.toJson<String?>(syncError),
      'deleted': serializer.toJson<bool>(deleted),
      'id': serializer.toJson<String>(id),
      'locationId': serializer.toJson<String>(locationId),
      'equipmentTypeId': serializer.toJson<String>(equipmentTypeId),
      'name': serializer.toJson<String>(name),
      'brand': serializer.toJson<String>(brand),
      'model': serializer.toJson<String>(model),
      'serialNumber': serializer.toJson<String?>(serialNumber),
      'internalLocation': serializer.toJson<String>(internalLocation),
      'installedAt': serializer.toJson<String?>(installedAt),
      'cost': serializer.toJson<String?>(cost),
      'notes': serializer.toJson<String>(notes),
      'createdAt': serializer.toJson<DateTime?>(createdAt),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
    };
  }

  LocalEquipment copyWith({
    String? organizationId,
    Value<int?> version = const Value.absent(),
    String? syncStatus,
    DateTime? localUpdatedAt,
    Value<DateTime?> lastSyncedAt = const Value.absent(),
    Value<String?> syncError = const Value.absent(),
    bool? deleted,
    String? id,
    String? locationId,
    String? equipmentTypeId,
    String? name,
    String? brand,
    String? model,
    Value<String?> serialNumber = const Value.absent(),
    String? internalLocation,
    Value<String?> installedAt = const Value.absent(),
    Value<String?> cost = const Value.absent(),
    String? notes,
    Value<DateTime?> createdAt = const Value.absent(),
    Value<DateTime?> updatedAt = const Value.absent(),
  }) => LocalEquipment(
    organizationId: organizationId ?? this.organizationId,
    version: version.present ? version.value : this.version,
    syncStatus: syncStatus ?? this.syncStatus,
    localUpdatedAt: localUpdatedAt ?? this.localUpdatedAt,
    lastSyncedAt: lastSyncedAt.present ? lastSyncedAt.value : this.lastSyncedAt,
    syncError: syncError.present ? syncError.value : this.syncError,
    deleted: deleted ?? this.deleted,
    id: id ?? this.id,
    locationId: locationId ?? this.locationId,
    equipmentTypeId: equipmentTypeId ?? this.equipmentTypeId,
    name: name ?? this.name,
    brand: brand ?? this.brand,
    model: model ?? this.model,
    serialNumber: serialNumber.present ? serialNumber.value : this.serialNumber,
    internalLocation: internalLocation ?? this.internalLocation,
    installedAt: installedAt.present ? installedAt.value : this.installedAt,
    cost: cost.present ? cost.value : this.cost,
    notes: notes ?? this.notes,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
  );
  LocalEquipment copyWithCompanion(LocalEquipmentsCompanion data) {
    return LocalEquipment(
      organizationId: data.organizationId.present
          ? data.organizationId.value
          : this.organizationId,
      version: data.version.present ? data.version.value : this.version,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      localUpdatedAt: data.localUpdatedAt.present
          ? data.localUpdatedAt.value
          : this.localUpdatedAt,
      lastSyncedAt: data.lastSyncedAt.present
          ? data.lastSyncedAt.value
          : this.lastSyncedAt,
      syncError: data.syncError.present ? data.syncError.value : this.syncError,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
      id: data.id.present ? data.id.value : this.id,
      locationId: data.locationId.present
          ? data.locationId.value
          : this.locationId,
      equipmentTypeId: data.equipmentTypeId.present
          ? data.equipmentTypeId.value
          : this.equipmentTypeId,
      name: data.name.present ? data.name.value : this.name,
      brand: data.brand.present ? data.brand.value : this.brand,
      model: data.model.present ? data.model.value : this.model,
      serialNumber: data.serialNumber.present
          ? data.serialNumber.value
          : this.serialNumber,
      internalLocation: data.internalLocation.present
          ? data.internalLocation.value
          : this.internalLocation,
      installedAt: data.installedAt.present
          ? data.installedAt.value
          : this.installedAt,
      cost: data.cost.present ? data.cost.value : this.cost,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalEquipment(')
          ..write('organizationId: $organizationId, ')
          ..write('version: $version, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('localUpdatedAt: $localUpdatedAt, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('syncError: $syncError, ')
          ..write('deleted: $deleted, ')
          ..write('id: $id, ')
          ..write('locationId: $locationId, ')
          ..write('equipmentTypeId: $equipmentTypeId, ')
          ..write('name: $name, ')
          ..write('brand: $brand, ')
          ..write('model: $model, ')
          ..write('serialNumber: $serialNumber, ')
          ..write('internalLocation: $internalLocation, ')
          ..write('installedAt: $installedAt, ')
          ..write('cost: $cost, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    organizationId,
    version,
    syncStatus,
    localUpdatedAt,
    lastSyncedAt,
    syncError,
    deleted,
    id,
    locationId,
    equipmentTypeId,
    name,
    brand,
    model,
    serialNumber,
    internalLocation,
    installedAt,
    cost,
    notes,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalEquipment &&
          other.organizationId == this.organizationId &&
          other.version == this.version &&
          other.syncStatus == this.syncStatus &&
          other.localUpdatedAt == this.localUpdatedAt &&
          other.lastSyncedAt == this.lastSyncedAt &&
          other.syncError == this.syncError &&
          other.deleted == this.deleted &&
          other.id == this.id &&
          other.locationId == this.locationId &&
          other.equipmentTypeId == this.equipmentTypeId &&
          other.name == this.name &&
          other.brand == this.brand &&
          other.model == this.model &&
          other.serialNumber == this.serialNumber &&
          other.internalLocation == this.internalLocation &&
          other.installedAt == this.installedAt &&
          other.cost == this.cost &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class LocalEquipmentsCompanion extends UpdateCompanion<LocalEquipment> {
  final Value<String> organizationId;
  final Value<int?> version;
  final Value<String> syncStatus;
  final Value<DateTime> localUpdatedAt;
  final Value<DateTime?> lastSyncedAt;
  final Value<String?> syncError;
  final Value<bool> deleted;
  final Value<String> id;
  final Value<String> locationId;
  final Value<String> equipmentTypeId;
  final Value<String> name;
  final Value<String> brand;
  final Value<String> model;
  final Value<String?> serialNumber;
  final Value<String> internalLocation;
  final Value<String?> installedAt;
  final Value<String?> cost;
  final Value<String> notes;
  final Value<DateTime?> createdAt;
  final Value<DateTime?> updatedAt;
  final Value<int> rowid;
  const LocalEquipmentsCompanion({
    this.organizationId = const Value.absent(),
    this.version = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.localUpdatedAt = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.syncError = const Value.absent(),
    this.deleted = const Value.absent(),
    this.id = const Value.absent(),
    this.locationId = const Value.absent(),
    this.equipmentTypeId = const Value.absent(),
    this.name = const Value.absent(),
    this.brand = const Value.absent(),
    this.model = const Value.absent(),
    this.serialNumber = const Value.absent(),
    this.internalLocation = const Value.absent(),
    this.installedAt = const Value.absent(),
    this.cost = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalEquipmentsCompanion.insert({
    required String organizationId,
    this.version = const Value.absent(),
    this.syncStatus = const Value.absent(),
    required DateTime localUpdatedAt,
    this.lastSyncedAt = const Value.absent(),
    this.syncError = const Value.absent(),
    this.deleted = const Value.absent(),
    required String id,
    required String locationId,
    required String equipmentTypeId,
    required String name,
    this.brand = const Value.absent(),
    this.model = const Value.absent(),
    this.serialNumber = const Value.absent(),
    this.internalLocation = const Value.absent(),
    this.installedAt = const Value.absent(),
    this.cost = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : organizationId = Value(organizationId),
       localUpdatedAt = Value(localUpdatedAt),
       id = Value(id),
       locationId = Value(locationId),
       equipmentTypeId = Value(equipmentTypeId),
       name = Value(name);
  static Insertable<LocalEquipment> custom({
    Expression<String>? organizationId,
    Expression<int>? version,
    Expression<String>? syncStatus,
    Expression<DateTime>? localUpdatedAt,
    Expression<DateTime>? lastSyncedAt,
    Expression<String>? syncError,
    Expression<bool>? deleted,
    Expression<String>? id,
    Expression<String>? locationId,
    Expression<String>? equipmentTypeId,
    Expression<String>? name,
    Expression<String>? brand,
    Expression<String>? model,
    Expression<String>? serialNumber,
    Expression<String>? internalLocation,
    Expression<String>? installedAt,
    Expression<String>? cost,
    Expression<String>? notes,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (organizationId != null) 'organization_id': organizationId,
      if (version != null) 'version': version,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (localUpdatedAt != null) 'local_updated_at': localUpdatedAt,
      if (lastSyncedAt != null) 'last_synced_at': lastSyncedAt,
      if (syncError != null) 'sync_error': syncError,
      if (deleted != null) 'deleted': deleted,
      if (id != null) 'id': id,
      if (locationId != null) 'location_id': locationId,
      if (equipmentTypeId != null) 'equipment_type_id': equipmentTypeId,
      if (name != null) 'name': name,
      if (brand != null) 'brand': brand,
      if (model != null) 'model': model,
      if (serialNumber != null) 'serial_number': serialNumber,
      if (internalLocation != null) 'internal_location': internalLocation,
      if (installedAt != null) 'installed_at': installedAt,
      if (cost != null) 'cost': cost,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalEquipmentsCompanion copyWith({
    Value<String>? organizationId,
    Value<int?>? version,
    Value<String>? syncStatus,
    Value<DateTime>? localUpdatedAt,
    Value<DateTime?>? lastSyncedAt,
    Value<String?>? syncError,
    Value<bool>? deleted,
    Value<String>? id,
    Value<String>? locationId,
    Value<String>? equipmentTypeId,
    Value<String>? name,
    Value<String>? brand,
    Value<String>? model,
    Value<String?>? serialNumber,
    Value<String>? internalLocation,
    Value<String?>? installedAt,
    Value<String?>? cost,
    Value<String>? notes,
    Value<DateTime?>? createdAt,
    Value<DateTime?>? updatedAt,
    Value<int>? rowid,
  }) {
    return LocalEquipmentsCompanion(
      organizationId: organizationId ?? this.organizationId,
      version: version ?? this.version,
      syncStatus: syncStatus ?? this.syncStatus,
      localUpdatedAt: localUpdatedAt ?? this.localUpdatedAt,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      syncError: syncError ?? this.syncError,
      deleted: deleted ?? this.deleted,
      id: id ?? this.id,
      locationId: locationId ?? this.locationId,
      equipmentTypeId: equipmentTypeId ?? this.equipmentTypeId,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      serialNumber: serialNumber ?? this.serialNumber,
      internalLocation: internalLocation ?? this.internalLocation,
      installedAt: installedAt ?? this.installedAt,
      cost: cost ?? this.cost,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (organizationId.present) {
      map['organization_id'] = Variable<String>(organizationId.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (localUpdatedAt.present) {
      map['local_updated_at'] = Variable<DateTime>(localUpdatedAt.value);
    }
    if (lastSyncedAt.present) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt.value);
    }
    if (syncError.present) {
      map['sync_error'] = Variable<String>(syncError.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (locationId.present) {
      map['location_id'] = Variable<String>(locationId.value);
    }
    if (equipmentTypeId.present) {
      map['equipment_type_id'] = Variable<String>(equipmentTypeId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (brand.present) {
      map['brand'] = Variable<String>(brand.value);
    }
    if (model.present) {
      map['model'] = Variable<String>(model.value);
    }
    if (serialNumber.present) {
      map['serial_number'] = Variable<String>(serialNumber.value);
    }
    if (internalLocation.present) {
      map['internal_location'] = Variable<String>(internalLocation.value);
    }
    if (installedAt.present) {
      map['installed_at'] = Variable<String>(installedAt.value);
    }
    if (cost.present) {
      map['cost'] = Variable<String>(cost.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalEquipmentsCompanion(')
          ..write('organizationId: $organizationId, ')
          ..write('version: $version, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('localUpdatedAt: $localUpdatedAt, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('syncError: $syncError, ')
          ..write('deleted: $deleted, ')
          ..write('id: $id, ')
          ..write('locationId: $locationId, ')
          ..write('equipmentTypeId: $equipmentTypeId, ')
          ..write('name: $name, ')
          ..write('brand: $brand, ')
          ..write('model: $model, ')
          ..write('serialNumber: $serialNumber, ')
          ..write('internalLocation: $internalLocation, ')
          ..write('installedAt: $installedAt, ')
          ..write('cost: $cost, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalServiceOrdersTable extends LocalServiceOrders
    with TableInfo<$LocalServiceOrdersTable, LocalServiceOrder> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalServiceOrdersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _organizationIdMeta = const VerificationMeta(
    'organizationId',
  );
  @override
  late final GeneratedColumn<String> organizationId = GeneratedColumn<String>(
    'organization_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('synced'),
  );
  static const VerificationMeta _localUpdatedAtMeta = const VerificationMeta(
    'localUpdatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> localUpdatedAt =
      GeneratedColumn<DateTime>(
        'local_updated_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _lastSyncedAtMeta = const VerificationMeta(
    'lastSyncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSyncedAt = GeneratedColumn<DateTime>(
    'last_synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncErrorMeta = const VerificationMeta(
    'syncError',
  );
  @override
  late final GeneratedColumn<String> syncError = GeneratedColumn<String>(
    'sync_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deletedMeta = const VerificationMeta(
    'deleted',
  );
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
    'deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _clientIdMeta = const VerificationMeta(
    'clientId',
  );
  @override
  late final GeneratedColumn<String> clientId = GeneratedColumn<String>(
    'client_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _locationIdMeta = const VerificationMeta(
    'locationId',
  );
  @override
  late final GeneratedColumn<String> locationId = GeneratedColumn<String>(
    'location_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _equipmentIdMeta = const VerificationMeta(
    'equipmentId',
  );
  @override
  late final GeneratedColumn<String> equipmentId = GeneratedColumn<String>(
    'equipment_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _serviceOrderTypeIdMeta =
      const VerificationMeta('serviceOrderTypeId');
  @override
  late final GeneratedColumn<String> serviceOrderTypeId =
      GeneratedColumn<String>(
        'service_order_type_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _companyIdMeta = const VerificationMeta(
    'companyId',
  );
  @override
  late final GeneratedColumn<String> companyId = GeneratedColumn<String>(
    'company_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _assignedUserIdMeta = const VerificationMeta(
    'assignedUserId',
  );
  @override
  late final GeneratedColumn<String> assignedUserId = GeneratedColumn<String>(
    'assigned_user_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('draft'),
  );
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  @override
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
    'reason',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _diagnosisMeta = const VerificationMeta(
    'diagnosis',
  );
  @override
  late final GeneratedColumn<String> diagnosis = GeneratedColumn<String>(
    'diagnosis',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _workPerformedMeta = const VerificationMeta(
    'workPerformed',
  );
  @override
  late final GeneratedColumn<String> workPerformed = GeneratedColumn<String>(
    'work_performed',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _recommendationsMeta = const VerificationMeta(
    'recommendations',
  );
  @override
  late final GeneratedColumn<String> recommendations = GeneratedColumn<String>(
    'recommendations',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _finalConditionMeta = const VerificationMeta(
    'finalCondition',
  );
  @override
  late final GeneratedColumn<String> finalCondition = GeneratedColumn<String>(
    'final_condition',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _scheduledForMeta = const VerificationMeta(
    'scheduledFor',
  );
  @override
  late final GeneratedColumn<DateTime> scheduledFor = GeneratedColumn<DateTime>(
    'scheduled_for',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    organizationId,
    version,
    syncStatus,
    localUpdatedAt,
    lastSyncedAt,
    syncError,
    deleted,
    id,
    clientId,
    locationId,
    equipmentId,
    serviceOrderTypeId,
    companyId,
    assignedUserId,
    status,
    reason,
    diagnosis,
    workPerformed,
    recommendations,
    finalCondition,
    notes,
    scheduledFor,
    startedAt,
    completedAt,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_service_orders';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalServiceOrder> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('organization_id')) {
      context.handle(
        _organizationIdMeta,
        organizationId.isAcceptableOrUnknown(
          data['organization_id']!,
          _organizationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_organizationIdMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('local_updated_at')) {
      context.handle(
        _localUpdatedAtMeta,
        localUpdatedAt.isAcceptableOrUnknown(
          data['local_updated_at']!,
          _localUpdatedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_localUpdatedAtMeta);
    }
    if (data.containsKey('last_synced_at')) {
      context.handle(
        _lastSyncedAtMeta,
        lastSyncedAt.isAcceptableOrUnknown(
          data['last_synced_at']!,
          _lastSyncedAtMeta,
        ),
      );
    }
    if (data.containsKey('sync_error')) {
      context.handle(
        _syncErrorMeta,
        syncError.isAcceptableOrUnknown(data['sync_error']!, _syncErrorMeta),
      );
    }
    if (data.containsKey('deleted')) {
      context.handle(
        _deletedMeta,
        deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta),
      );
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('client_id')) {
      context.handle(
        _clientIdMeta,
        clientId.isAcceptableOrUnknown(data['client_id']!, _clientIdMeta),
      );
    } else if (isInserting) {
      context.missing(_clientIdMeta);
    }
    if (data.containsKey('location_id')) {
      context.handle(
        _locationIdMeta,
        locationId.isAcceptableOrUnknown(data['location_id']!, _locationIdMeta),
      );
    }
    if (data.containsKey('equipment_id')) {
      context.handle(
        _equipmentIdMeta,
        equipmentId.isAcceptableOrUnknown(
          data['equipment_id']!,
          _equipmentIdMeta,
        ),
      );
    }
    if (data.containsKey('service_order_type_id')) {
      context.handle(
        _serviceOrderTypeIdMeta,
        serviceOrderTypeId.isAcceptableOrUnknown(
          data['service_order_type_id']!,
          _serviceOrderTypeIdMeta,
        ),
      );
    }
    if (data.containsKey('company_id')) {
      context.handle(
        _companyIdMeta,
        companyId.isAcceptableOrUnknown(data['company_id']!, _companyIdMeta),
      );
    }
    if (data.containsKey('assigned_user_id')) {
      context.handle(
        _assignedUserIdMeta,
        assignedUserId.isAcceptableOrUnknown(
          data['assigned_user_id']!,
          _assignedUserIdMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('reason')) {
      context.handle(
        _reasonMeta,
        reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta),
      );
    }
    if (data.containsKey('diagnosis')) {
      context.handle(
        _diagnosisMeta,
        diagnosis.isAcceptableOrUnknown(data['diagnosis']!, _diagnosisMeta),
      );
    }
    if (data.containsKey('work_performed')) {
      context.handle(
        _workPerformedMeta,
        workPerformed.isAcceptableOrUnknown(
          data['work_performed']!,
          _workPerformedMeta,
        ),
      );
    }
    if (data.containsKey('recommendations')) {
      context.handle(
        _recommendationsMeta,
        recommendations.isAcceptableOrUnknown(
          data['recommendations']!,
          _recommendationsMeta,
        ),
      );
    }
    if (data.containsKey('final_condition')) {
      context.handle(
        _finalConditionMeta,
        finalCondition.isAcceptableOrUnknown(
          data['final_condition']!,
          _finalConditionMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('scheduled_for')) {
      context.handle(
        _scheduledForMeta,
        scheduledFor.isAcceptableOrUnknown(
          data['scheduled_for']!,
          _scheduledForMeta,
        ),
      );
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalServiceOrder map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalServiceOrder(
      organizationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}organization_id'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      ),
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
      localUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}local_updated_at'],
      )!,
      lastSyncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_synced_at'],
      ),
      syncError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_error'],
      ),
      deleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}deleted'],
      )!,
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      clientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_id'],
      )!,
      locationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}location_id'],
      ),
      equipmentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}equipment_id'],
      ),
      serviceOrderTypeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}service_order_type_id'],
      ),
      companyId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}company_id'],
      ),
      assignedUserId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}assigned_user_id'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      reason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reason'],
      )!,
      diagnosis: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}diagnosis'],
      )!,
      workPerformed: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}work_performed'],
      )!,
      recommendations: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recommendations'],
      )!,
      finalCondition: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}final_condition'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      )!,
      scheduledFor: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}scheduled_for'],
      ),
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      ),
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      ),
    );
  }

  @override
  $LocalServiceOrdersTable createAlias(String alias) {
    return $LocalServiceOrdersTable(attachedDatabase, alias);
  }
}

class LocalServiceOrder extends DataClass
    implements Insertable<LocalServiceOrder> {
  final String organizationId;
  final int? version;
  final String syncStatus;
  final DateTime localUpdatedAt;
  final DateTime? lastSyncedAt;
  final String? syncError;
  final bool deleted;
  final String id;
  final String clientId;
  final String? locationId;
  final String? equipmentId;
  final String? serviceOrderTypeId;
  final String? companyId;
  final String? assignedUserId;
  final String status;
  final String reason;
  final String diagnosis;
  final String workPerformed;
  final String recommendations;
  final String finalCondition;
  final String notes;
  final DateTime? scheduledFor;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  const LocalServiceOrder({
    required this.organizationId,
    this.version,
    required this.syncStatus,
    required this.localUpdatedAt,
    this.lastSyncedAt,
    this.syncError,
    required this.deleted,
    required this.id,
    required this.clientId,
    this.locationId,
    this.equipmentId,
    this.serviceOrderTypeId,
    this.companyId,
    this.assignedUserId,
    required this.status,
    required this.reason,
    required this.diagnosis,
    required this.workPerformed,
    required this.recommendations,
    required this.finalCondition,
    required this.notes,
    this.scheduledFor,
    this.startedAt,
    this.completedAt,
    this.createdAt,
    this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['organization_id'] = Variable<String>(organizationId);
    if (!nullToAbsent || version != null) {
      map['version'] = Variable<int>(version);
    }
    map['sync_status'] = Variable<String>(syncStatus);
    map['local_updated_at'] = Variable<DateTime>(localUpdatedAt);
    if (!nullToAbsent || lastSyncedAt != null) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt);
    }
    if (!nullToAbsent || syncError != null) {
      map['sync_error'] = Variable<String>(syncError);
    }
    map['deleted'] = Variable<bool>(deleted);
    map['id'] = Variable<String>(id);
    map['client_id'] = Variable<String>(clientId);
    if (!nullToAbsent || locationId != null) {
      map['location_id'] = Variable<String>(locationId);
    }
    if (!nullToAbsent || equipmentId != null) {
      map['equipment_id'] = Variable<String>(equipmentId);
    }
    if (!nullToAbsent || serviceOrderTypeId != null) {
      map['service_order_type_id'] = Variable<String>(serviceOrderTypeId);
    }
    if (!nullToAbsent || companyId != null) {
      map['company_id'] = Variable<String>(companyId);
    }
    if (!nullToAbsent || assignedUserId != null) {
      map['assigned_user_id'] = Variable<String>(assignedUserId);
    }
    map['status'] = Variable<String>(status);
    map['reason'] = Variable<String>(reason);
    map['diagnosis'] = Variable<String>(diagnosis);
    map['work_performed'] = Variable<String>(workPerformed);
    map['recommendations'] = Variable<String>(recommendations);
    map['final_condition'] = Variable<String>(finalCondition);
    map['notes'] = Variable<String>(notes);
    if (!nullToAbsent || scheduledFor != null) {
      map['scheduled_for'] = Variable<DateTime>(scheduledFor);
    }
    if (!nullToAbsent || startedAt != null) {
      map['started_at'] = Variable<DateTime>(startedAt);
    }
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<DateTime>(createdAt);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    return map;
  }

  LocalServiceOrdersCompanion toCompanion(bool nullToAbsent) {
    return LocalServiceOrdersCompanion(
      organizationId: Value(organizationId),
      version: version == null && nullToAbsent
          ? const Value.absent()
          : Value(version),
      syncStatus: Value(syncStatus),
      localUpdatedAt: Value(localUpdatedAt),
      lastSyncedAt: lastSyncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncedAt),
      syncError: syncError == null && nullToAbsent
          ? const Value.absent()
          : Value(syncError),
      deleted: Value(deleted),
      id: Value(id),
      clientId: Value(clientId),
      locationId: locationId == null && nullToAbsent
          ? const Value.absent()
          : Value(locationId),
      equipmentId: equipmentId == null && nullToAbsent
          ? const Value.absent()
          : Value(equipmentId),
      serviceOrderTypeId: serviceOrderTypeId == null && nullToAbsent
          ? const Value.absent()
          : Value(serviceOrderTypeId),
      companyId: companyId == null && nullToAbsent
          ? const Value.absent()
          : Value(companyId),
      assignedUserId: assignedUserId == null && nullToAbsent
          ? const Value.absent()
          : Value(assignedUserId),
      status: Value(status),
      reason: Value(reason),
      diagnosis: Value(diagnosis),
      workPerformed: Value(workPerformed),
      recommendations: Value(recommendations),
      finalCondition: Value(finalCondition),
      notes: Value(notes),
      scheduledFor: scheduledFor == null && nullToAbsent
          ? const Value.absent()
          : Value(scheduledFor),
      startedAt: startedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(startedAt),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory LocalServiceOrder.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalServiceOrder(
      organizationId: serializer.fromJson<String>(json['organizationId']),
      version: serializer.fromJson<int?>(json['version']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      localUpdatedAt: serializer.fromJson<DateTime>(json['localUpdatedAt']),
      lastSyncedAt: serializer.fromJson<DateTime?>(json['lastSyncedAt']),
      syncError: serializer.fromJson<String?>(json['syncError']),
      deleted: serializer.fromJson<bool>(json['deleted']),
      id: serializer.fromJson<String>(json['id']),
      clientId: serializer.fromJson<String>(json['clientId']),
      locationId: serializer.fromJson<String?>(json['locationId']),
      equipmentId: serializer.fromJson<String?>(json['equipmentId']),
      serviceOrderTypeId: serializer.fromJson<String?>(
        json['serviceOrderTypeId'],
      ),
      companyId: serializer.fromJson<String?>(json['companyId']),
      assignedUserId: serializer.fromJson<String?>(json['assignedUserId']),
      status: serializer.fromJson<String>(json['status']),
      reason: serializer.fromJson<String>(json['reason']),
      diagnosis: serializer.fromJson<String>(json['diagnosis']),
      workPerformed: serializer.fromJson<String>(json['workPerformed']),
      recommendations: serializer.fromJson<String>(json['recommendations']),
      finalCondition: serializer.fromJson<String>(json['finalCondition']),
      notes: serializer.fromJson<String>(json['notes']),
      scheduledFor: serializer.fromJson<DateTime?>(json['scheduledFor']),
      startedAt: serializer.fromJson<DateTime?>(json['startedAt']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
      createdAt: serializer.fromJson<DateTime?>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'organizationId': serializer.toJson<String>(organizationId),
      'version': serializer.toJson<int?>(version),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'localUpdatedAt': serializer.toJson<DateTime>(localUpdatedAt),
      'lastSyncedAt': serializer.toJson<DateTime?>(lastSyncedAt),
      'syncError': serializer.toJson<String?>(syncError),
      'deleted': serializer.toJson<bool>(deleted),
      'id': serializer.toJson<String>(id),
      'clientId': serializer.toJson<String>(clientId),
      'locationId': serializer.toJson<String?>(locationId),
      'equipmentId': serializer.toJson<String?>(equipmentId),
      'serviceOrderTypeId': serializer.toJson<String?>(serviceOrderTypeId),
      'companyId': serializer.toJson<String?>(companyId),
      'assignedUserId': serializer.toJson<String?>(assignedUserId),
      'status': serializer.toJson<String>(status),
      'reason': serializer.toJson<String>(reason),
      'diagnosis': serializer.toJson<String>(diagnosis),
      'workPerformed': serializer.toJson<String>(workPerformed),
      'recommendations': serializer.toJson<String>(recommendations),
      'finalCondition': serializer.toJson<String>(finalCondition),
      'notes': serializer.toJson<String>(notes),
      'scheduledFor': serializer.toJson<DateTime?>(scheduledFor),
      'startedAt': serializer.toJson<DateTime?>(startedAt),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
      'createdAt': serializer.toJson<DateTime?>(createdAt),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
    };
  }

  LocalServiceOrder copyWith({
    String? organizationId,
    Value<int?> version = const Value.absent(),
    String? syncStatus,
    DateTime? localUpdatedAt,
    Value<DateTime?> lastSyncedAt = const Value.absent(),
    Value<String?> syncError = const Value.absent(),
    bool? deleted,
    String? id,
    String? clientId,
    Value<String?> locationId = const Value.absent(),
    Value<String?> equipmentId = const Value.absent(),
    Value<String?> serviceOrderTypeId = const Value.absent(),
    Value<String?> companyId = const Value.absent(),
    Value<String?> assignedUserId = const Value.absent(),
    String? status,
    String? reason,
    String? diagnosis,
    String? workPerformed,
    String? recommendations,
    String? finalCondition,
    String? notes,
    Value<DateTime?> scheduledFor = const Value.absent(),
    Value<DateTime?> startedAt = const Value.absent(),
    Value<DateTime?> completedAt = const Value.absent(),
    Value<DateTime?> createdAt = const Value.absent(),
    Value<DateTime?> updatedAt = const Value.absent(),
  }) => LocalServiceOrder(
    organizationId: organizationId ?? this.organizationId,
    version: version.present ? version.value : this.version,
    syncStatus: syncStatus ?? this.syncStatus,
    localUpdatedAt: localUpdatedAt ?? this.localUpdatedAt,
    lastSyncedAt: lastSyncedAt.present ? lastSyncedAt.value : this.lastSyncedAt,
    syncError: syncError.present ? syncError.value : this.syncError,
    deleted: deleted ?? this.deleted,
    id: id ?? this.id,
    clientId: clientId ?? this.clientId,
    locationId: locationId.present ? locationId.value : this.locationId,
    equipmentId: equipmentId.present ? equipmentId.value : this.equipmentId,
    serviceOrderTypeId: serviceOrderTypeId.present
        ? serviceOrderTypeId.value
        : this.serviceOrderTypeId,
    companyId: companyId.present ? companyId.value : this.companyId,
    assignedUserId: assignedUserId.present
        ? assignedUserId.value
        : this.assignedUserId,
    status: status ?? this.status,
    reason: reason ?? this.reason,
    diagnosis: diagnosis ?? this.diagnosis,
    workPerformed: workPerformed ?? this.workPerformed,
    recommendations: recommendations ?? this.recommendations,
    finalCondition: finalCondition ?? this.finalCondition,
    notes: notes ?? this.notes,
    scheduledFor: scheduledFor.present ? scheduledFor.value : this.scheduledFor,
    startedAt: startedAt.present ? startedAt.value : this.startedAt,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
  );
  LocalServiceOrder copyWithCompanion(LocalServiceOrdersCompanion data) {
    return LocalServiceOrder(
      organizationId: data.organizationId.present
          ? data.organizationId.value
          : this.organizationId,
      version: data.version.present ? data.version.value : this.version,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      localUpdatedAt: data.localUpdatedAt.present
          ? data.localUpdatedAt.value
          : this.localUpdatedAt,
      lastSyncedAt: data.lastSyncedAt.present
          ? data.lastSyncedAt.value
          : this.lastSyncedAt,
      syncError: data.syncError.present ? data.syncError.value : this.syncError,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
      id: data.id.present ? data.id.value : this.id,
      clientId: data.clientId.present ? data.clientId.value : this.clientId,
      locationId: data.locationId.present
          ? data.locationId.value
          : this.locationId,
      equipmentId: data.equipmentId.present
          ? data.equipmentId.value
          : this.equipmentId,
      serviceOrderTypeId: data.serviceOrderTypeId.present
          ? data.serviceOrderTypeId.value
          : this.serviceOrderTypeId,
      companyId: data.companyId.present ? data.companyId.value : this.companyId,
      assignedUserId: data.assignedUserId.present
          ? data.assignedUserId.value
          : this.assignedUserId,
      status: data.status.present ? data.status.value : this.status,
      reason: data.reason.present ? data.reason.value : this.reason,
      diagnosis: data.diagnosis.present ? data.diagnosis.value : this.diagnosis,
      workPerformed: data.workPerformed.present
          ? data.workPerformed.value
          : this.workPerformed,
      recommendations: data.recommendations.present
          ? data.recommendations.value
          : this.recommendations,
      finalCondition: data.finalCondition.present
          ? data.finalCondition.value
          : this.finalCondition,
      notes: data.notes.present ? data.notes.value : this.notes,
      scheduledFor: data.scheduledFor.present
          ? data.scheduledFor.value
          : this.scheduledFor,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalServiceOrder(')
          ..write('organizationId: $organizationId, ')
          ..write('version: $version, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('localUpdatedAt: $localUpdatedAt, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('syncError: $syncError, ')
          ..write('deleted: $deleted, ')
          ..write('id: $id, ')
          ..write('clientId: $clientId, ')
          ..write('locationId: $locationId, ')
          ..write('equipmentId: $equipmentId, ')
          ..write('serviceOrderTypeId: $serviceOrderTypeId, ')
          ..write('companyId: $companyId, ')
          ..write('assignedUserId: $assignedUserId, ')
          ..write('status: $status, ')
          ..write('reason: $reason, ')
          ..write('diagnosis: $diagnosis, ')
          ..write('workPerformed: $workPerformed, ')
          ..write('recommendations: $recommendations, ')
          ..write('finalCondition: $finalCondition, ')
          ..write('notes: $notes, ')
          ..write('scheduledFor: $scheduledFor, ')
          ..write('startedAt: $startedAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    organizationId,
    version,
    syncStatus,
    localUpdatedAt,
    lastSyncedAt,
    syncError,
    deleted,
    id,
    clientId,
    locationId,
    equipmentId,
    serviceOrderTypeId,
    companyId,
    assignedUserId,
    status,
    reason,
    diagnosis,
    workPerformed,
    recommendations,
    finalCondition,
    notes,
    scheduledFor,
    startedAt,
    completedAt,
    createdAt,
    updatedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalServiceOrder &&
          other.organizationId == this.organizationId &&
          other.version == this.version &&
          other.syncStatus == this.syncStatus &&
          other.localUpdatedAt == this.localUpdatedAt &&
          other.lastSyncedAt == this.lastSyncedAt &&
          other.syncError == this.syncError &&
          other.deleted == this.deleted &&
          other.id == this.id &&
          other.clientId == this.clientId &&
          other.locationId == this.locationId &&
          other.equipmentId == this.equipmentId &&
          other.serviceOrderTypeId == this.serviceOrderTypeId &&
          other.companyId == this.companyId &&
          other.assignedUserId == this.assignedUserId &&
          other.status == this.status &&
          other.reason == this.reason &&
          other.diagnosis == this.diagnosis &&
          other.workPerformed == this.workPerformed &&
          other.recommendations == this.recommendations &&
          other.finalCondition == this.finalCondition &&
          other.notes == this.notes &&
          other.scheduledFor == this.scheduledFor &&
          other.startedAt == this.startedAt &&
          other.completedAt == this.completedAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class LocalServiceOrdersCompanion extends UpdateCompanion<LocalServiceOrder> {
  final Value<String> organizationId;
  final Value<int?> version;
  final Value<String> syncStatus;
  final Value<DateTime> localUpdatedAt;
  final Value<DateTime?> lastSyncedAt;
  final Value<String?> syncError;
  final Value<bool> deleted;
  final Value<String> id;
  final Value<String> clientId;
  final Value<String?> locationId;
  final Value<String?> equipmentId;
  final Value<String?> serviceOrderTypeId;
  final Value<String?> companyId;
  final Value<String?> assignedUserId;
  final Value<String> status;
  final Value<String> reason;
  final Value<String> diagnosis;
  final Value<String> workPerformed;
  final Value<String> recommendations;
  final Value<String> finalCondition;
  final Value<String> notes;
  final Value<DateTime?> scheduledFor;
  final Value<DateTime?> startedAt;
  final Value<DateTime?> completedAt;
  final Value<DateTime?> createdAt;
  final Value<DateTime?> updatedAt;
  final Value<int> rowid;
  const LocalServiceOrdersCompanion({
    this.organizationId = const Value.absent(),
    this.version = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.localUpdatedAt = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.syncError = const Value.absent(),
    this.deleted = const Value.absent(),
    this.id = const Value.absent(),
    this.clientId = const Value.absent(),
    this.locationId = const Value.absent(),
    this.equipmentId = const Value.absent(),
    this.serviceOrderTypeId = const Value.absent(),
    this.companyId = const Value.absent(),
    this.assignedUserId = const Value.absent(),
    this.status = const Value.absent(),
    this.reason = const Value.absent(),
    this.diagnosis = const Value.absent(),
    this.workPerformed = const Value.absent(),
    this.recommendations = const Value.absent(),
    this.finalCondition = const Value.absent(),
    this.notes = const Value.absent(),
    this.scheduledFor = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalServiceOrdersCompanion.insert({
    required String organizationId,
    this.version = const Value.absent(),
    this.syncStatus = const Value.absent(),
    required DateTime localUpdatedAt,
    this.lastSyncedAt = const Value.absent(),
    this.syncError = const Value.absent(),
    this.deleted = const Value.absent(),
    required String id,
    required String clientId,
    this.locationId = const Value.absent(),
    this.equipmentId = const Value.absent(),
    this.serviceOrderTypeId = const Value.absent(),
    this.companyId = const Value.absent(),
    this.assignedUserId = const Value.absent(),
    this.status = const Value.absent(),
    this.reason = const Value.absent(),
    this.diagnosis = const Value.absent(),
    this.workPerformed = const Value.absent(),
    this.recommendations = const Value.absent(),
    this.finalCondition = const Value.absent(),
    this.notes = const Value.absent(),
    this.scheduledFor = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : organizationId = Value(organizationId),
       localUpdatedAt = Value(localUpdatedAt),
       id = Value(id),
       clientId = Value(clientId);
  static Insertable<LocalServiceOrder> custom({
    Expression<String>? organizationId,
    Expression<int>? version,
    Expression<String>? syncStatus,
    Expression<DateTime>? localUpdatedAt,
    Expression<DateTime>? lastSyncedAt,
    Expression<String>? syncError,
    Expression<bool>? deleted,
    Expression<String>? id,
    Expression<String>? clientId,
    Expression<String>? locationId,
    Expression<String>? equipmentId,
    Expression<String>? serviceOrderTypeId,
    Expression<String>? companyId,
    Expression<String>? assignedUserId,
    Expression<String>? status,
    Expression<String>? reason,
    Expression<String>? diagnosis,
    Expression<String>? workPerformed,
    Expression<String>? recommendations,
    Expression<String>? finalCondition,
    Expression<String>? notes,
    Expression<DateTime>? scheduledFor,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? completedAt,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (organizationId != null) 'organization_id': organizationId,
      if (version != null) 'version': version,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (localUpdatedAt != null) 'local_updated_at': localUpdatedAt,
      if (lastSyncedAt != null) 'last_synced_at': lastSyncedAt,
      if (syncError != null) 'sync_error': syncError,
      if (deleted != null) 'deleted': deleted,
      if (id != null) 'id': id,
      if (clientId != null) 'client_id': clientId,
      if (locationId != null) 'location_id': locationId,
      if (equipmentId != null) 'equipment_id': equipmentId,
      if (serviceOrderTypeId != null)
        'service_order_type_id': serviceOrderTypeId,
      if (companyId != null) 'company_id': companyId,
      if (assignedUserId != null) 'assigned_user_id': assignedUserId,
      if (status != null) 'status': status,
      if (reason != null) 'reason': reason,
      if (diagnosis != null) 'diagnosis': diagnosis,
      if (workPerformed != null) 'work_performed': workPerformed,
      if (recommendations != null) 'recommendations': recommendations,
      if (finalCondition != null) 'final_condition': finalCondition,
      if (notes != null) 'notes': notes,
      if (scheduledFor != null) 'scheduled_for': scheduledFor,
      if (startedAt != null) 'started_at': startedAt,
      if (completedAt != null) 'completed_at': completedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalServiceOrdersCompanion copyWith({
    Value<String>? organizationId,
    Value<int?>? version,
    Value<String>? syncStatus,
    Value<DateTime>? localUpdatedAt,
    Value<DateTime?>? lastSyncedAt,
    Value<String?>? syncError,
    Value<bool>? deleted,
    Value<String>? id,
    Value<String>? clientId,
    Value<String?>? locationId,
    Value<String?>? equipmentId,
    Value<String?>? serviceOrderTypeId,
    Value<String?>? companyId,
    Value<String?>? assignedUserId,
    Value<String>? status,
    Value<String>? reason,
    Value<String>? diagnosis,
    Value<String>? workPerformed,
    Value<String>? recommendations,
    Value<String>? finalCondition,
    Value<String>? notes,
    Value<DateTime?>? scheduledFor,
    Value<DateTime?>? startedAt,
    Value<DateTime?>? completedAt,
    Value<DateTime?>? createdAt,
    Value<DateTime?>? updatedAt,
    Value<int>? rowid,
  }) {
    return LocalServiceOrdersCompanion(
      organizationId: organizationId ?? this.organizationId,
      version: version ?? this.version,
      syncStatus: syncStatus ?? this.syncStatus,
      localUpdatedAt: localUpdatedAt ?? this.localUpdatedAt,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      syncError: syncError ?? this.syncError,
      deleted: deleted ?? this.deleted,
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      locationId: locationId ?? this.locationId,
      equipmentId: equipmentId ?? this.equipmentId,
      serviceOrderTypeId: serviceOrderTypeId ?? this.serviceOrderTypeId,
      companyId: companyId ?? this.companyId,
      assignedUserId: assignedUserId ?? this.assignedUserId,
      status: status ?? this.status,
      reason: reason ?? this.reason,
      diagnosis: diagnosis ?? this.diagnosis,
      workPerformed: workPerformed ?? this.workPerformed,
      recommendations: recommendations ?? this.recommendations,
      finalCondition: finalCondition ?? this.finalCondition,
      notes: notes ?? this.notes,
      scheduledFor: scheduledFor ?? this.scheduledFor,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (organizationId.present) {
      map['organization_id'] = Variable<String>(organizationId.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (localUpdatedAt.present) {
      map['local_updated_at'] = Variable<DateTime>(localUpdatedAt.value);
    }
    if (lastSyncedAt.present) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt.value);
    }
    if (syncError.present) {
      map['sync_error'] = Variable<String>(syncError.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (clientId.present) {
      map['client_id'] = Variable<String>(clientId.value);
    }
    if (locationId.present) {
      map['location_id'] = Variable<String>(locationId.value);
    }
    if (equipmentId.present) {
      map['equipment_id'] = Variable<String>(equipmentId.value);
    }
    if (serviceOrderTypeId.present) {
      map['service_order_type_id'] = Variable<String>(serviceOrderTypeId.value);
    }
    if (companyId.present) {
      map['company_id'] = Variable<String>(companyId.value);
    }
    if (assignedUserId.present) {
      map['assigned_user_id'] = Variable<String>(assignedUserId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    if (diagnosis.present) {
      map['diagnosis'] = Variable<String>(diagnosis.value);
    }
    if (workPerformed.present) {
      map['work_performed'] = Variable<String>(workPerformed.value);
    }
    if (recommendations.present) {
      map['recommendations'] = Variable<String>(recommendations.value);
    }
    if (finalCondition.present) {
      map['final_condition'] = Variable<String>(finalCondition.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (scheduledFor.present) {
      map['scheduled_for'] = Variable<DateTime>(scheduledFor.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalServiceOrdersCompanion(')
          ..write('organizationId: $organizationId, ')
          ..write('version: $version, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('localUpdatedAt: $localUpdatedAt, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('syncError: $syncError, ')
          ..write('deleted: $deleted, ')
          ..write('id: $id, ')
          ..write('clientId: $clientId, ')
          ..write('locationId: $locationId, ')
          ..write('equipmentId: $equipmentId, ')
          ..write('serviceOrderTypeId: $serviceOrderTypeId, ')
          ..write('companyId: $companyId, ')
          ..write('assignedUserId: $assignedUserId, ')
          ..write('status: $status, ')
          ..write('reason: $reason, ')
          ..write('diagnosis: $diagnosis, ')
          ..write('workPerformed: $workPerformed, ')
          ..write('recommendations: $recommendations, ')
          ..write('finalCondition: $finalCondition, ')
          ..write('notes: $notes, ')
          ..write('scheduledFor: $scheduledFor, ')
          ..write('startedAt: $startedAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalServiceOrderPartsTable extends LocalServiceOrderParts
    with TableInfo<$LocalServiceOrderPartsTable, LocalServiceOrderPart> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalServiceOrderPartsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _organizationIdMeta = const VerificationMeta(
    'organizationId',
  );
  @override
  late final GeneratedColumn<String> organizationId = GeneratedColumn<String>(
    'organization_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('synced'),
  );
  static const VerificationMeta _localUpdatedAtMeta = const VerificationMeta(
    'localUpdatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> localUpdatedAt =
      GeneratedColumn<DateTime>(
        'local_updated_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _lastSyncedAtMeta = const VerificationMeta(
    'lastSyncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSyncedAt = GeneratedColumn<DateTime>(
    'last_synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncErrorMeta = const VerificationMeta(
    'syncError',
  );
  @override
  late final GeneratedColumn<String> syncError = GeneratedColumn<String>(
    'sync_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deletedMeta = const VerificationMeta(
    'deleted',
  );
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
    'deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _serviceOrderIdMeta = const VerificationMeta(
    'serviceOrderId',
  );
  @override
  late final GeneratedColumn<String> serviceOrderId = GeneratedColumn<String>(
    'service_order_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _partNumberMeta = const VerificationMeta(
    'partNumber',
  );
  @override
  late final GeneratedColumn<String> partNumber = GeneratedColumn<String>(
    'part_number',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _quantityMeta = const VerificationMeta(
    'quantity',
  );
  @override
  late final GeneratedColumn<String> quantity = GeneratedColumn<String>(
    'quantity',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('1'),
  );
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
    'unit',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _unitCostMeta = const VerificationMeta(
    'unitCost',
  );
  @override
  late final GeneratedColumn<String> unitCost = GeneratedColumn<String>(
    'unit_cost',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _unitPriceMeta = const VerificationMeta(
    'unitPrice',
  );
  @override
  late final GeneratedColumn<String> unitPrice = GeneratedColumn<String>(
    'unit_price',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    organizationId,
    version,
    syncStatus,
    localUpdatedAt,
    lastSyncedAt,
    syncError,
    deleted,
    id,
    serviceOrderId,
    description,
    partNumber,
    quantity,
    unit,
    unitCost,
    unitPrice,
    notes,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_service_order_parts';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalServiceOrderPart> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('organization_id')) {
      context.handle(
        _organizationIdMeta,
        organizationId.isAcceptableOrUnknown(
          data['organization_id']!,
          _organizationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_organizationIdMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('local_updated_at')) {
      context.handle(
        _localUpdatedAtMeta,
        localUpdatedAt.isAcceptableOrUnknown(
          data['local_updated_at']!,
          _localUpdatedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_localUpdatedAtMeta);
    }
    if (data.containsKey('last_synced_at')) {
      context.handle(
        _lastSyncedAtMeta,
        lastSyncedAt.isAcceptableOrUnknown(
          data['last_synced_at']!,
          _lastSyncedAtMeta,
        ),
      );
    }
    if (data.containsKey('sync_error')) {
      context.handle(
        _syncErrorMeta,
        syncError.isAcceptableOrUnknown(data['sync_error']!, _syncErrorMeta),
      );
    }
    if (data.containsKey('deleted')) {
      context.handle(
        _deletedMeta,
        deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta),
      );
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('service_order_id')) {
      context.handle(
        _serviceOrderIdMeta,
        serviceOrderId.isAcceptableOrUnknown(
          data['service_order_id']!,
          _serviceOrderIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_serviceOrderIdMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('part_number')) {
      context.handle(
        _partNumberMeta,
        partNumber.isAcceptableOrUnknown(data['part_number']!, _partNumberMeta),
      );
    }
    if (data.containsKey('quantity')) {
      context.handle(
        _quantityMeta,
        quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta),
      );
    }
    if (data.containsKey('unit')) {
      context.handle(
        _unitMeta,
        unit.isAcceptableOrUnknown(data['unit']!, _unitMeta),
      );
    }
    if (data.containsKey('unit_cost')) {
      context.handle(
        _unitCostMeta,
        unitCost.isAcceptableOrUnknown(data['unit_cost']!, _unitCostMeta),
      );
    }
    if (data.containsKey('unit_price')) {
      context.handle(
        _unitPriceMeta,
        unitPrice.isAcceptableOrUnknown(data['unit_price']!, _unitPriceMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalServiceOrderPart map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalServiceOrderPart(
      organizationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}organization_id'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      ),
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
      localUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}local_updated_at'],
      )!,
      lastSyncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_synced_at'],
      ),
      syncError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_error'],
      ),
      deleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}deleted'],
      )!,
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      serviceOrderId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}service_order_id'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      partNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}part_number'],
      )!,
      quantity: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}quantity'],
      )!,
      unit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit'],
      )!,
      unitCost: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit_cost'],
      ),
      unitPrice: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit_price'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      ),
    );
  }

  @override
  $LocalServiceOrderPartsTable createAlias(String alias) {
    return $LocalServiceOrderPartsTable(attachedDatabase, alias);
  }
}

class LocalServiceOrderPart extends DataClass
    implements Insertable<LocalServiceOrderPart> {
  final String organizationId;
  final int? version;
  final String syncStatus;
  final DateTime localUpdatedAt;
  final DateTime? lastSyncedAt;
  final String? syncError;
  final bool deleted;
  final String id;
  final String serviceOrderId;
  final String description;
  final String partNumber;
  final String quantity;
  final String unit;
  final String? unitCost;
  final String? unitPrice;
  final String notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  const LocalServiceOrderPart({
    required this.organizationId,
    this.version,
    required this.syncStatus,
    required this.localUpdatedAt,
    this.lastSyncedAt,
    this.syncError,
    required this.deleted,
    required this.id,
    required this.serviceOrderId,
    required this.description,
    required this.partNumber,
    required this.quantity,
    required this.unit,
    this.unitCost,
    this.unitPrice,
    required this.notes,
    this.createdAt,
    this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['organization_id'] = Variable<String>(organizationId);
    if (!nullToAbsent || version != null) {
      map['version'] = Variable<int>(version);
    }
    map['sync_status'] = Variable<String>(syncStatus);
    map['local_updated_at'] = Variable<DateTime>(localUpdatedAt);
    if (!nullToAbsent || lastSyncedAt != null) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt);
    }
    if (!nullToAbsent || syncError != null) {
      map['sync_error'] = Variable<String>(syncError);
    }
    map['deleted'] = Variable<bool>(deleted);
    map['id'] = Variable<String>(id);
    map['service_order_id'] = Variable<String>(serviceOrderId);
    map['description'] = Variable<String>(description);
    map['part_number'] = Variable<String>(partNumber);
    map['quantity'] = Variable<String>(quantity);
    map['unit'] = Variable<String>(unit);
    if (!nullToAbsent || unitCost != null) {
      map['unit_cost'] = Variable<String>(unitCost);
    }
    if (!nullToAbsent || unitPrice != null) {
      map['unit_price'] = Variable<String>(unitPrice);
    }
    map['notes'] = Variable<String>(notes);
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<DateTime>(createdAt);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    return map;
  }

  LocalServiceOrderPartsCompanion toCompanion(bool nullToAbsent) {
    return LocalServiceOrderPartsCompanion(
      organizationId: Value(organizationId),
      version: version == null && nullToAbsent
          ? const Value.absent()
          : Value(version),
      syncStatus: Value(syncStatus),
      localUpdatedAt: Value(localUpdatedAt),
      lastSyncedAt: lastSyncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncedAt),
      syncError: syncError == null && nullToAbsent
          ? const Value.absent()
          : Value(syncError),
      deleted: Value(deleted),
      id: Value(id),
      serviceOrderId: Value(serviceOrderId),
      description: Value(description),
      partNumber: Value(partNumber),
      quantity: Value(quantity),
      unit: Value(unit),
      unitCost: unitCost == null && nullToAbsent
          ? const Value.absent()
          : Value(unitCost),
      unitPrice: unitPrice == null && nullToAbsent
          ? const Value.absent()
          : Value(unitPrice),
      notes: Value(notes),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory LocalServiceOrderPart.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalServiceOrderPart(
      organizationId: serializer.fromJson<String>(json['organizationId']),
      version: serializer.fromJson<int?>(json['version']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      localUpdatedAt: serializer.fromJson<DateTime>(json['localUpdatedAt']),
      lastSyncedAt: serializer.fromJson<DateTime?>(json['lastSyncedAt']),
      syncError: serializer.fromJson<String?>(json['syncError']),
      deleted: serializer.fromJson<bool>(json['deleted']),
      id: serializer.fromJson<String>(json['id']),
      serviceOrderId: serializer.fromJson<String>(json['serviceOrderId']),
      description: serializer.fromJson<String>(json['description']),
      partNumber: serializer.fromJson<String>(json['partNumber']),
      quantity: serializer.fromJson<String>(json['quantity']),
      unit: serializer.fromJson<String>(json['unit']),
      unitCost: serializer.fromJson<String?>(json['unitCost']),
      unitPrice: serializer.fromJson<String?>(json['unitPrice']),
      notes: serializer.fromJson<String>(json['notes']),
      createdAt: serializer.fromJson<DateTime?>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'organizationId': serializer.toJson<String>(organizationId),
      'version': serializer.toJson<int?>(version),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'localUpdatedAt': serializer.toJson<DateTime>(localUpdatedAt),
      'lastSyncedAt': serializer.toJson<DateTime?>(lastSyncedAt),
      'syncError': serializer.toJson<String?>(syncError),
      'deleted': serializer.toJson<bool>(deleted),
      'id': serializer.toJson<String>(id),
      'serviceOrderId': serializer.toJson<String>(serviceOrderId),
      'description': serializer.toJson<String>(description),
      'partNumber': serializer.toJson<String>(partNumber),
      'quantity': serializer.toJson<String>(quantity),
      'unit': serializer.toJson<String>(unit),
      'unitCost': serializer.toJson<String?>(unitCost),
      'unitPrice': serializer.toJson<String?>(unitPrice),
      'notes': serializer.toJson<String>(notes),
      'createdAt': serializer.toJson<DateTime?>(createdAt),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
    };
  }

  LocalServiceOrderPart copyWith({
    String? organizationId,
    Value<int?> version = const Value.absent(),
    String? syncStatus,
    DateTime? localUpdatedAt,
    Value<DateTime?> lastSyncedAt = const Value.absent(),
    Value<String?> syncError = const Value.absent(),
    bool? deleted,
    String? id,
    String? serviceOrderId,
    String? description,
    String? partNumber,
    String? quantity,
    String? unit,
    Value<String?> unitCost = const Value.absent(),
    Value<String?> unitPrice = const Value.absent(),
    String? notes,
    Value<DateTime?> createdAt = const Value.absent(),
    Value<DateTime?> updatedAt = const Value.absent(),
  }) => LocalServiceOrderPart(
    organizationId: organizationId ?? this.organizationId,
    version: version.present ? version.value : this.version,
    syncStatus: syncStatus ?? this.syncStatus,
    localUpdatedAt: localUpdatedAt ?? this.localUpdatedAt,
    lastSyncedAt: lastSyncedAt.present ? lastSyncedAt.value : this.lastSyncedAt,
    syncError: syncError.present ? syncError.value : this.syncError,
    deleted: deleted ?? this.deleted,
    id: id ?? this.id,
    serviceOrderId: serviceOrderId ?? this.serviceOrderId,
    description: description ?? this.description,
    partNumber: partNumber ?? this.partNumber,
    quantity: quantity ?? this.quantity,
    unit: unit ?? this.unit,
    unitCost: unitCost.present ? unitCost.value : this.unitCost,
    unitPrice: unitPrice.present ? unitPrice.value : this.unitPrice,
    notes: notes ?? this.notes,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
  );
  LocalServiceOrderPart copyWithCompanion(
    LocalServiceOrderPartsCompanion data,
  ) {
    return LocalServiceOrderPart(
      organizationId: data.organizationId.present
          ? data.organizationId.value
          : this.organizationId,
      version: data.version.present ? data.version.value : this.version,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      localUpdatedAt: data.localUpdatedAt.present
          ? data.localUpdatedAt.value
          : this.localUpdatedAt,
      lastSyncedAt: data.lastSyncedAt.present
          ? data.lastSyncedAt.value
          : this.lastSyncedAt,
      syncError: data.syncError.present ? data.syncError.value : this.syncError,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
      id: data.id.present ? data.id.value : this.id,
      serviceOrderId: data.serviceOrderId.present
          ? data.serviceOrderId.value
          : this.serviceOrderId,
      description: data.description.present
          ? data.description.value
          : this.description,
      partNumber: data.partNumber.present
          ? data.partNumber.value
          : this.partNumber,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      unit: data.unit.present ? data.unit.value : this.unit,
      unitCost: data.unitCost.present ? data.unitCost.value : this.unitCost,
      unitPrice: data.unitPrice.present ? data.unitPrice.value : this.unitPrice,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalServiceOrderPart(')
          ..write('organizationId: $organizationId, ')
          ..write('version: $version, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('localUpdatedAt: $localUpdatedAt, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('syncError: $syncError, ')
          ..write('deleted: $deleted, ')
          ..write('id: $id, ')
          ..write('serviceOrderId: $serviceOrderId, ')
          ..write('description: $description, ')
          ..write('partNumber: $partNumber, ')
          ..write('quantity: $quantity, ')
          ..write('unit: $unit, ')
          ..write('unitCost: $unitCost, ')
          ..write('unitPrice: $unitPrice, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    organizationId,
    version,
    syncStatus,
    localUpdatedAt,
    lastSyncedAt,
    syncError,
    deleted,
    id,
    serviceOrderId,
    description,
    partNumber,
    quantity,
    unit,
    unitCost,
    unitPrice,
    notes,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalServiceOrderPart &&
          other.organizationId == this.organizationId &&
          other.version == this.version &&
          other.syncStatus == this.syncStatus &&
          other.localUpdatedAt == this.localUpdatedAt &&
          other.lastSyncedAt == this.lastSyncedAt &&
          other.syncError == this.syncError &&
          other.deleted == this.deleted &&
          other.id == this.id &&
          other.serviceOrderId == this.serviceOrderId &&
          other.description == this.description &&
          other.partNumber == this.partNumber &&
          other.quantity == this.quantity &&
          other.unit == this.unit &&
          other.unitCost == this.unitCost &&
          other.unitPrice == this.unitPrice &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class LocalServiceOrderPartsCompanion
    extends UpdateCompanion<LocalServiceOrderPart> {
  final Value<String> organizationId;
  final Value<int?> version;
  final Value<String> syncStatus;
  final Value<DateTime> localUpdatedAt;
  final Value<DateTime?> lastSyncedAt;
  final Value<String?> syncError;
  final Value<bool> deleted;
  final Value<String> id;
  final Value<String> serviceOrderId;
  final Value<String> description;
  final Value<String> partNumber;
  final Value<String> quantity;
  final Value<String> unit;
  final Value<String?> unitCost;
  final Value<String?> unitPrice;
  final Value<String> notes;
  final Value<DateTime?> createdAt;
  final Value<DateTime?> updatedAt;
  final Value<int> rowid;
  const LocalServiceOrderPartsCompanion({
    this.organizationId = const Value.absent(),
    this.version = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.localUpdatedAt = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.syncError = const Value.absent(),
    this.deleted = const Value.absent(),
    this.id = const Value.absent(),
    this.serviceOrderId = const Value.absent(),
    this.description = const Value.absent(),
    this.partNumber = const Value.absent(),
    this.quantity = const Value.absent(),
    this.unit = const Value.absent(),
    this.unitCost = const Value.absent(),
    this.unitPrice = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalServiceOrderPartsCompanion.insert({
    required String organizationId,
    this.version = const Value.absent(),
    this.syncStatus = const Value.absent(),
    required DateTime localUpdatedAt,
    this.lastSyncedAt = const Value.absent(),
    this.syncError = const Value.absent(),
    this.deleted = const Value.absent(),
    required String id,
    required String serviceOrderId,
    this.description = const Value.absent(),
    this.partNumber = const Value.absent(),
    this.quantity = const Value.absent(),
    this.unit = const Value.absent(),
    this.unitCost = const Value.absent(),
    this.unitPrice = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : organizationId = Value(organizationId),
       localUpdatedAt = Value(localUpdatedAt),
       id = Value(id),
       serviceOrderId = Value(serviceOrderId);
  static Insertable<LocalServiceOrderPart> custom({
    Expression<String>? organizationId,
    Expression<int>? version,
    Expression<String>? syncStatus,
    Expression<DateTime>? localUpdatedAt,
    Expression<DateTime>? lastSyncedAt,
    Expression<String>? syncError,
    Expression<bool>? deleted,
    Expression<String>? id,
    Expression<String>? serviceOrderId,
    Expression<String>? description,
    Expression<String>? partNumber,
    Expression<String>? quantity,
    Expression<String>? unit,
    Expression<String>? unitCost,
    Expression<String>? unitPrice,
    Expression<String>? notes,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (organizationId != null) 'organization_id': organizationId,
      if (version != null) 'version': version,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (localUpdatedAt != null) 'local_updated_at': localUpdatedAt,
      if (lastSyncedAt != null) 'last_synced_at': lastSyncedAt,
      if (syncError != null) 'sync_error': syncError,
      if (deleted != null) 'deleted': deleted,
      if (id != null) 'id': id,
      if (serviceOrderId != null) 'service_order_id': serviceOrderId,
      if (description != null) 'description': description,
      if (partNumber != null) 'part_number': partNumber,
      if (quantity != null) 'quantity': quantity,
      if (unit != null) 'unit': unit,
      if (unitCost != null) 'unit_cost': unitCost,
      if (unitPrice != null) 'unit_price': unitPrice,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalServiceOrderPartsCompanion copyWith({
    Value<String>? organizationId,
    Value<int?>? version,
    Value<String>? syncStatus,
    Value<DateTime>? localUpdatedAt,
    Value<DateTime?>? lastSyncedAt,
    Value<String?>? syncError,
    Value<bool>? deleted,
    Value<String>? id,
    Value<String>? serviceOrderId,
    Value<String>? description,
    Value<String>? partNumber,
    Value<String>? quantity,
    Value<String>? unit,
    Value<String?>? unitCost,
    Value<String?>? unitPrice,
    Value<String>? notes,
    Value<DateTime?>? createdAt,
    Value<DateTime?>? updatedAt,
    Value<int>? rowid,
  }) {
    return LocalServiceOrderPartsCompanion(
      organizationId: organizationId ?? this.organizationId,
      version: version ?? this.version,
      syncStatus: syncStatus ?? this.syncStatus,
      localUpdatedAt: localUpdatedAt ?? this.localUpdatedAt,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      syncError: syncError ?? this.syncError,
      deleted: deleted ?? this.deleted,
      id: id ?? this.id,
      serviceOrderId: serviceOrderId ?? this.serviceOrderId,
      description: description ?? this.description,
      partNumber: partNumber ?? this.partNumber,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      unitCost: unitCost ?? this.unitCost,
      unitPrice: unitPrice ?? this.unitPrice,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (organizationId.present) {
      map['organization_id'] = Variable<String>(organizationId.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (localUpdatedAt.present) {
      map['local_updated_at'] = Variable<DateTime>(localUpdatedAt.value);
    }
    if (lastSyncedAt.present) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt.value);
    }
    if (syncError.present) {
      map['sync_error'] = Variable<String>(syncError.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (serviceOrderId.present) {
      map['service_order_id'] = Variable<String>(serviceOrderId.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (partNumber.present) {
      map['part_number'] = Variable<String>(partNumber.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<String>(quantity.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (unitCost.present) {
      map['unit_cost'] = Variable<String>(unitCost.value);
    }
    if (unitPrice.present) {
      map['unit_price'] = Variable<String>(unitPrice.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalServiceOrderPartsCompanion(')
          ..write('organizationId: $organizationId, ')
          ..write('version: $version, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('localUpdatedAt: $localUpdatedAt, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('syncError: $syncError, ')
          ..write('deleted: $deleted, ')
          ..write('id: $id, ')
          ..write('serviceOrderId: $serviceOrderId, ')
          ..write('description: $description, ')
          ..write('partNumber: $partNumber, ')
          ..write('quantity: $quantity, ')
          ..write('unit: $unit, ')
          ..write('unitCost: $unitCost, ')
          ..write('unitPrice: $unitPrice, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalEquipmentTypesTable extends LocalEquipmentTypes
    with TableInfo<$LocalEquipmentTypesTable, LocalEquipmentType> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalEquipmentTypesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _organizationIdMeta = const VerificationMeta(
    'organizationId',
  );
  @override
  late final GeneratedColumn<String> organizationId = GeneratedColumn<String>(
    'organization_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    organizationId,
    name,
    description,
    version,
    cachedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_equipment_types';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalEquipmentType> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('organization_id')) {
      context.handle(
        _organizationIdMeta,
        organizationId.isAcceptableOrUnknown(
          data['organization_id']!,
          _organizationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_organizationIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalEquipmentType map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalEquipmentType(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      organizationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}organization_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      ),
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $LocalEquipmentTypesTable createAlias(String alias) {
    return $LocalEquipmentTypesTable(attachedDatabase, alias);
  }
}

class LocalEquipmentType extends DataClass
    implements Insertable<LocalEquipmentType> {
  final String id;
  final String organizationId;
  final String name;
  final String description;
  final int? version;
  final DateTime cachedAt;
  const LocalEquipmentType({
    required this.id,
    required this.organizationId,
    required this.name,
    required this.description,
    this.version,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['organization_id'] = Variable<String>(organizationId);
    map['name'] = Variable<String>(name);
    map['description'] = Variable<String>(description);
    if (!nullToAbsent || version != null) {
      map['version'] = Variable<int>(version);
    }
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  LocalEquipmentTypesCompanion toCompanion(bool nullToAbsent) {
    return LocalEquipmentTypesCompanion(
      id: Value(id),
      organizationId: Value(organizationId),
      name: Value(name),
      description: Value(description),
      version: version == null && nullToAbsent
          ? const Value.absent()
          : Value(version),
      cachedAt: Value(cachedAt),
    );
  }

  factory LocalEquipmentType.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalEquipmentType(
      id: serializer.fromJson<String>(json['id']),
      organizationId: serializer.fromJson<String>(json['organizationId']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String>(json['description']),
      version: serializer.fromJson<int?>(json['version']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'organizationId': serializer.toJson<String>(organizationId),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String>(description),
      'version': serializer.toJson<int?>(version),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  LocalEquipmentType copyWith({
    String? id,
    String? organizationId,
    String? name,
    String? description,
    Value<int?> version = const Value.absent(),
    DateTime? cachedAt,
  }) => LocalEquipmentType(
    id: id ?? this.id,
    organizationId: organizationId ?? this.organizationId,
    name: name ?? this.name,
    description: description ?? this.description,
    version: version.present ? version.value : this.version,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  LocalEquipmentType copyWithCompanion(LocalEquipmentTypesCompanion data) {
    return LocalEquipmentType(
      id: data.id.present ? data.id.value : this.id,
      organizationId: data.organizationId.present
          ? data.organizationId.value
          : this.organizationId,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      version: data.version.present ? data.version.value : this.version,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalEquipmentType(')
          ..write('id: $id, ')
          ..write('organizationId: $organizationId, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('version: $version, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, organizationId, name, description, version, cachedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalEquipmentType &&
          other.id == this.id &&
          other.organizationId == this.organizationId &&
          other.name == this.name &&
          other.description == this.description &&
          other.version == this.version &&
          other.cachedAt == this.cachedAt);
}

class LocalEquipmentTypesCompanion extends UpdateCompanion<LocalEquipmentType> {
  final Value<String> id;
  final Value<String> organizationId;
  final Value<String> name;
  final Value<String> description;
  final Value<int?> version;
  final Value<DateTime> cachedAt;
  final Value<int> rowid;
  const LocalEquipmentTypesCompanion({
    this.id = const Value.absent(),
    this.organizationId = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.version = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalEquipmentTypesCompanion.insert({
    required String id,
    required String organizationId,
    required String name,
    this.description = const Value.absent(),
    this.version = const Value.absent(),
    required DateTime cachedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       organizationId = Value(organizationId),
       name = Value(name),
       cachedAt = Value(cachedAt);
  static Insertable<LocalEquipmentType> custom({
    Expression<String>? id,
    Expression<String>? organizationId,
    Expression<String>? name,
    Expression<String>? description,
    Expression<int>? version,
    Expression<DateTime>? cachedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (organizationId != null) 'organization_id': organizationId,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (version != null) 'version': version,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalEquipmentTypesCompanion copyWith({
    Value<String>? id,
    Value<String>? organizationId,
    Value<String>? name,
    Value<String>? description,
    Value<int?>? version,
    Value<DateTime>? cachedAt,
    Value<int>? rowid,
  }) {
    return LocalEquipmentTypesCompanion(
      id: id ?? this.id,
      organizationId: organizationId ?? this.organizationId,
      name: name ?? this.name,
      description: description ?? this.description,
      version: version ?? this.version,
      cachedAt: cachedAt ?? this.cachedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (organizationId.present) {
      map['organization_id'] = Variable<String>(organizationId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalEquipmentTypesCompanion(')
          ..write('id: $id, ')
          ..write('organizationId: $organizationId, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('version: $version, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalReferenceDataTable extends LocalReferenceData
    with TableInfo<$LocalReferenceDataTable, LocalReferenceDataData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalReferenceDataTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _organizationIdMeta = const VerificationMeta(
    'organizationId',
  );
  @override
  late final GeneratedColumn<String> organizationId = GeneratedColumn<String>(
    'organization_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _subtitleMeta = const VerificationMeta(
    'subtitle',
  );
  @override
  late final GeneratedColumn<String> subtitle = GeneratedColumn<String>(
    'subtitle',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    kind,
    id,
    organizationId,
    label,
    subtitle,
    cachedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_reference_data';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalReferenceDataData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('organization_id')) {
      context.handle(
        _organizationIdMeta,
        organizationId.isAcceptableOrUnknown(
          data['organization_id']!,
          _organizationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_organizationIdMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    if (data.containsKey('subtitle')) {
      context.handle(
        _subtitleMeta,
        subtitle.isAcceptableOrUnknown(data['subtitle']!, _subtitleMeta),
      );
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {kind, id};
  @override
  LocalReferenceDataData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalReferenceDataData(
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      organizationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}organization_id'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      )!,
      subtitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subtitle'],
      )!,
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $LocalReferenceDataTable createAlias(String alias) {
    return $LocalReferenceDataTable(attachedDatabase, alias);
  }
}

class LocalReferenceDataData extends DataClass
    implements Insertable<LocalReferenceDataData> {
  final String kind;
  final String id;
  final String organizationId;
  final String label;
  final String subtitle;
  final DateTime cachedAt;
  const LocalReferenceDataData({
    required this.kind,
    required this.id,
    required this.organizationId,
    required this.label,
    required this.subtitle,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['kind'] = Variable<String>(kind);
    map['id'] = Variable<String>(id);
    map['organization_id'] = Variable<String>(organizationId);
    map['label'] = Variable<String>(label);
    map['subtitle'] = Variable<String>(subtitle);
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  LocalReferenceDataCompanion toCompanion(bool nullToAbsent) {
    return LocalReferenceDataCompanion(
      kind: Value(kind),
      id: Value(id),
      organizationId: Value(organizationId),
      label: Value(label),
      subtitle: Value(subtitle),
      cachedAt: Value(cachedAt),
    );
  }

  factory LocalReferenceDataData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalReferenceDataData(
      kind: serializer.fromJson<String>(json['kind']),
      id: serializer.fromJson<String>(json['id']),
      organizationId: serializer.fromJson<String>(json['organizationId']),
      label: serializer.fromJson<String>(json['label']),
      subtitle: serializer.fromJson<String>(json['subtitle']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'kind': serializer.toJson<String>(kind),
      'id': serializer.toJson<String>(id),
      'organizationId': serializer.toJson<String>(organizationId),
      'label': serializer.toJson<String>(label),
      'subtitle': serializer.toJson<String>(subtitle),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  LocalReferenceDataData copyWith({
    String? kind,
    String? id,
    String? organizationId,
    String? label,
    String? subtitle,
    DateTime? cachedAt,
  }) => LocalReferenceDataData(
    kind: kind ?? this.kind,
    id: id ?? this.id,
    organizationId: organizationId ?? this.organizationId,
    label: label ?? this.label,
    subtitle: subtitle ?? this.subtitle,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  LocalReferenceDataData copyWithCompanion(LocalReferenceDataCompanion data) {
    return LocalReferenceDataData(
      kind: data.kind.present ? data.kind.value : this.kind,
      id: data.id.present ? data.id.value : this.id,
      organizationId: data.organizationId.present
          ? data.organizationId.value
          : this.organizationId,
      label: data.label.present ? data.label.value : this.label,
      subtitle: data.subtitle.present ? data.subtitle.value : this.subtitle,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalReferenceDataData(')
          ..write('kind: $kind, ')
          ..write('id: $id, ')
          ..write('organizationId: $organizationId, ')
          ..write('label: $label, ')
          ..write('subtitle: $subtitle, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(kind, id, organizationId, label, subtitle, cachedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalReferenceDataData &&
          other.kind == this.kind &&
          other.id == this.id &&
          other.organizationId == this.organizationId &&
          other.label == this.label &&
          other.subtitle == this.subtitle &&
          other.cachedAt == this.cachedAt);
}

class LocalReferenceDataCompanion
    extends UpdateCompanion<LocalReferenceDataData> {
  final Value<String> kind;
  final Value<String> id;
  final Value<String> organizationId;
  final Value<String> label;
  final Value<String> subtitle;
  final Value<DateTime> cachedAt;
  final Value<int> rowid;
  const LocalReferenceDataCompanion({
    this.kind = const Value.absent(),
    this.id = const Value.absent(),
    this.organizationId = const Value.absent(),
    this.label = const Value.absent(),
    this.subtitle = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalReferenceDataCompanion.insert({
    required String kind,
    required String id,
    required String organizationId,
    required String label,
    this.subtitle = const Value.absent(),
    required DateTime cachedAt,
    this.rowid = const Value.absent(),
  }) : kind = Value(kind),
       id = Value(id),
       organizationId = Value(organizationId),
       label = Value(label),
       cachedAt = Value(cachedAt);
  static Insertable<LocalReferenceDataData> custom({
    Expression<String>? kind,
    Expression<String>? id,
    Expression<String>? organizationId,
    Expression<String>? label,
    Expression<String>? subtitle,
    Expression<DateTime>? cachedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (kind != null) 'kind': kind,
      if (id != null) 'id': id,
      if (organizationId != null) 'organization_id': organizationId,
      if (label != null) 'label': label,
      if (subtitle != null) 'subtitle': subtitle,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalReferenceDataCompanion copyWith({
    Value<String>? kind,
    Value<String>? id,
    Value<String>? organizationId,
    Value<String>? label,
    Value<String>? subtitle,
    Value<DateTime>? cachedAt,
    Value<int>? rowid,
  }) {
    return LocalReferenceDataCompanion(
      kind: kind ?? this.kind,
      id: id ?? this.id,
      organizationId: organizationId ?? this.organizationId,
      label: label ?? this.label,
      subtitle: subtitle ?? this.subtitle,
      cachedAt: cachedAt ?? this.cachedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (organizationId.present) {
      map['organization_id'] = Variable<String>(organizationId.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (subtitle.present) {
      map['subtitle'] = Variable<String>(subtitle.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalReferenceDataCompanion(')
          ..write('kind: $kind, ')
          ..write('id: $id, ')
          ..write('organizationId: $organizationId, ')
          ..write('label: $label, ')
          ..write('subtitle: $subtitle, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalQrCodesTable extends LocalQrCodes
    with TableInfo<$LocalQrCodesTable, LocalQrCode> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalQrCodesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _organizationIdMeta = const VerificationMeta(
    'organizationId',
  );
  @override
  late final GeneratedColumn<String> organizationId = GeneratedColumn<String>(
    'organization_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('synced'),
  );
  static const VerificationMeta _localUpdatedAtMeta = const VerificationMeta(
    'localUpdatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> localUpdatedAt =
      GeneratedColumn<DateTime>(
        'local_updated_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _lastSyncedAtMeta = const VerificationMeta(
    'lastSyncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSyncedAt = GeneratedColumn<DateTime>(
    'last_synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncErrorMeta = const VerificationMeta(
    'syncError',
  );
  @override
  late final GeneratedColumn<String> syncError = GeneratedColumn<String>(
    'sync_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deletedMeta = const VerificationMeta(
    'deleted',
  );
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
    'deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _publicCodeMeta = const VerificationMeta(
    'publicCode',
  );
  @override
  late final GeneratedColumn<String> publicCode = GeneratedColumn<String>(
    'public_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _batchIdMeta = const VerificationMeta(
    'batchId',
  );
  @override
  late final GeneratedColumn<String> batchId = GeneratedColumn<String>(
    'batch_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _clientIdMeta = const VerificationMeta(
    'clientId',
  );
  @override
  late final GeneratedColumn<String> clientId = GeneratedColumn<String>(
    'client_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _locationIdMeta = const VerificationMeta(
    'locationId',
  );
  @override
  late final GeneratedColumn<String> locationId = GeneratedColumn<String>(
    'location_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _equipmentIdMeta = const VerificationMeta(
    'equipmentId',
  );
  @override
  late final GeneratedColumn<String> equipmentId = GeneratedColumn<String>(
    'equipment_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _assignedAtMeta = const VerificationMeta(
    'assignedAt',
  );
  @override
  late final GeneratedColumn<DateTime> assignedAt = GeneratedColumn<DateTime>(
    'assigned_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    organizationId,
    version,
    syncStatus,
    localUpdatedAt,
    lastSyncedAt,
    syncError,
    deleted,
    id,
    publicCode,
    status,
    batchId,
    clientId,
    locationId,
    equipmentId,
    assignedAt,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_qr_codes';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalQrCode> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('organization_id')) {
      context.handle(
        _organizationIdMeta,
        organizationId.isAcceptableOrUnknown(
          data['organization_id']!,
          _organizationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_organizationIdMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('local_updated_at')) {
      context.handle(
        _localUpdatedAtMeta,
        localUpdatedAt.isAcceptableOrUnknown(
          data['local_updated_at']!,
          _localUpdatedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_localUpdatedAtMeta);
    }
    if (data.containsKey('last_synced_at')) {
      context.handle(
        _lastSyncedAtMeta,
        lastSyncedAt.isAcceptableOrUnknown(
          data['last_synced_at']!,
          _lastSyncedAtMeta,
        ),
      );
    }
    if (data.containsKey('sync_error')) {
      context.handle(
        _syncErrorMeta,
        syncError.isAcceptableOrUnknown(data['sync_error']!, _syncErrorMeta),
      );
    }
    if (data.containsKey('deleted')) {
      context.handle(
        _deletedMeta,
        deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta),
      );
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('public_code')) {
      context.handle(
        _publicCodeMeta,
        publicCode.isAcceptableOrUnknown(data['public_code']!, _publicCodeMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('batch_id')) {
      context.handle(
        _batchIdMeta,
        batchId.isAcceptableOrUnknown(data['batch_id']!, _batchIdMeta),
      );
    }
    if (data.containsKey('client_id')) {
      context.handle(
        _clientIdMeta,
        clientId.isAcceptableOrUnknown(data['client_id']!, _clientIdMeta),
      );
    }
    if (data.containsKey('location_id')) {
      context.handle(
        _locationIdMeta,
        locationId.isAcceptableOrUnknown(data['location_id']!, _locationIdMeta),
      );
    }
    if (data.containsKey('equipment_id')) {
      context.handle(
        _equipmentIdMeta,
        equipmentId.isAcceptableOrUnknown(
          data['equipment_id']!,
          _equipmentIdMeta,
        ),
      );
    }
    if (data.containsKey('assigned_at')) {
      context.handle(
        _assignedAtMeta,
        assignedAt.isAcceptableOrUnknown(data['assigned_at']!, _assignedAtMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalQrCode map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalQrCode(
      organizationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}organization_id'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      ),
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
      localUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}local_updated_at'],
      )!,
      lastSyncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_synced_at'],
      ),
      syncError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_error'],
      ),
      deleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}deleted'],
      )!,
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      publicCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}public_code'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      batchId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}batch_id'],
      ),
      clientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_id'],
      ),
      locationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}location_id'],
      ),
      equipmentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}equipment_id'],
      ),
      assignedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}assigned_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      ),
    );
  }

  @override
  $LocalQrCodesTable createAlias(String alias) {
    return $LocalQrCodesTable(attachedDatabase, alias);
  }
}

class LocalQrCode extends DataClass implements Insertable<LocalQrCode> {
  final String organizationId;
  final int? version;
  final String syncStatus;
  final DateTime localUpdatedAt;
  final DateTime? lastSyncedAt;
  final String? syncError;
  final bool deleted;
  final String id;
  final String? publicCode;
  final String status;
  final String? batchId;
  final String? clientId;
  final String? locationId;
  final String? equipmentId;
  final DateTime? assignedAt;
  final DateTime? createdAt;
  const LocalQrCode({
    required this.organizationId,
    this.version,
    required this.syncStatus,
    required this.localUpdatedAt,
    this.lastSyncedAt,
    this.syncError,
    required this.deleted,
    required this.id,
    this.publicCode,
    required this.status,
    this.batchId,
    this.clientId,
    this.locationId,
    this.equipmentId,
    this.assignedAt,
    this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['organization_id'] = Variable<String>(organizationId);
    if (!nullToAbsent || version != null) {
      map['version'] = Variable<int>(version);
    }
    map['sync_status'] = Variable<String>(syncStatus);
    map['local_updated_at'] = Variable<DateTime>(localUpdatedAt);
    if (!nullToAbsent || lastSyncedAt != null) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt);
    }
    if (!nullToAbsent || syncError != null) {
      map['sync_error'] = Variable<String>(syncError);
    }
    map['deleted'] = Variable<bool>(deleted);
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || publicCode != null) {
      map['public_code'] = Variable<String>(publicCode);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || batchId != null) {
      map['batch_id'] = Variable<String>(batchId);
    }
    if (!nullToAbsent || clientId != null) {
      map['client_id'] = Variable<String>(clientId);
    }
    if (!nullToAbsent || locationId != null) {
      map['location_id'] = Variable<String>(locationId);
    }
    if (!nullToAbsent || equipmentId != null) {
      map['equipment_id'] = Variable<String>(equipmentId);
    }
    if (!nullToAbsent || assignedAt != null) {
      map['assigned_at'] = Variable<DateTime>(assignedAt);
    }
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<DateTime>(createdAt);
    }
    return map;
  }

  LocalQrCodesCompanion toCompanion(bool nullToAbsent) {
    return LocalQrCodesCompanion(
      organizationId: Value(organizationId),
      version: version == null && nullToAbsent
          ? const Value.absent()
          : Value(version),
      syncStatus: Value(syncStatus),
      localUpdatedAt: Value(localUpdatedAt),
      lastSyncedAt: lastSyncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncedAt),
      syncError: syncError == null && nullToAbsent
          ? const Value.absent()
          : Value(syncError),
      deleted: Value(deleted),
      id: Value(id),
      publicCode: publicCode == null && nullToAbsent
          ? const Value.absent()
          : Value(publicCode),
      status: Value(status),
      batchId: batchId == null && nullToAbsent
          ? const Value.absent()
          : Value(batchId),
      clientId: clientId == null && nullToAbsent
          ? const Value.absent()
          : Value(clientId),
      locationId: locationId == null && nullToAbsent
          ? const Value.absent()
          : Value(locationId),
      equipmentId: equipmentId == null && nullToAbsent
          ? const Value.absent()
          : Value(equipmentId),
      assignedAt: assignedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(assignedAt),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
    );
  }

  factory LocalQrCode.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalQrCode(
      organizationId: serializer.fromJson<String>(json['organizationId']),
      version: serializer.fromJson<int?>(json['version']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      localUpdatedAt: serializer.fromJson<DateTime>(json['localUpdatedAt']),
      lastSyncedAt: serializer.fromJson<DateTime?>(json['lastSyncedAt']),
      syncError: serializer.fromJson<String?>(json['syncError']),
      deleted: serializer.fromJson<bool>(json['deleted']),
      id: serializer.fromJson<String>(json['id']),
      publicCode: serializer.fromJson<String?>(json['publicCode']),
      status: serializer.fromJson<String>(json['status']),
      batchId: serializer.fromJson<String?>(json['batchId']),
      clientId: serializer.fromJson<String?>(json['clientId']),
      locationId: serializer.fromJson<String?>(json['locationId']),
      equipmentId: serializer.fromJson<String?>(json['equipmentId']),
      assignedAt: serializer.fromJson<DateTime?>(json['assignedAt']),
      createdAt: serializer.fromJson<DateTime?>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'organizationId': serializer.toJson<String>(organizationId),
      'version': serializer.toJson<int?>(version),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'localUpdatedAt': serializer.toJson<DateTime>(localUpdatedAt),
      'lastSyncedAt': serializer.toJson<DateTime?>(lastSyncedAt),
      'syncError': serializer.toJson<String?>(syncError),
      'deleted': serializer.toJson<bool>(deleted),
      'id': serializer.toJson<String>(id),
      'publicCode': serializer.toJson<String?>(publicCode),
      'status': serializer.toJson<String>(status),
      'batchId': serializer.toJson<String?>(batchId),
      'clientId': serializer.toJson<String?>(clientId),
      'locationId': serializer.toJson<String?>(locationId),
      'equipmentId': serializer.toJson<String?>(equipmentId),
      'assignedAt': serializer.toJson<DateTime?>(assignedAt),
      'createdAt': serializer.toJson<DateTime?>(createdAt),
    };
  }

  LocalQrCode copyWith({
    String? organizationId,
    Value<int?> version = const Value.absent(),
    String? syncStatus,
    DateTime? localUpdatedAt,
    Value<DateTime?> lastSyncedAt = const Value.absent(),
    Value<String?> syncError = const Value.absent(),
    bool? deleted,
    String? id,
    Value<String?> publicCode = const Value.absent(),
    String? status,
    Value<String?> batchId = const Value.absent(),
    Value<String?> clientId = const Value.absent(),
    Value<String?> locationId = const Value.absent(),
    Value<String?> equipmentId = const Value.absent(),
    Value<DateTime?> assignedAt = const Value.absent(),
    Value<DateTime?> createdAt = const Value.absent(),
  }) => LocalQrCode(
    organizationId: organizationId ?? this.organizationId,
    version: version.present ? version.value : this.version,
    syncStatus: syncStatus ?? this.syncStatus,
    localUpdatedAt: localUpdatedAt ?? this.localUpdatedAt,
    lastSyncedAt: lastSyncedAt.present ? lastSyncedAt.value : this.lastSyncedAt,
    syncError: syncError.present ? syncError.value : this.syncError,
    deleted: deleted ?? this.deleted,
    id: id ?? this.id,
    publicCode: publicCode.present ? publicCode.value : this.publicCode,
    status: status ?? this.status,
    batchId: batchId.present ? batchId.value : this.batchId,
    clientId: clientId.present ? clientId.value : this.clientId,
    locationId: locationId.present ? locationId.value : this.locationId,
    equipmentId: equipmentId.present ? equipmentId.value : this.equipmentId,
    assignedAt: assignedAt.present ? assignedAt.value : this.assignedAt,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
  );
  LocalQrCode copyWithCompanion(LocalQrCodesCompanion data) {
    return LocalQrCode(
      organizationId: data.organizationId.present
          ? data.organizationId.value
          : this.organizationId,
      version: data.version.present ? data.version.value : this.version,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      localUpdatedAt: data.localUpdatedAt.present
          ? data.localUpdatedAt.value
          : this.localUpdatedAt,
      lastSyncedAt: data.lastSyncedAt.present
          ? data.lastSyncedAt.value
          : this.lastSyncedAt,
      syncError: data.syncError.present ? data.syncError.value : this.syncError,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
      id: data.id.present ? data.id.value : this.id,
      publicCode: data.publicCode.present
          ? data.publicCode.value
          : this.publicCode,
      status: data.status.present ? data.status.value : this.status,
      batchId: data.batchId.present ? data.batchId.value : this.batchId,
      clientId: data.clientId.present ? data.clientId.value : this.clientId,
      locationId: data.locationId.present
          ? data.locationId.value
          : this.locationId,
      equipmentId: data.equipmentId.present
          ? data.equipmentId.value
          : this.equipmentId,
      assignedAt: data.assignedAt.present
          ? data.assignedAt.value
          : this.assignedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalQrCode(')
          ..write('organizationId: $organizationId, ')
          ..write('version: $version, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('localUpdatedAt: $localUpdatedAt, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('syncError: $syncError, ')
          ..write('deleted: $deleted, ')
          ..write('id: $id, ')
          ..write('publicCode: $publicCode, ')
          ..write('status: $status, ')
          ..write('batchId: $batchId, ')
          ..write('clientId: $clientId, ')
          ..write('locationId: $locationId, ')
          ..write('equipmentId: $equipmentId, ')
          ..write('assignedAt: $assignedAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    organizationId,
    version,
    syncStatus,
    localUpdatedAt,
    lastSyncedAt,
    syncError,
    deleted,
    id,
    publicCode,
    status,
    batchId,
    clientId,
    locationId,
    equipmentId,
    assignedAt,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalQrCode &&
          other.organizationId == this.organizationId &&
          other.version == this.version &&
          other.syncStatus == this.syncStatus &&
          other.localUpdatedAt == this.localUpdatedAt &&
          other.lastSyncedAt == this.lastSyncedAt &&
          other.syncError == this.syncError &&
          other.deleted == this.deleted &&
          other.id == this.id &&
          other.publicCode == this.publicCode &&
          other.status == this.status &&
          other.batchId == this.batchId &&
          other.clientId == this.clientId &&
          other.locationId == this.locationId &&
          other.equipmentId == this.equipmentId &&
          other.assignedAt == this.assignedAt &&
          other.createdAt == this.createdAt);
}

class LocalQrCodesCompanion extends UpdateCompanion<LocalQrCode> {
  final Value<String> organizationId;
  final Value<int?> version;
  final Value<String> syncStatus;
  final Value<DateTime> localUpdatedAt;
  final Value<DateTime?> lastSyncedAt;
  final Value<String?> syncError;
  final Value<bool> deleted;
  final Value<String> id;
  final Value<String?> publicCode;
  final Value<String> status;
  final Value<String?> batchId;
  final Value<String?> clientId;
  final Value<String?> locationId;
  final Value<String?> equipmentId;
  final Value<DateTime?> assignedAt;
  final Value<DateTime?> createdAt;
  final Value<int> rowid;
  const LocalQrCodesCompanion({
    this.organizationId = const Value.absent(),
    this.version = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.localUpdatedAt = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.syncError = const Value.absent(),
    this.deleted = const Value.absent(),
    this.id = const Value.absent(),
    this.publicCode = const Value.absent(),
    this.status = const Value.absent(),
    this.batchId = const Value.absent(),
    this.clientId = const Value.absent(),
    this.locationId = const Value.absent(),
    this.equipmentId = const Value.absent(),
    this.assignedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalQrCodesCompanion.insert({
    required String organizationId,
    this.version = const Value.absent(),
    this.syncStatus = const Value.absent(),
    required DateTime localUpdatedAt,
    this.lastSyncedAt = const Value.absent(),
    this.syncError = const Value.absent(),
    this.deleted = const Value.absent(),
    required String id,
    this.publicCode = const Value.absent(),
    required String status,
    this.batchId = const Value.absent(),
    this.clientId = const Value.absent(),
    this.locationId = const Value.absent(),
    this.equipmentId = const Value.absent(),
    this.assignedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : organizationId = Value(organizationId),
       localUpdatedAt = Value(localUpdatedAt),
       id = Value(id),
       status = Value(status);
  static Insertable<LocalQrCode> custom({
    Expression<String>? organizationId,
    Expression<int>? version,
    Expression<String>? syncStatus,
    Expression<DateTime>? localUpdatedAt,
    Expression<DateTime>? lastSyncedAt,
    Expression<String>? syncError,
    Expression<bool>? deleted,
    Expression<String>? id,
    Expression<String>? publicCode,
    Expression<String>? status,
    Expression<String>? batchId,
    Expression<String>? clientId,
    Expression<String>? locationId,
    Expression<String>? equipmentId,
    Expression<DateTime>? assignedAt,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (organizationId != null) 'organization_id': organizationId,
      if (version != null) 'version': version,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (localUpdatedAt != null) 'local_updated_at': localUpdatedAt,
      if (lastSyncedAt != null) 'last_synced_at': lastSyncedAt,
      if (syncError != null) 'sync_error': syncError,
      if (deleted != null) 'deleted': deleted,
      if (id != null) 'id': id,
      if (publicCode != null) 'public_code': publicCode,
      if (status != null) 'status': status,
      if (batchId != null) 'batch_id': batchId,
      if (clientId != null) 'client_id': clientId,
      if (locationId != null) 'location_id': locationId,
      if (equipmentId != null) 'equipment_id': equipmentId,
      if (assignedAt != null) 'assigned_at': assignedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalQrCodesCompanion copyWith({
    Value<String>? organizationId,
    Value<int?>? version,
    Value<String>? syncStatus,
    Value<DateTime>? localUpdatedAt,
    Value<DateTime?>? lastSyncedAt,
    Value<String?>? syncError,
    Value<bool>? deleted,
    Value<String>? id,
    Value<String?>? publicCode,
    Value<String>? status,
    Value<String?>? batchId,
    Value<String?>? clientId,
    Value<String?>? locationId,
    Value<String?>? equipmentId,
    Value<DateTime?>? assignedAt,
    Value<DateTime?>? createdAt,
    Value<int>? rowid,
  }) {
    return LocalQrCodesCompanion(
      organizationId: organizationId ?? this.organizationId,
      version: version ?? this.version,
      syncStatus: syncStatus ?? this.syncStatus,
      localUpdatedAt: localUpdatedAt ?? this.localUpdatedAt,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      syncError: syncError ?? this.syncError,
      deleted: deleted ?? this.deleted,
      id: id ?? this.id,
      publicCode: publicCode ?? this.publicCode,
      status: status ?? this.status,
      batchId: batchId ?? this.batchId,
      clientId: clientId ?? this.clientId,
      locationId: locationId ?? this.locationId,
      equipmentId: equipmentId ?? this.equipmentId,
      assignedAt: assignedAt ?? this.assignedAt,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (organizationId.present) {
      map['organization_id'] = Variable<String>(organizationId.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (localUpdatedAt.present) {
      map['local_updated_at'] = Variable<DateTime>(localUpdatedAt.value);
    }
    if (lastSyncedAt.present) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt.value);
    }
    if (syncError.present) {
      map['sync_error'] = Variable<String>(syncError.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (publicCode.present) {
      map['public_code'] = Variable<String>(publicCode.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (batchId.present) {
      map['batch_id'] = Variable<String>(batchId.value);
    }
    if (clientId.present) {
      map['client_id'] = Variable<String>(clientId.value);
    }
    if (locationId.present) {
      map['location_id'] = Variable<String>(locationId.value);
    }
    if (equipmentId.present) {
      map['equipment_id'] = Variable<String>(equipmentId.value);
    }
    if (assignedAt.present) {
      map['assigned_at'] = Variable<DateTime>(assignedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalQrCodesCompanion(')
          ..write('organizationId: $organizationId, ')
          ..write('version: $version, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('localUpdatedAt: $localUpdatedAt, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('syncError: $syncError, ')
          ..write('deleted: $deleted, ')
          ..write('id: $id, ')
          ..write('publicCode: $publicCode, ')
          ..write('status: $status, ')
          ..write('batchId: $batchId, ')
          ..write('clientId: $clientId, ')
          ..write('locationId: $locationId, ')
          ..write('equipmentId: $equipmentId, ')
          ..write('assignedAt: $assignedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalQrBatchesTable extends LocalQrBatches
    with TableInfo<$LocalQrBatchesTable, LocalQrBatch> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalQrBatchesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _organizationIdMeta = const VerificationMeta(
    'organizationId',
  );
  @override
  late final GeneratedColumn<String> organizationId = GeneratedColumn<String>(
    'organization_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('synced'),
  );
  static const VerificationMeta _localUpdatedAtMeta = const VerificationMeta(
    'localUpdatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> localUpdatedAt =
      GeneratedColumn<DateTime>(
        'local_updated_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _lastSyncedAtMeta = const VerificationMeta(
    'lastSyncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSyncedAt = GeneratedColumn<DateTime>(
    'last_synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncErrorMeta = const VerificationMeta(
    'syncError',
  );
  @override
  late final GeneratedColumn<String> syncError = GeneratedColumn<String>(
    'sync_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deletedMeta = const VerificationMeta(
    'deleted',
  );
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
    'deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _quantityMeta = const VerificationMeta(
    'quantity',
  );
  @override
  late final GeneratedColumn<int> quantity = GeneratedColumn<int>(
    'quantity',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reservedUserIdMeta = const VerificationMeta(
    'reservedUserId',
  );
  @override
  late final GeneratedColumn<String> reservedUserId = GeneratedColumn<String>(
    'reserved_user_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reservedDeviceIdMeta = const VerificationMeta(
    'reservedDeviceId',
  );
  @override
  late final GeneratedColumn<String> reservedDeviceId = GeneratedColumn<String>(
    'reserved_device_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _exportCountMeta = const VerificationMeta(
    'exportCount',
  );
  @override
  late final GeneratedColumn<int> exportCount = GeneratedColumn<int>(
    'export_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    organizationId,
    version,
    syncStatus,
    localUpdatedAt,
    lastSyncedAt,
    syncError,
    deleted,
    id,
    label,
    quantity,
    status,
    reservedUserId,
    reservedDeviceId,
    exportCount,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_qr_batches';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalQrBatch> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('organization_id')) {
      context.handle(
        _organizationIdMeta,
        organizationId.isAcceptableOrUnknown(
          data['organization_id']!,
          _organizationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_organizationIdMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('local_updated_at')) {
      context.handle(
        _localUpdatedAtMeta,
        localUpdatedAt.isAcceptableOrUnknown(
          data['local_updated_at']!,
          _localUpdatedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_localUpdatedAtMeta);
    }
    if (data.containsKey('last_synced_at')) {
      context.handle(
        _lastSyncedAtMeta,
        lastSyncedAt.isAcceptableOrUnknown(
          data['last_synced_at']!,
          _lastSyncedAtMeta,
        ),
      );
    }
    if (data.containsKey('sync_error')) {
      context.handle(
        _syncErrorMeta,
        syncError.isAcceptableOrUnknown(data['sync_error']!, _syncErrorMeta),
      );
    }
    if (data.containsKey('deleted')) {
      context.handle(
        _deletedMeta,
        deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta),
      );
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    }
    if (data.containsKey('quantity')) {
      context.handle(
        _quantityMeta,
        quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('reserved_user_id')) {
      context.handle(
        _reservedUserIdMeta,
        reservedUserId.isAcceptableOrUnknown(
          data['reserved_user_id']!,
          _reservedUserIdMeta,
        ),
      );
    }
    if (data.containsKey('reserved_device_id')) {
      context.handle(
        _reservedDeviceIdMeta,
        reservedDeviceId.isAcceptableOrUnknown(
          data['reserved_device_id']!,
          _reservedDeviceIdMeta,
        ),
      );
    }
    if (data.containsKey('export_count')) {
      context.handle(
        _exportCountMeta,
        exportCount.isAcceptableOrUnknown(
          data['export_count']!,
          _exportCountMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalQrBatch map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalQrBatch(
      organizationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}organization_id'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      ),
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
      localUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}local_updated_at'],
      )!,
      lastSyncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_synced_at'],
      ),
      syncError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_error'],
      ),
      deleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}deleted'],
      )!,
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      )!,
      quantity: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quantity'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      reservedUserId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reserved_user_id'],
      ),
      reservedDeviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reserved_device_id'],
      ),
      exportCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}export_count'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      ),
    );
  }

  @override
  $LocalQrBatchesTable createAlias(String alias) {
    return $LocalQrBatchesTable(attachedDatabase, alias);
  }
}

class LocalQrBatch extends DataClass implements Insertable<LocalQrBatch> {
  final String organizationId;
  final int? version;
  final String syncStatus;
  final DateTime localUpdatedAt;
  final DateTime? lastSyncedAt;
  final String? syncError;
  final bool deleted;
  final String id;
  final String label;
  final int quantity;
  final String status;
  final String? reservedUserId;
  final String? reservedDeviceId;
  final int exportCount;
  final DateTime? createdAt;
  const LocalQrBatch({
    required this.organizationId,
    this.version,
    required this.syncStatus,
    required this.localUpdatedAt,
    this.lastSyncedAt,
    this.syncError,
    required this.deleted,
    required this.id,
    required this.label,
    required this.quantity,
    required this.status,
    this.reservedUserId,
    this.reservedDeviceId,
    required this.exportCount,
    this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['organization_id'] = Variable<String>(organizationId);
    if (!nullToAbsent || version != null) {
      map['version'] = Variable<int>(version);
    }
    map['sync_status'] = Variable<String>(syncStatus);
    map['local_updated_at'] = Variable<DateTime>(localUpdatedAt);
    if (!nullToAbsent || lastSyncedAt != null) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt);
    }
    if (!nullToAbsent || syncError != null) {
      map['sync_error'] = Variable<String>(syncError);
    }
    map['deleted'] = Variable<bool>(deleted);
    map['id'] = Variable<String>(id);
    map['label'] = Variable<String>(label);
    map['quantity'] = Variable<int>(quantity);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || reservedUserId != null) {
      map['reserved_user_id'] = Variable<String>(reservedUserId);
    }
    if (!nullToAbsent || reservedDeviceId != null) {
      map['reserved_device_id'] = Variable<String>(reservedDeviceId);
    }
    map['export_count'] = Variable<int>(exportCount);
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<DateTime>(createdAt);
    }
    return map;
  }

  LocalQrBatchesCompanion toCompanion(bool nullToAbsent) {
    return LocalQrBatchesCompanion(
      organizationId: Value(organizationId),
      version: version == null && nullToAbsent
          ? const Value.absent()
          : Value(version),
      syncStatus: Value(syncStatus),
      localUpdatedAt: Value(localUpdatedAt),
      lastSyncedAt: lastSyncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncedAt),
      syncError: syncError == null && nullToAbsent
          ? const Value.absent()
          : Value(syncError),
      deleted: Value(deleted),
      id: Value(id),
      label: Value(label),
      quantity: Value(quantity),
      status: Value(status),
      reservedUserId: reservedUserId == null && nullToAbsent
          ? const Value.absent()
          : Value(reservedUserId),
      reservedDeviceId: reservedDeviceId == null && nullToAbsent
          ? const Value.absent()
          : Value(reservedDeviceId),
      exportCount: Value(exportCount),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
    );
  }

  factory LocalQrBatch.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalQrBatch(
      organizationId: serializer.fromJson<String>(json['organizationId']),
      version: serializer.fromJson<int?>(json['version']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      localUpdatedAt: serializer.fromJson<DateTime>(json['localUpdatedAt']),
      lastSyncedAt: serializer.fromJson<DateTime?>(json['lastSyncedAt']),
      syncError: serializer.fromJson<String?>(json['syncError']),
      deleted: serializer.fromJson<bool>(json['deleted']),
      id: serializer.fromJson<String>(json['id']),
      label: serializer.fromJson<String>(json['label']),
      quantity: serializer.fromJson<int>(json['quantity']),
      status: serializer.fromJson<String>(json['status']),
      reservedUserId: serializer.fromJson<String?>(json['reservedUserId']),
      reservedDeviceId: serializer.fromJson<String?>(json['reservedDeviceId']),
      exportCount: serializer.fromJson<int>(json['exportCount']),
      createdAt: serializer.fromJson<DateTime?>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'organizationId': serializer.toJson<String>(organizationId),
      'version': serializer.toJson<int?>(version),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'localUpdatedAt': serializer.toJson<DateTime>(localUpdatedAt),
      'lastSyncedAt': serializer.toJson<DateTime?>(lastSyncedAt),
      'syncError': serializer.toJson<String?>(syncError),
      'deleted': serializer.toJson<bool>(deleted),
      'id': serializer.toJson<String>(id),
      'label': serializer.toJson<String>(label),
      'quantity': serializer.toJson<int>(quantity),
      'status': serializer.toJson<String>(status),
      'reservedUserId': serializer.toJson<String?>(reservedUserId),
      'reservedDeviceId': serializer.toJson<String?>(reservedDeviceId),
      'exportCount': serializer.toJson<int>(exportCount),
      'createdAt': serializer.toJson<DateTime?>(createdAt),
    };
  }

  LocalQrBatch copyWith({
    String? organizationId,
    Value<int?> version = const Value.absent(),
    String? syncStatus,
    DateTime? localUpdatedAt,
    Value<DateTime?> lastSyncedAt = const Value.absent(),
    Value<String?> syncError = const Value.absent(),
    bool? deleted,
    String? id,
    String? label,
    int? quantity,
    String? status,
    Value<String?> reservedUserId = const Value.absent(),
    Value<String?> reservedDeviceId = const Value.absent(),
    int? exportCount,
    Value<DateTime?> createdAt = const Value.absent(),
  }) => LocalQrBatch(
    organizationId: organizationId ?? this.organizationId,
    version: version.present ? version.value : this.version,
    syncStatus: syncStatus ?? this.syncStatus,
    localUpdatedAt: localUpdatedAt ?? this.localUpdatedAt,
    lastSyncedAt: lastSyncedAt.present ? lastSyncedAt.value : this.lastSyncedAt,
    syncError: syncError.present ? syncError.value : this.syncError,
    deleted: deleted ?? this.deleted,
    id: id ?? this.id,
    label: label ?? this.label,
    quantity: quantity ?? this.quantity,
    status: status ?? this.status,
    reservedUserId: reservedUserId.present
        ? reservedUserId.value
        : this.reservedUserId,
    reservedDeviceId: reservedDeviceId.present
        ? reservedDeviceId.value
        : this.reservedDeviceId,
    exportCount: exportCount ?? this.exportCount,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
  );
  LocalQrBatch copyWithCompanion(LocalQrBatchesCompanion data) {
    return LocalQrBatch(
      organizationId: data.organizationId.present
          ? data.organizationId.value
          : this.organizationId,
      version: data.version.present ? data.version.value : this.version,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      localUpdatedAt: data.localUpdatedAt.present
          ? data.localUpdatedAt.value
          : this.localUpdatedAt,
      lastSyncedAt: data.lastSyncedAt.present
          ? data.lastSyncedAt.value
          : this.lastSyncedAt,
      syncError: data.syncError.present ? data.syncError.value : this.syncError,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
      id: data.id.present ? data.id.value : this.id,
      label: data.label.present ? data.label.value : this.label,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      status: data.status.present ? data.status.value : this.status,
      reservedUserId: data.reservedUserId.present
          ? data.reservedUserId.value
          : this.reservedUserId,
      reservedDeviceId: data.reservedDeviceId.present
          ? data.reservedDeviceId.value
          : this.reservedDeviceId,
      exportCount: data.exportCount.present
          ? data.exportCount.value
          : this.exportCount,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalQrBatch(')
          ..write('organizationId: $organizationId, ')
          ..write('version: $version, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('localUpdatedAt: $localUpdatedAt, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('syncError: $syncError, ')
          ..write('deleted: $deleted, ')
          ..write('id: $id, ')
          ..write('label: $label, ')
          ..write('quantity: $quantity, ')
          ..write('status: $status, ')
          ..write('reservedUserId: $reservedUserId, ')
          ..write('reservedDeviceId: $reservedDeviceId, ')
          ..write('exportCount: $exportCount, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    organizationId,
    version,
    syncStatus,
    localUpdatedAt,
    lastSyncedAt,
    syncError,
    deleted,
    id,
    label,
    quantity,
    status,
    reservedUserId,
    reservedDeviceId,
    exportCount,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalQrBatch &&
          other.organizationId == this.organizationId &&
          other.version == this.version &&
          other.syncStatus == this.syncStatus &&
          other.localUpdatedAt == this.localUpdatedAt &&
          other.lastSyncedAt == this.lastSyncedAt &&
          other.syncError == this.syncError &&
          other.deleted == this.deleted &&
          other.id == this.id &&
          other.label == this.label &&
          other.quantity == this.quantity &&
          other.status == this.status &&
          other.reservedUserId == this.reservedUserId &&
          other.reservedDeviceId == this.reservedDeviceId &&
          other.exportCount == this.exportCount &&
          other.createdAt == this.createdAt);
}

class LocalQrBatchesCompanion extends UpdateCompanion<LocalQrBatch> {
  final Value<String> organizationId;
  final Value<int?> version;
  final Value<String> syncStatus;
  final Value<DateTime> localUpdatedAt;
  final Value<DateTime?> lastSyncedAt;
  final Value<String?> syncError;
  final Value<bool> deleted;
  final Value<String> id;
  final Value<String> label;
  final Value<int> quantity;
  final Value<String> status;
  final Value<String?> reservedUserId;
  final Value<String?> reservedDeviceId;
  final Value<int> exportCount;
  final Value<DateTime?> createdAt;
  final Value<int> rowid;
  const LocalQrBatchesCompanion({
    this.organizationId = const Value.absent(),
    this.version = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.localUpdatedAt = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.syncError = const Value.absent(),
    this.deleted = const Value.absent(),
    this.id = const Value.absent(),
    this.label = const Value.absent(),
    this.quantity = const Value.absent(),
    this.status = const Value.absent(),
    this.reservedUserId = const Value.absent(),
    this.reservedDeviceId = const Value.absent(),
    this.exportCount = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalQrBatchesCompanion.insert({
    required String organizationId,
    this.version = const Value.absent(),
    this.syncStatus = const Value.absent(),
    required DateTime localUpdatedAt,
    this.lastSyncedAt = const Value.absent(),
    this.syncError = const Value.absent(),
    this.deleted = const Value.absent(),
    required String id,
    this.label = const Value.absent(),
    this.quantity = const Value.absent(),
    required String status,
    this.reservedUserId = const Value.absent(),
    this.reservedDeviceId = const Value.absent(),
    this.exportCount = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : organizationId = Value(organizationId),
       localUpdatedAt = Value(localUpdatedAt),
       id = Value(id),
       status = Value(status);
  static Insertable<LocalQrBatch> custom({
    Expression<String>? organizationId,
    Expression<int>? version,
    Expression<String>? syncStatus,
    Expression<DateTime>? localUpdatedAt,
    Expression<DateTime>? lastSyncedAt,
    Expression<String>? syncError,
    Expression<bool>? deleted,
    Expression<String>? id,
    Expression<String>? label,
    Expression<int>? quantity,
    Expression<String>? status,
    Expression<String>? reservedUserId,
    Expression<String>? reservedDeviceId,
    Expression<int>? exportCount,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (organizationId != null) 'organization_id': organizationId,
      if (version != null) 'version': version,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (localUpdatedAt != null) 'local_updated_at': localUpdatedAt,
      if (lastSyncedAt != null) 'last_synced_at': lastSyncedAt,
      if (syncError != null) 'sync_error': syncError,
      if (deleted != null) 'deleted': deleted,
      if (id != null) 'id': id,
      if (label != null) 'label': label,
      if (quantity != null) 'quantity': quantity,
      if (status != null) 'status': status,
      if (reservedUserId != null) 'reserved_user_id': reservedUserId,
      if (reservedDeviceId != null) 'reserved_device_id': reservedDeviceId,
      if (exportCount != null) 'export_count': exportCount,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalQrBatchesCompanion copyWith({
    Value<String>? organizationId,
    Value<int?>? version,
    Value<String>? syncStatus,
    Value<DateTime>? localUpdatedAt,
    Value<DateTime?>? lastSyncedAt,
    Value<String?>? syncError,
    Value<bool>? deleted,
    Value<String>? id,
    Value<String>? label,
    Value<int>? quantity,
    Value<String>? status,
    Value<String?>? reservedUserId,
    Value<String?>? reservedDeviceId,
    Value<int>? exportCount,
    Value<DateTime?>? createdAt,
    Value<int>? rowid,
  }) {
    return LocalQrBatchesCompanion(
      organizationId: organizationId ?? this.organizationId,
      version: version ?? this.version,
      syncStatus: syncStatus ?? this.syncStatus,
      localUpdatedAt: localUpdatedAt ?? this.localUpdatedAt,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      syncError: syncError ?? this.syncError,
      deleted: deleted ?? this.deleted,
      id: id ?? this.id,
      label: label ?? this.label,
      quantity: quantity ?? this.quantity,
      status: status ?? this.status,
      reservedUserId: reservedUserId ?? this.reservedUserId,
      reservedDeviceId: reservedDeviceId ?? this.reservedDeviceId,
      exportCount: exportCount ?? this.exportCount,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (organizationId.present) {
      map['organization_id'] = Variable<String>(organizationId.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (localUpdatedAt.present) {
      map['local_updated_at'] = Variable<DateTime>(localUpdatedAt.value);
    }
    if (lastSyncedAt.present) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt.value);
    }
    if (syncError.present) {
      map['sync_error'] = Variable<String>(syncError.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<int>(quantity.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (reservedUserId.present) {
      map['reserved_user_id'] = Variable<String>(reservedUserId.value);
    }
    if (reservedDeviceId.present) {
      map['reserved_device_id'] = Variable<String>(reservedDeviceId.value);
    }
    if (exportCount.present) {
      map['export_count'] = Variable<int>(exportCount.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalQrBatchesCompanion(')
          ..write('organizationId: $organizationId, ')
          ..write('version: $version, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('localUpdatedAt: $localUpdatedAt, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('syncError: $syncError, ')
          ..write('deleted: $deleted, ')
          ..write('id: $id, ')
          ..write('label: $label, ')
          ..write('quantity: $quantity, ')
          ..write('status: $status, ')
          ..write('reservedUserId: $reservedUserId, ')
          ..write('reservedDeviceId: $reservedDeviceId, ')
          ..write('exportCount: $exportCount, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncOutboxTable extends SyncOutbox
    with TableInfo<$SyncOutboxTable, SyncOutboxData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncOutboxTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _operationIdMeta = const VerificationMeta(
    'operationId',
  );
  @override
  late final GeneratedColumn<String> operationId = GeneratedColumn<String>(
    'operation_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _organizationIdMeta = const VerificationMeta(
    'organizationId',
  );
  @override
  late final GeneratedColumn<String> organizationId = GeneratedColumn<String>(
    'organization_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityTypeMeta = const VerificationMeta(
    'entityType',
  );
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
    'entity_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
    'entity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _operationTypeMeta = const VerificationMeta(
    'operationType',
  );
  @override
  late final GeneratedColumn<String> operationType = GeneratedColumn<String>(
    'operation_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _baseVersionMeta = const VerificationMeta(
    'baseVersion',
  );
  @override
  late final GeneratedColumn<int> baseVersion = GeneratedColumn<int>(
    'base_version',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _occurredAtMeta = const VerificationMeta(
    'occurredAt',
  );
  @override
  late final GeneratedColumn<DateTime> occurredAt = GeneratedColumn<DateTime>(
    'occurred_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _attemptsMeta = const VerificationMeta(
    'attempts',
  );
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
    'attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    operationId,
    organizationId,
    entityType,
    entityId,
    operationType,
    payload,
    baseVersion,
    occurredAt,
    attempts,
    lastError,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_outbox';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncOutboxData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('operation_id')) {
      context.handle(
        _operationIdMeta,
        operationId.isAcceptableOrUnknown(
          data['operation_id']!,
          _operationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_operationIdMeta);
    }
    if (data.containsKey('organization_id')) {
      context.handle(
        _organizationIdMeta,
        organizationId.isAcceptableOrUnknown(
          data['organization_id']!,
          _organizationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_organizationIdMeta);
    }
    if (data.containsKey('entity_type')) {
      context.handle(
        _entityTypeMeta,
        entityType.isAcceptableOrUnknown(data['entity_type']!, _entityTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('operation_type')) {
      context.handle(
        _operationTypeMeta,
        operationType.isAcceptableOrUnknown(
          data['operation_type']!,
          _operationTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_operationTypeMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('base_version')) {
      context.handle(
        _baseVersionMeta,
        baseVersion.isAcceptableOrUnknown(
          data['base_version']!,
          _baseVersionMeta,
        ),
      );
    }
    if (data.containsKey('occurred_at')) {
      context.handle(
        _occurredAtMeta,
        occurredAt.isAcceptableOrUnknown(data['occurred_at']!, _occurredAtMeta),
      );
    } else if (isInserting) {
      context.missing(_occurredAtMeta);
    }
    if (data.containsKey('attempts')) {
      context.handle(
        _attemptsMeta,
        attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {operationId};
  @override
  SyncOutboxData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncOutboxData(
      operationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operation_id'],
      )!,
      organizationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}organization_id'],
      )!,
      entityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_type'],
      )!,
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      )!,
      operationType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operation_type'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      baseVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}base_version'],
      ),
      occurredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}occurred_at'],
      )!,
      attempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempts'],
      )!,
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
    );
  }

  @override
  $SyncOutboxTable createAlias(String alias) {
    return $SyncOutboxTable(attachedDatabase, alias);
  }
}

class SyncOutboxData extends DataClass implements Insertable<SyncOutboxData> {
  final String operationId;
  final String organizationId;
  final String entityType;
  final String entityId;
  final String operationType;
  final String payload;
  final int? baseVersion;
  final DateTime occurredAt;
  final int attempts;
  final String? lastError;
  const SyncOutboxData({
    required this.operationId,
    required this.organizationId,
    required this.entityType,
    required this.entityId,
    required this.operationType,
    required this.payload,
    this.baseVersion,
    required this.occurredAt,
    required this.attempts,
    this.lastError,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['operation_id'] = Variable<String>(operationId);
    map['organization_id'] = Variable<String>(organizationId);
    map['entity_type'] = Variable<String>(entityType);
    map['entity_id'] = Variable<String>(entityId);
    map['operation_type'] = Variable<String>(operationType);
    map['payload'] = Variable<String>(payload);
    if (!nullToAbsent || baseVersion != null) {
      map['base_version'] = Variable<int>(baseVersion);
    }
    map['occurred_at'] = Variable<DateTime>(occurredAt);
    map['attempts'] = Variable<int>(attempts);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    return map;
  }

  SyncOutboxCompanion toCompanion(bool nullToAbsent) {
    return SyncOutboxCompanion(
      operationId: Value(operationId),
      organizationId: Value(organizationId),
      entityType: Value(entityType),
      entityId: Value(entityId),
      operationType: Value(operationType),
      payload: Value(payload),
      baseVersion: baseVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(baseVersion),
      occurredAt: Value(occurredAt),
      attempts: Value(attempts),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
    );
  }

  factory SyncOutboxData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncOutboxData(
      operationId: serializer.fromJson<String>(json['operationId']),
      organizationId: serializer.fromJson<String>(json['organizationId']),
      entityType: serializer.fromJson<String>(json['entityType']),
      entityId: serializer.fromJson<String>(json['entityId']),
      operationType: serializer.fromJson<String>(json['operationType']),
      payload: serializer.fromJson<String>(json['payload']),
      baseVersion: serializer.fromJson<int?>(json['baseVersion']),
      occurredAt: serializer.fromJson<DateTime>(json['occurredAt']),
      attempts: serializer.fromJson<int>(json['attempts']),
      lastError: serializer.fromJson<String?>(json['lastError']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'operationId': serializer.toJson<String>(operationId),
      'organizationId': serializer.toJson<String>(organizationId),
      'entityType': serializer.toJson<String>(entityType),
      'entityId': serializer.toJson<String>(entityId),
      'operationType': serializer.toJson<String>(operationType),
      'payload': serializer.toJson<String>(payload),
      'baseVersion': serializer.toJson<int?>(baseVersion),
      'occurredAt': serializer.toJson<DateTime>(occurredAt),
      'attempts': serializer.toJson<int>(attempts),
      'lastError': serializer.toJson<String?>(lastError),
    };
  }

  SyncOutboxData copyWith({
    String? operationId,
    String? organizationId,
    String? entityType,
    String? entityId,
    String? operationType,
    String? payload,
    Value<int?> baseVersion = const Value.absent(),
    DateTime? occurredAt,
    int? attempts,
    Value<String?> lastError = const Value.absent(),
  }) => SyncOutboxData(
    operationId: operationId ?? this.operationId,
    organizationId: organizationId ?? this.organizationId,
    entityType: entityType ?? this.entityType,
    entityId: entityId ?? this.entityId,
    operationType: operationType ?? this.operationType,
    payload: payload ?? this.payload,
    baseVersion: baseVersion.present ? baseVersion.value : this.baseVersion,
    occurredAt: occurredAt ?? this.occurredAt,
    attempts: attempts ?? this.attempts,
    lastError: lastError.present ? lastError.value : this.lastError,
  );
  SyncOutboxData copyWithCompanion(SyncOutboxCompanion data) {
    return SyncOutboxData(
      operationId: data.operationId.present
          ? data.operationId.value
          : this.operationId,
      organizationId: data.organizationId.present
          ? data.organizationId.value
          : this.organizationId,
      entityType: data.entityType.present
          ? data.entityType.value
          : this.entityType,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      operationType: data.operationType.present
          ? data.operationType.value
          : this.operationType,
      payload: data.payload.present ? data.payload.value : this.payload,
      baseVersion: data.baseVersion.present
          ? data.baseVersion.value
          : this.baseVersion,
      occurredAt: data.occurredAt.present
          ? data.occurredAt.value
          : this.occurredAt,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncOutboxData(')
          ..write('operationId: $operationId, ')
          ..write('organizationId: $organizationId, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('operationType: $operationType, ')
          ..write('payload: $payload, ')
          ..write('baseVersion: $baseVersion, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('attempts: $attempts, ')
          ..write('lastError: $lastError')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    operationId,
    organizationId,
    entityType,
    entityId,
    operationType,
    payload,
    baseVersion,
    occurredAt,
    attempts,
    lastError,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncOutboxData &&
          other.operationId == this.operationId &&
          other.organizationId == this.organizationId &&
          other.entityType == this.entityType &&
          other.entityId == this.entityId &&
          other.operationType == this.operationType &&
          other.payload == this.payload &&
          other.baseVersion == this.baseVersion &&
          other.occurredAt == this.occurredAt &&
          other.attempts == this.attempts &&
          other.lastError == this.lastError);
}

class SyncOutboxCompanion extends UpdateCompanion<SyncOutboxData> {
  final Value<String> operationId;
  final Value<String> organizationId;
  final Value<String> entityType;
  final Value<String> entityId;
  final Value<String> operationType;
  final Value<String> payload;
  final Value<int?> baseVersion;
  final Value<DateTime> occurredAt;
  final Value<int> attempts;
  final Value<String?> lastError;
  final Value<int> rowid;
  const SyncOutboxCompanion({
    this.operationId = const Value.absent(),
    this.organizationId = const Value.absent(),
    this.entityType = const Value.absent(),
    this.entityId = const Value.absent(),
    this.operationType = const Value.absent(),
    this.payload = const Value.absent(),
    this.baseVersion = const Value.absent(),
    this.occurredAt = const Value.absent(),
    this.attempts = const Value.absent(),
    this.lastError = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncOutboxCompanion.insert({
    required String operationId,
    required String organizationId,
    required String entityType,
    required String entityId,
    required String operationType,
    required String payload,
    this.baseVersion = const Value.absent(),
    required DateTime occurredAt,
    this.attempts = const Value.absent(),
    this.lastError = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : operationId = Value(operationId),
       organizationId = Value(organizationId),
       entityType = Value(entityType),
       entityId = Value(entityId),
       operationType = Value(operationType),
       payload = Value(payload),
       occurredAt = Value(occurredAt);
  static Insertable<SyncOutboxData> custom({
    Expression<String>? operationId,
    Expression<String>? organizationId,
    Expression<String>? entityType,
    Expression<String>? entityId,
    Expression<String>? operationType,
    Expression<String>? payload,
    Expression<int>? baseVersion,
    Expression<DateTime>? occurredAt,
    Expression<int>? attempts,
    Expression<String>? lastError,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (operationId != null) 'operation_id': operationId,
      if (organizationId != null) 'organization_id': organizationId,
      if (entityType != null) 'entity_type': entityType,
      if (entityId != null) 'entity_id': entityId,
      if (operationType != null) 'operation_type': operationType,
      if (payload != null) 'payload': payload,
      if (baseVersion != null) 'base_version': baseVersion,
      if (occurredAt != null) 'occurred_at': occurredAt,
      if (attempts != null) 'attempts': attempts,
      if (lastError != null) 'last_error': lastError,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncOutboxCompanion copyWith({
    Value<String>? operationId,
    Value<String>? organizationId,
    Value<String>? entityType,
    Value<String>? entityId,
    Value<String>? operationType,
    Value<String>? payload,
    Value<int?>? baseVersion,
    Value<DateTime>? occurredAt,
    Value<int>? attempts,
    Value<String?>? lastError,
    Value<int>? rowid,
  }) {
    return SyncOutboxCompanion(
      operationId: operationId ?? this.operationId,
      organizationId: organizationId ?? this.organizationId,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      operationType: operationType ?? this.operationType,
      payload: payload ?? this.payload,
      baseVersion: baseVersion ?? this.baseVersion,
      occurredAt: occurredAt ?? this.occurredAt,
      attempts: attempts ?? this.attempts,
      lastError: lastError ?? this.lastError,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (operationId.present) {
      map['operation_id'] = Variable<String>(operationId.value);
    }
    if (organizationId.present) {
      map['organization_id'] = Variable<String>(organizationId.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (operationType.present) {
      map['operation_type'] = Variable<String>(operationType.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (baseVersion.present) {
      map['base_version'] = Variable<int>(baseVersion.value);
    }
    if (occurredAt.present) {
      map['occurred_at'] = Variable<DateTime>(occurredAt.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncOutboxCompanion(')
          ..write('operationId: $operationId, ')
          ..write('organizationId: $organizationId, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('operationType: $operationType, ')
          ..write('payload: $payload, ')
          ..write('baseVersion: $baseVersion, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('attempts: $attempts, ')
          ..write('lastError: $lastError, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalSyncStateTable extends LocalSyncState
    with TableInfo<$LocalSyncStateTable, LocalSyncStateData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalSyncStateTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _organizationIdMeta = const VerificationMeta(
    'organizationId',
  );
  @override
  late final GeneratedColumn<String> organizationId = GeneratedColumn<String>(
    'organization_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cursorMeta = const VerificationMeta('cursor');
  @override
  late final GeneratedColumn<int> cursor = GeneratedColumn<int>(
    'cursor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [organizationId, cursor];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_sync_state';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalSyncStateData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('organization_id')) {
      context.handle(
        _organizationIdMeta,
        organizationId.isAcceptableOrUnknown(
          data['organization_id']!,
          _organizationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_organizationIdMeta);
    }
    if (data.containsKey('cursor')) {
      context.handle(
        _cursorMeta,
        cursor.isAcceptableOrUnknown(data['cursor']!, _cursorMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {organizationId};
  @override
  LocalSyncStateData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalSyncStateData(
      organizationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}organization_id'],
      )!,
      cursor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cursor'],
      )!,
    );
  }

  @override
  $LocalSyncStateTable createAlias(String alias) {
    return $LocalSyncStateTable(attachedDatabase, alias);
  }
}

class LocalSyncStateData extends DataClass
    implements Insertable<LocalSyncStateData> {
  final String organizationId;
  final int cursor;
  const LocalSyncStateData({
    required this.organizationId,
    required this.cursor,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['organization_id'] = Variable<String>(organizationId);
    map['cursor'] = Variable<int>(cursor);
    return map;
  }

  LocalSyncStateCompanion toCompanion(bool nullToAbsent) {
    return LocalSyncStateCompanion(
      organizationId: Value(organizationId),
      cursor: Value(cursor),
    );
  }

  factory LocalSyncStateData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalSyncStateData(
      organizationId: serializer.fromJson<String>(json['organizationId']),
      cursor: serializer.fromJson<int>(json['cursor']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'organizationId': serializer.toJson<String>(organizationId),
      'cursor': serializer.toJson<int>(cursor),
    };
  }

  LocalSyncStateData copyWith({String? organizationId, int? cursor}) =>
      LocalSyncStateData(
        organizationId: organizationId ?? this.organizationId,
        cursor: cursor ?? this.cursor,
      );
  LocalSyncStateData copyWithCompanion(LocalSyncStateCompanion data) {
    return LocalSyncStateData(
      organizationId: data.organizationId.present
          ? data.organizationId.value
          : this.organizationId,
      cursor: data.cursor.present ? data.cursor.value : this.cursor,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalSyncStateData(')
          ..write('organizationId: $organizationId, ')
          ..write('cursor: $cursor')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(organizationId, cursor);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalSyncStateData &&
          other.organizationId == this.organizationId &&
          other.cursor == this.cursor);
}

class LocalSyncStateCompanion extends UpdateCompanion<LocalSyncStateData> {
  final Value<String> organizationId;
  final Value<int> cursor;
  final Value<int> rowid;
  const LocalSyncStateCompanion({
    this.organizationId = const Value.absent(),
    this.cursor = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalSyncStateCompanion.insert({
    required String organizationId,
    this.cursor = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : organizationId = Value(organizationId);
  static Insertable<LocalSyncStateData> custom({
    Expression<String>? organizationId,
    Expression<int>? cursor,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (organizationId != null) 'organization_id': organizationId,
      if (cursor != null) 'cursor': cursor,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalSyncStateCompanion copyWith({
    Value<String>? organizationId,
    Value<int>? cursor,
    Value<int>? rowid,
  }) {
    return LocalSyncStateCompanion(
      organizationId: organizationId ?? this.organizationId,
      cursor: cursor ?? this.cursor,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (organizationId.present) {
      map['organization_id'] = Variable<String>(organizationId.value);
    }
    if (cursor.present) {
      map['cursor'] = Variable<int>(cursor.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalSyncStateCompanion(')
          ..write('organizationId: $organizationId, ')
          ..write('cursor: $cursor, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UploadQueueTable extends UploadQueue
    with TableInfo<$UploadQueueTable, UploadQueueData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UploadQueueTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _organizationIdMeta = const VerificationMeta(
    'organizationId',
  );
  @override
  late final GeneratedColumn<String> organizationId = GeneratedColumn<String>(
    'organization_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _serviceOrderIdMeta = const VerificationMeta(
    'serviceOrderId',
  );
  @override
  late final GeneratedColumn<String> serviceOrderId = GeneratedColumn<String>(
    'service_order_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _filePathMeta = const VerificationMeta(
    'filePath',
  );
  @override
  late final GeneratedColumn<String> filePath = GeneratedColumn<String>(
    'file_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sha256Meta = const VerificationMeta('sha256');
  @override
  late final GeneratedColumn<String> sha256 = GeneratedColumn<String>(
    'sha256',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _photoKindMeta = const VerificationMeta(
    'photoKind',
  );
  @override
  late final GeneratedColumn<String> photoKind = GeneratedColumn<String>(
    'photo_kind',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _captionMeta = const VerificationMeta(
    'caption',
  );
  @override
  late final GeneratedColumn<String> caption = GeneratedColumn<String>(
    'caption',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _attemptsMeta = const VerificationMeta(
    'attempts',
  );
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
    'attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    organizationId,
    serviceOrderId,
    kind,
    filePath,
    sha256,
    photoKind,
    caption,
    createdAt,
    attempts,
    lastError,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'upload_queue';
  @override
  VerificationContext validateIntegrity(
    Insertable<UploadQueueData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('organization_id')) {
      context.handle(
        _organizationIdMeta,
        organizationId.isAcceptableOrUnknown(
          data['organization_id']!,
          _organizationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_organizationIdMeta);
    }
    if (data.containsKey('service_order_id')) {
      context.handle(
        _serviceOrderIdMeta,
        serviceOrderId.isAcceptableOrUnknown(
          data['service_order_id']!,
          _serviceOrderIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_serviceOrderIdMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('file_path')) {
      context.handle(
        _filePathMeta,
        filePath.isAcceptableOrUnknown(data['file_path']!, _filePathMeta),
      );
    } else if (isInserting) {
      context.missing(_filePathMeta);
    }
    if (data.containsKey('sha256')) {
      context.handle(
        _sha256Meta,
        sha256.isAcceptableOrUnknown(data['sha256']!, _sha256Meta),
      );
    } else if (isInserting) {
      context.missing(_sha256Meta);
    }
    if (data.containsKey('photo_kind')) {
      context.handle(
        _photoKindMeta,
        photoKind.isAcceptableOrUnknown(data['photo_kind']!, _photoKindMeta),
      );
    }
    if (data.containsKey('caption')) {
      context.handle(
        _captionMeta,
        caption.isAcceptableOrUnknown(data['caption']!, _captionMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('attempts')) {
      context.handle(
        _attemptsMeta,
        attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UploadQueueData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UploadQueueData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      organizationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}organization_id'],
      )!,
      serviceOrderId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}service_order_id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      filePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_path'],
      )!,
      sha256: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sha256'],
      )!,
      photoKind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}photo_kind'],
      ),
      caption: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}caption'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      attempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempts'],
      )!,
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
    );
  }

  @override
  $UploadQueueTable createAlias(String alias) {
    return $UploadQueueTable(attachedDatabase, alias);
  }
}

class UploadQueueData extends DataClass implements Insertable<UploadQueueData> {
  final String id;
  final String organizationId;
  final String serviceOrderId;
  final String kind;
  final String filePath;
  final String sha256;
  final String? photoKind;
  final String? caption;
  final DateTime createdAt;
  final int attempts;
  final String? lastError;
  const UploadQueueData({
    required this.id,
    required this.organizationId,
    required this.serviceOrderId,
    required this.kind,
    required this.filePath,
    required this.sha256,
    this.photoKind,
    this.caption,
    required this.createdAt,
    required this.attempts,
    this.lastError,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['organization_id'] = Variable<String>(organizationId);
    map['service_order_id'] = Variable<String>(serviceOrderId);
    map['kind'] = Variable<String>(kind);
    map['file_path'] = Variable<String>(filePath);
    map['sha256'] = Variable<String>(sha256);
    if (!nullToAbsent || photoKind != null) {
      map['photo_kind'] = Variable<String>(photoKind);
    }
    if (!nullToAbsent || caption != null) {
      map['caption'] = Variable<String>(caption);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['attempts'] = Variable<int>(attempts);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    return map;
  }

  UploadQueueCompanion toCompanion(bool nullToAbsent) {
    return UploadQueueCompanion(
      id: Value(id),
      organizationId: Value(organizationId),
      serviceOrderId: Value(serviceOrderId),
      kind: Value(kind),
      filePath: Value(filePath),
      sha256: Value(sha256),
      photoKind: photoKind == null && nullToAbsent
          ? const Value.absent()
          : Value(photoKind),
      caption: caption == null && nullToAbsent
          ? const Value.absent()
          : Value(caption),
      createdAt: Value(createdAt),
      attempts: Value(attempts),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
    );
  }

  factory UploadQueueData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UploadQueueData(
      id: serializer.fromJson<String>(json['id']),
      organizationId: serializer.fromJson<String>(json['organizationId']),
      serviceOrderId: serializer.fromJson<String>(json['serviceOrderId']),
      kind: serializer.fromJson<String>(json['kind']),
      filePath: serializer.fromJson<String>(json['filePath']),
      sha256: serializer.fromJson<String>(json['sha256']),
      photoKind: serializer.fromJson<String?>(json['photoKind']),
      caption: serializer.fromJson<String?>(json['caption']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      attempts: serializer.fromJson<int>(json['attempts']),
      lastError: serializer.fromJson<String?>(json['lastError']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'organizationId': serializer.toJson<String>(organizationId),
      'serviceOrderId': serializer.toJson<String>(serviceOrderId),
      'kind': serializer.toJson<String>(kind),
      'filePath': serializer.toJson<String>(filePath),
      'sha256': serializer.toJson<String>(sha256),
      'photoKind': serializer.toJson<String?>(photoKind),
      'caption': serializer.toJson<String?>(caption),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'attempts': serializer.toJson<int>(attempts),
      'lastError': serializer.toJson<String?>(lastError),
    };
  }

  UploadQueueData copyWith({
    String? id,
    String? organizationId,
    String? serviceOrderId,
    String? kind,
    String? filePath,
    String? sha256,
    Value<String?> photoKind = const Value.absent(),
    Value<String?> caption = const Value.absent(),
    DateTime? createdAt,
    int? attempts,
    Value<String?> lastError = const Value.absent(),
  }) => UploadQueueData(
    id: id ?? this.id,
    organizationId: organizationId ?? this.organizationId,
    serviceOrderId: serviceOrderId ?? this.serviceOrderId,
    kind: kind ?? this.kind,
    filePath: filePath ?? this.filePath,
    sha256: sha256 ?? this.sha256,
    photoKind: photoKind.present ? photoKind.value : this.photoKind,
    caption: caption.present ? caption.value : this.caption,
    createdAt: createdAt ?? this.createdAt,
    attempts: attempts ?? this.attempts,
    lastError: lastError.present ? lastError.value : this.lastError,
  );
  UploadQueueData copyWithCompanion(UploadQueueCompanion data) {
    return UploadQueueData(
      id: data.id.present ? data.id.value : this.id,
      organizationId: data.organizationId.present
          ? data.organizationId.value
          : this.organizationId,
      serviceOrderId: data.serviceOrderId.present
          ? data.serviceOrderId.value
          : this.serviceOrderId,
      kind: data.kind.present ? data.kind.value : this.kind,
      filePath: data.filePath.present ? data.filePath.value : this.filePath,
      sha256: data.sha256.present ? data.sha256.value : this.sha256,
      photoKind: data.photoKind.present ? data.photoKind.value : this.photoKind,
      caption: data.caption.present ? data.caption.value : this.caption,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UploadQueueData(')
          ..write('id: $id, ')
          ..write('organizationId: $organizationId, ')
          ..write('serviceOrderId: $serviceOrderId, ')
          ..write('kind: $kind, ')
          ..write('filePath: $filePath, ')
          ..write('sha256: $sha256, ')
          ..write('photoKind: $photoKind, ')
          ..write('caption: $caption, ')
          ..write('createdAt: $createdAt, ')
          ..write('attempts: $attempts, ')
          ..write('lastError: $lastError')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    organizationId,
    serviceOrderId,
    kind,
    filePath,
    sha256,
    photoKind,
    caption,
    createdAt,
    attempts,
    lastError,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UploadQueueData &&
          other.id == this.id &&
          other.organizationId == this.organizationId &&
          other.serviceOrderId == this.serviceOrderId &&
          other.kind == this.kind &&
          other.filePath == this.filePath &&
          other.sha256 == this.sha256 &&
          other.photoKind == this.photoKind &&
          other.caption == this.caption &&
          other.createdAt == this.createdAt &&
          other.attempts == this.attempts &&
          other.lastError == this.lastError);
}

class UploadQueueCompanion extends UpdateCompanion<UploadQueueData> {
  final Value<String> id;
  final Value<String> organizationId;
  final Value<String> serviceOrderId;
  final Value<String> kind;
  final Value<String> filePath;
  final Value<String> sha256;
  final Value<String?> photoKind;
  final Value<String?> caption;
  final Value<DateTime> createdAt;
  final Value<int> attempts;
  final Value<String?> lastError;
  final Value<int> rowid;
  const UploadQueueCompanion({
    this.id = const Value.absent(),
    this.organizationId = const Value.absent(),
    this.serviceOrderId = const Value.absent(),
    this.kind = const Value.absent(),
    this.filePath = const Value.absent(),
    this.sha256 = const Value.absent(),
    this.photoKind = const Value.absent(),
    this.caption = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.attempts = const Value.absent(),
    this.lastError = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UploadQueueCompanion.insert({
    required String id,
    required String organizationId,
    required String serviceOrderId,
    required String kind,
    required String filePath,
    required String sha256,
    this.photoKind = const Value.absent(),
    this.caption = const Value.absent(),
    required DateTime createdAt,
    this.attempts = const Value.absent(),
    this.lastError = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       organizationId = Value(organizationId),
       serviceOrderId = Value(serviceOrderId),
       kind = Value(kind),
       filePath = Value(filePath),
       sha256 = Value(sha256),
       createdAt = Value(createdAt);
  static Insertable<UploadQueueData> custom({
    Expression<String>? id,
    Expression<String>? organizationId,
    Expression<String>? serviceOrderId,
    Expression<String>? kind,
    Expression<String>? filePath,
    Expression<String>? sha256,
    Expression<String>? photoKind,
    Expression<String>? caption,
    Expression<DateTime>? createdAt,
    Expression<int>? attempts,
    Expression<String>? lastError,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (organizationId != null) 'organization_id': organizationId,
      if (serviceOrderId != null) 'service_order_id': serviceOrderId,
      if (kind != null) 'kind': kind,
      if (filePath != null) 'file_path': filePath,
      if (sha256 != null) 'sha256': sha256,
      if (photoKind != null) 'photo_kind': photoKind,
      if (caption != null) 'caption': caption,
      if (createdAt != null) 'created_at': createdAt,
      if (attempts != null) 'attempts': attempts,
      if (lastError != null) 'last_error': lastError,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UploadQueueCompanion copyWith({
    Value<String>? id,
    Value<String>? organizationId,
    Value<String>? serviceOrderId,
    Value<String>? kind,
    Value<String>? filePath,
    Value<String>? sha256,
    Value<String?>? photoKind,
    Value<String?>? caption,
    Value<DateTime>? createdAt,
    Value<int>? attempts,
    Value<String?>? lastError,
    Value<int>? rowid,
  }) {
    return UploadQueueCompanion(
      id: id ?? this.id,
      organizationId: organizationId ?? this.organizationId,
      serviceOrderId: serviceOrderId ?? this.serviceOrderId,
      kind: kind ?? this.kind,
      filePath: filePath ?? this.filePath,
      sha256: sha256 ?? this.sha256,
      photoKind: photoKind ?? this.photoKind,
      caption: caption ?? this.caption,
      createdAt: createdAt ?? this.createdAt,
      attempts: attempts ?? this.attempts,
      lastError: lastError ?? this.lastError,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (organizationId.present) {
      map['organization_id'] = Variable<String>(organizationId.value);
    }
    if (serviceOrderId.present) {
      map['service_order_id'] = Variable<String>(serviceOrderId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (filePath.present) {
      map['file_path'] = Variable<String>(filePath.value);
    }
    if (sha256.present) {
      map['sha256'] = Variable<String>(sha256.value);
    }
    if (photoKind.present) {
      map['photo_kind'] = Variable<String>(photoKind.value);
    }
    if (caption.present) {
      map['caption'] = Variable<String>(caption.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UploadQueueCompanion(')
          ..write('id: $id, ')
          ..write('organizationId: $organizationId, ')
          ..write('serviceOrderId: $serviceOrderId, ')
          ..write('kind: $kind, ')
          ..write('filePath: $filePath, ')
          ..write('sha256: $sha256, ')
          ..write('photoKind: $photoKind, ')
          ..write('caption: $caption, ')
          ..write('createdAt: $createdAt, ')
          ..write('attempts: $attempts, ')
          ..write('lastError: $lastError, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $LocalClientsTable localClients = $LocalClientsTable(this);
  late final $LocalLocationsTable localLocations = $LocalLocationsTable(this);
  late final $LocalEquipmentsTable localEquipments = $LocalEquipmentsTable(
    this,
  );
  late final $LocalServiceOrdersTable localServiceOrders =
      $LocalServiceOrdersTable(this);
  late final $LocalServiceOrderPartsTable localServiceOrderParts =
      $LocalServiceOrderPartsTable(this);
  late final $LocalEquipmentTypesTable localEquipmentTypes =
      $LocalEquipmentTypesTable(this);
  late final $LocalReferenceDataTable localReferenceData =
      $LocalReferenceDataTable(this);
  late final $LocalQrCodesTable localQrCodes = $LocalQrCodesTable(this);
  late final $LocalQrBatchesTable localQrBatches = $LocalQrBatchesTable(this);
  late final $SyncOutboxTable syncOutbox = $SyncOutboxTable(this);
  late final $LocalSyncStateTable localSyncState = $LocalSyncStateTable(this);
  late final $UploadQueueTable uploadQueue = $UploadQueueTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    localClients,
    localLocations,
    localEquipments,
    localServiceOrders,
    localServiceOrderParts,
    localEquipmentTypes,
    localReferenceData,
    localQrCodes,
    localQrBatches,
    syncOutbox,
    localSyncState,
    uploadQueue,
  ];
}

typedef $$LocalClientsTableCreateCompanionBuilder =
    LocalClientsCompanion Function({
      required String organizationId,
      Value<int?> version,
      Value<String> syncStatus,
      required DateTime localUpdatedAt,
      Value<DateTime?> lastSyncedAt,
      Value<String?> syncError,
      Value<bool> deleted,
      required String id,
      required String kind,
      required String name,
      Value<String> legalName,
      Value<String> taxId,
      Value<String> phone,
      Value<String> email,
      Value<String> contactPerson,
      Value<String?> internalNotes,
      Value<DateTime?> createdAt,
      Value<DateTime?> updatedAt,
      Value<int> rowid,
    });
typedef $$LocalClientsTableUpdateCompanionBuilder =
    LocalClientsCompanion Function({
      Value<String> organizationId,
      Value<int?> version,
      Value<String> syncStatus,
      Value<DateTime> localUpdatedAt,
      Value<DateTime?> lastSyncedAt,
      Value<String?> syncError,
      Value<bool> deleted,
      Value<String> id,
      Value<String> kind,
      Value<String> name,
      Value<String> legalName,
      Value<String> taxId,
      Value<String> phone,
      Value<String> email,
      Value<String> contactPerson,
      Value<String?> internalNotes,
      Value<DateTime?> createdAt,
      Value<DateTime?> updatedAt,
      Value<int> rowid,
    });

class $$LocalClientsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalClientsTable> {
  $$LocalClientsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get organizationId => $composableBuilder(
    column: $table.organizationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get localUpdatedAt => $composableBuilder(
    column: $table.localUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncError => $composableBuilder(
    column: $table.syncError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get legalName => $composableBuilder(
    column: $table.legalName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get taxId => $composableBuilder(
    column: $table.taxId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contactPerson => $composableBuilder(
    column: $table.contactPerson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get internalNotes => $composableBuilder(
    column: $table.internalNotes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalClientsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalClientsTable> {
  $$LocalClientsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get organizationId => $composableBuilder(
    column: $table.organizationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get localUpdatedAt => $composableBuilder(
    column: $table.localUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncError => $composableBuilder(
    column: $table.syncError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get legalName => $composableBuilder(
    column: $table.legalName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get taxId => $composableBuilder(
    column: $table.taxId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contactPerson => $composableBuilder(
    column: $table.contactPerson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get internalNotes => $composableBuilder(
    column: $table.internalNotes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalClientsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalClientsTable> {
  $$LocalClientsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get organizationId => $composableBuilder(
    column: $table.organizationId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get localUpdatedAt => $composableBuilder(
    column: $table.localUpdatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncError =>
      $composableBuilder(column: $table.syncError, builder: (column) => column);

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get legalName =>
      $composableBuilder(column: $table.legalName, builder: (column) => column);

  GeneratedColumn<String> get taxId =>
      $composableBuilder(column: $table.taxId, builder: (column) => column);

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get contactPerson => $composableBuilder(
    column: $table.contactPerson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get internalNotes => $composableBuilder(
    column: $table.internalNotes,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$LocalClientsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalClientsTable,
          LocalClient,
          $$LocalClientsTableFilterComposer,
          $$LocalClientsTableOrderingComposer,
          $$LocalClientsTableAnnotationComposer,
          $$LocalClientsTableCreateCompanionBuilder,
          $$LocalClientsTableUpdateCompanionBuilder,
          (
            LocalClient,
            BaseReferences<_$AppDatabase, $LocalClientsTable, LocalClient>,
          ),
          LocalClient,
          PrefetchHooks Function()
        > {
  $$LocalClientsTableTableManager(_$AppDatabase db, $LocalClientsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalClientsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalClientsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalClientsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> organizationId = const Value.absent(),
                Value<int?> version = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<DateTime> localUpdatedAt = const Value.absent(),
                Value<DateTime?> lastSyncedAt = const Value.absent(),
                Value<String?> syncError = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> legalName = const Value.absent(),
                Value<String> taxId = const Value.absent(),
                Value<String> phone = const Value.absent(),
                Value<String> email = const Value.absent(),
                Value<String> contactPerson = const Value.absent(),
                Value<String?> internalNotes = const Value.absent(),
                Value<DateTime?> createdAt = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalClientsCompanion(
                organizationId: organizationId,
                version: version,
                syncStatus: syncStatus,
                localUpdatedAt: localUpdatedAt,
                lastSyncedAt: lastSyncedAt,
                syncError: syncError,
                deleted: deleted,
                id: id,
                kind: kind,
                name: name,
                legalName: legalName,
                taxId: taxId,
                phone: phone,
                email: email,
                contactPerson: contactPerson,
                internalNotes: internalNotes,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String organizationId,
                Value<int?> version = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                required DateTime localUpdatedAt,
                Value<DateTime?> lastSyncedAt = const Value.absent(),
                Value<String?> syncError = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                required String id,
                required String kind,
                required String name,
                Value<String> legalName = const Value.absent(),
                Value<String> taxId = const Value.absent(),
                Value<String> phone = const Value.absent(),
                Value<String> email = const Value.absent(),
                Value<String> contactPerson = const Value.absent(),
                Value<String?> internalNotes = const Value.absent(),
                Value<DateTime?> createdAt = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalClientsCompanion.insert(
                organizationId: organizationId,
                version: version,
                syncStatus: syncStatus,
                localUpdatedAt: localUpdatedAt,
                lastSyncedAt: lastSyncedAt,
                syncError: syncError,
                deleted: deleted,
                id: id,
                kind: kind,
                name: name,
                legalName: legalName,
                taxId: taxId,
                phone: phone,
                email: email,
                contactPerson: contactPerson,
                internalNotes: internalNotes,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LocalClientsTable, LocalClient>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $LocalClientsTable,
                    LocalClient
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalClientsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalClientsTable,
      LocalClient,
      $$LocalClientsTableFilterComposer,
      $$LocalClientsTableOrderingComposer,
      $$LocalClientsTableAnnotationComposer,
      $$LocalClientsTableCreateCompanionBuilder,
      $$LocalClientsTableUpdateCompanionBuilder,
      (
        LocalClient,
        BaseReferences<_$AppDatabase, $LocalClientsTable, LocalClient>,
      ),
      LocalClient,
      PrefetchHooks Function()
    >;
typedef $$LocalLocationsTableCreateCompanionBuilder =
    LocalLocationsCompanion Function({
      required String organizationId,
      Value<int?> version,
      Value<String> syncStatus,
      required DateTime localUpdatedAt,
      Value<DateTime?> lastSyncedAt,
      Value<String?> syncError,
      Value<bool> deleted,
      required String id,
      required String clientId,
      Value<String?> parentLocationId,
      required String name,
      Value<String> postalCode,
      Value<String> street,
      Value<String> number,
      Value<String> complement,
      Value<String> district,
      Value<String> city,
      Value<String> state,
      Value<String> contactPerson,
      Value<String> phone,
      Value<String> accessInstructions,
      Value<String> notes,
      Value<DateTime?> createdAt,
      Value<DateTime?> updatedAt,
      Value<int> rowid,
    });
typedef $$LocalLocationsTableUpdateCompanionBuilder =
    LocalLocationsCompanion Function({
      Value<String> organizationId,
      Value<int?> version,
      Value<String> syncStatus,
      Value<DateTime> localUpdatedAt,
      Value<DateTime?> lastSyncedAt,
      Value<String?> syncError,
      Value<bool> deleted,
      Value<String> id,
      Value<String> clientId,
      Value<String?> parentLocationId,
      Value<String> name,
      Value<String> postalCode,
      Value<String> street,
      Value<String> number,
      Value<String> complement,
      Value<String> district,
      Value<String> city,
      Value<String> state,
      Value<String> contactPerson,
      Value<String> phone,
      Value<String> accessInstructions,
      Value<String> notes,
      Value<DateTime?> createdAt,
      Value<DateTime?> updatedAt,
      Value<int> rowid,
    });

class $$LocalLocationsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalLocationsTable> {
  $$LocalLocationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get organizationId => $composableBuilder(
    column: $table.organizationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get localUpdatedAt => $composableBuilder(
    column: $table.localUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncError => $composableBuilder(
    column: $table.syncError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get parentLocationId => $composableBuilder(
    column: $table.parentLocationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get postalCode => $composableBuilder(
    column: $table.postalCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get street => $composableBuilder(
    column: $table.street,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get number => $composableBuilder(
    column: $table.number,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get complement => $composableBuilder(
    column: $table.complement,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get district => $composableBuilder(
    column: $table.district,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get city => $composableBuilder(
    column: $table.city,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contactPerson => $composableBuilder(
    column: $table.contactPerson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accessInstructions => $composableBuilder(
    column: $table.accessInstructions,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalLocationsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalLocationsTable> {
  $$LocalLocationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get organizationId => $composableBuilder(
    column: $table.organizationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get localUpdatedAt => $composableBuilder(
    column: $table.localUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncError => $composableBuilder(
    column: $table.syncError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get parentLocationId => $composableBuilder(
    column: $table.parentLocationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get postalCode => $composableBuilder(
    column: $table.postalCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get street => $composableBuilder(
    column: $table.street,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get number => $composableBuilder(
    column: $table.number,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get complement => $composableBuilder(
    column: $table.complement,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get district => $composableBuilder(
    column: $table.district,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get city => $composableBuilder(
    column: $table.city,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contactPerson => $composableBuilder(
    column: $table.contactPerson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accessInstructions => $composableBuilder(
    column: $table.accessInstructions,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalLocationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalLocationsTable> {
  $$LocalLocationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get organizationId => $composableBuilder(
    column: $table.organizationId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get localUpdatedAt => $composableBuilder(
    column: $table.localUpdatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncError =>
      $composableBuilder(column: $table.syncError, builder: (column) => column);

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get clientId =>
      $composableBuilder(column: $table.clientId, builder: (column) => column);

  GeneratedColumn<String> get parentLocationId => $composableBuilder(
    column: $table.parentLocationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get postalCode => $composableBuilder(
    column: $table.postalCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get street =>
      $composableBuilder(column: $table.street, builder: (column) => column);

  GeneratedColumn<String> get number =>
      $composableBuilder(column: $table.number, builder: (column) => column);

  GeneratedColumn<String> get complement => $composableBuilder(
    column: $table.complement,
    builder: (column) => column,
  );

  GeneratedColumn<String> get district =>
      $composableBuilder(column: $table.district, builder: (column) => column);

  GeneratedColumn<String> get city =>
      $composableBuilder(column: $table.city, builder: (column) => column);

  GeneratedColumn<String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<String> get contactPerson => $composableBuilder(
    column: $table.contactPerson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumn<String> get accessInstructions => $composableBuilder(
    column: $table.accessInstructions,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$LocalLocationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalLocationsTable,
          LocalLocation,
          $$LocalLocationsTableFilterComposer,
          $$LocalLocationsTableOrderingComposer,
          $$LocalLocationsTableAnnotationComposer,
          $$LocalLocationsTableCreateCompanionBuilder,
          $$LocalLocationsTableUpdateCompanionBuilder,
          (
            LocalLocation,
            BaseReferences<_$AppDatabase, $LocalLocationsTable, LocalLocation>,
          ),
          LocalLocation,
          PrefetchHooks Function()
        > {
  $$LocalLocationsTableTableManager(
    _$AppDatabase db,
    $LocalLocationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalLocationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalLocationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalLocationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> organizationId = const Value.absent(),
                Value<int?> version = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<DateTime> localUpdatedAt = const Value.absent(),
                Value<DateTime?> lastSyncedAt = const Value.absent(),
                Value<String?> syncError = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<String> clientId = const Value.absent(),
                Value<String?> parentLocationId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> postalCode = const Value.absent(),
                Value<String> street = const Value.absent(),
                Value<String> number = const Value.absent(),
                Value<String> complement = const Value.absent(),
                Value<String> district = const Value.absent(),
                Value<String> city = const Value.absent(),
                Value<String> state = const Value.absent(),
                Value<String> contactPerson = const Value.absent(),
                Value<String> phone = const Value.absent(),
                Value<String> accessInstructions = const Value.absent(),
                Value<String> notes = const Value.absent(),
                Value<DateTime?> createdAt = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalLocationsCompanion(
                organizationId: organizationId,
                version: version,
                syncStatus: syncStatus,
                localUpdatedAt: localUpdatedAt,
                lastSyncedAt: lastSyncedAt,
                syncError: syncError,
                deleted: deleted,
                id: id,
                clientId: clientId,
                parentLocationId: parentLocationId,
                name: name,
                postalCode: postalCode,
                street: street,
                number: number,
                complement: complement,
                district: district,
                city: city,
                state: state,
                contactPerson: contactPerson,
                phone: phone,
                accessInstructions: accessInstructions,
                notes: notes,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String organizationId,
                Value<int?> version = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                required DateTime localUpdatedAt,
                Value<DateTime?> lastSyncedAt = const Value.absent(),
                Value<String?> syncError = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                required String id,
                required String clientId,
                Value<String?> parentLocationId = const Value.absent(),
                required String name,
                Value<String> postalCode = const Value.absent(),
                Value<String> street = const Value.absent(),
                Value<String> number = const Value.absent(),
                Value<String> complement = const Value.absent(),
                Value<String> district = const Value.absent(),
                Value<String> city = const Value.absent(),
                Value<String> state = const Value.absent(),
                Value<String> contactPerson = const Value.absent(),
                Value<String> phone = const Value.absent(),
                Value<String> accessInstructions = const Value.absent(),
                Value<String> notes = const Value.absent(),
                Value<DateTime?> createdAt = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalLocationsCompanion.insert(
                organizationId: organizationId,
                version: version,
                syncStatus: syncStatus,
                localUpdatedAt: localUpdatedAt,
                lastSyncedAt: lastSyncedAt,
                syncError: syncError,
                deleted: deleted,
                id: id,
                clientId: clientId,
                parentLocationId: parentLocationId,
                name: name,
                postalCode: postalCode,
                street: street,
                number: number,
                complement: complement,
                district: district,
                city: city,
                state: state,
                contactPerson: contactPerson,
                phone: phone,
                accessInstructions: accessInstructions,
                notes: notes,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LocalLocationsTable, LocalLocation>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $LocalLocationsTable,
                    LocalLocation
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalLocationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalLocationsTable,
      LocalLocation,
      $$LocalLocationsTableFilterComposer,
      $$LocalLocationsTableOrderingComposer,
      $$LocalLocationsTableAnnotationComposer,
      $$LocalLocationsTableCreateCompanionBuilder,
      $$LocalLocationsTableUpdateCompanionBuilder,
      (
        LocalLocation,
        BaseReferences<_$AppDatabase, $LocalLocationsTable, LocalLocation>,
      ),
      LocalLocation,
      PrefetchHooks Function()
    >;
typedef $$LocalEquipmentsTableCreateCompanionBuilder =
    LocalEquipmentsCompanion Function({
      required String organizationId,
      Value<int?> version,
      Value<String> syncStatus,
      required DateTime localUpdatedAt,
      Value<DateTime?> lastSyncedAt,
      Value<String?> syncError,
      Value<bool> deleted,
      required String id,
      required String locationId,
      required String equipmentTypeId,
      required String name,
      Value<String> brand,
      Value<String> model,
      Value<String?> serialNumber,
      Value<String> internalLocation,
      Value<String?> installedAt,
      Value<String?> cost,
      Value<String> notes,
      Value<DateTime?> createdAt,
      Value<DateTime?> updatedAt,
      Value<int> rowid,
    });
typedef $$LocalEquipmentsTableUpdateCompanionBuilder =
    LocalEquipmentsCompanion Function({
      Value<String> organizationId,
      Value<int?> version,
      Value<String> syncStatus,
      Value<DateTime> localUpdatedAt,
      Value<DateTime?> lastSyncedAt,
      Value<String?> syncError,
      Value<bool> deleted,
      Value<String> id,
      Value<String> locationId,
      Value<String> equipmentTypeId,
      Value<String> name,
      Value<String> brand,
      Value<String> model,
      Value<String?> serialNumber,
      Value<String> internalLocation,
      Value<String?> installedAt,
      Value<String?> cost,
      Value<String> notes,
      Value<DateTime?> createdAt,
      Value<DateTime?> updatedAt,
      Value<int> rowid,
    });

class $$LocalEquipmentsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalEquipmentsTable> {
  $$LocalEquipmentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get organizationId => $composableBuilder(
    column: $table.organizationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get localUpdatedAt => $composableBuilder(
    column: $table.localUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncError => $composableBuilder(
    column: $table.syncError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get locationId => $composableBuilder(
    column: $table.locationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get equipmentTypeId => $composableBuilder(
    column: $table.equipmentTypeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get brand => $composableBuilder(
    column: $table.brand,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get model => $composableBuilder(
    column: $table.model,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serialNumber => $composableBuilder(
    column: $table.serialNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get internalLocation => $composableBuilder(
    column: $table.internalLocation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get installedAt => $composableBuilder(
    column: $table.installedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cost => $composableBuilder(
    column: $table.cost,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalEquipmentsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalEquipmentsTable> {
  $$LocalEquipmentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get organizationId => $composableBuilder(
    column: $table.organizationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get localUpdatedAt => $composableBuilder(
    column: $table.localUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncError => $composableBuilder(
    column: $table.syncError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get locationId => $composableBuilder(
    column: $table.locationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get equipmentTypeId => $composableBuilder(
    column: $table.equipmentTypeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get brand => $composableBuilder(
    column: $table.brand,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get model => $composableBuilder(
    column: $table.model,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serialNumber => $composableBuilder(
    column: $table.serialNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get internalLocation => $composableBuilder(
    column: $table.internalLocation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get installedAt => $composableBuilder(
    column: $table.installedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cost => $composableBuilder(
    column: $table.cost,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalEquipmentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalEquipmentsTable> {
  $$LocalEquipmentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get organizationId => $composableBuilder(
    column: $table.organizationId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get localUpdatedAt => $composableBuilder(
    column: $table.localUpdatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncError =>
      $composableBuilder(column: $table.syncError, builder: (column) => column);

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get locationId => $composableBuilder(
    column: $table.locationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get equipmentTypeId => $composableBuilder(
    column: $table.equipmentTypeId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get brand =>
      $composableBuilder(column: $table.brand, builder: (column) => column);

  GeneratedColumn<String> get model =>
      $composableBuilder(column: $table.model, builder: (column) => column);

  GeneratedColumn<String> get serialNumber => $composableBuilder(
    column: $table.serialNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get internalLocation => $composableBuilder(
    column: $table.internalLocation,
    builder: (column) => column,
  );

  GeneratedColumn<String> get installedAt => $composableBuilder(
    column: $table.installedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get cost =>
      $composableBuilder(column: $table.cost, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$LocalEquipmentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalEquipmentsTable,
          LocalEquipment,
          $$LocalEquipmentsTableFilterComposer,
          $$LocalEquipmentsTableOrderingComposer,
          $$LocalEquipmentsTableAnnotationComposer,
          $$LocalEquipmentsTableCreateCompanionBuilder,
          $$LocalEquipmentsTableUpdateCompanionBuilder,
          (
            LocalEquipment,
            BaseReferences<
              _$AppDatabase,
              $LocalEquipmentsTable,
              LocalEquipment
            >,
          ),
          LocalEquipment,
          PrefetchHooks Function()
        > {
  $$LocalEquipmentsTableTableManager(
    _$AppDatabase db,
    $LocalEquipmentsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalEquipmentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalEquipmentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalEquipmentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> organizationId = const Value.absent(),
                Value<int?> version = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<DateTime> localUpdatedAt = const Value.absent(),
                Value<DateTime?> lastSyncedAt = const Value.absent(),
                Value<String?> syncError = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<String> locationId = const Value.absent(),
                Value<String> equipmentTypeId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> brand = const Value.absent(),
                Value<String> model = const Value.absent(),
                Value<String?> serialNumber = const Value.absent(),
                Value<String> internalLocation = const Value.absent(),
                Value<String?> installedAt = const Value.absent(),
                Value<String?> cost = const Value.absent(),
                Value<String> notes = const Value.absent(),
                Value<DateTime?> createdAt = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalEquipmentsCompanion(
                organizationId: organizationId,
                version: version,
                syncStatus: syncStatus,
                localUpdatedAt: localUpdatedAt,
                lastSyncedAt: lastSyncedAt,
                syncError: syncError,
                deleted: deleted,
                id: id,
                locationId: locationId,
                equipmentTypeId: equipmentTypeId,
                name: name,
                brand: brand,
                model: model,
                serialNumber: serialNumber,
                internalLocation: internalLocation,
                installedAt: installedAt,
                cost: cost,
                notes: notes,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String organizationId,
                Value<int?> version = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                required DateTime localUpdatedAt,
                Value<DateTime?> lastSyncedAt = const Value.absent(),
                Value<String?> syncError = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                required String id,
                required String locationId,
                required String equipmentTypeId,
                required String name,
                Value<String> brand = const Value.absent(),
                Value<String> model = const Value.absent(),
                Value<String?> serialNumber = const Value.absent(),
                Value<String> internalLocation = const Value.absent(),
                Value<String?> installedAt = const Value.absent(),
                Value<String?> cost = const Value.absent(),
                Value<String> notes = const Value.absent(),
                Value<DateTime?> createdAt = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalEquipmentsCompanion.insert(
                organizationId: organizationId,
                version: version,
                syncStatus: syncStatus,
                localUpdatedAt: localUpdatedAt,
                lastSyncedAt: lastSyncedAt,
                syncError: syncError,
                deleted: deleted,
                id: id,
                locationId: locationId,
                equipmentTypeId: equipmentTypeId,
                name: name,
                brand: brand,
                model: model,
                serialNumber: serialNumber,
                internalLocation: internalLocation,
                installedAt: installedAt,
                cost: cost,
                notes: notes,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LocalEquipmentsTable, LocalEquipment>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $LocalEquipmentsTable,
                    LocalEquipment
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalEquipmentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalEquipmentsTable,
      LocalEquipment,
      $$LocalEquipmentsTableFilterComposer,
      $$LocalEquipmentsTableOrderingComposer,
      $$LocalEquipmentsTableAnnotationComposer,
      $$LocalEquipmentsTableCreateCompanionBuilder,
      $$LocalEquipmentsTableUpdateCompanionBuilder,
      (
        LocalEquipment,
        BaseReferences<_$AppDatabase, $LocalEquipmentsTable, LocalEquipment>,
      ),
      LocalEquipment,
      PrefetchHooks Function()
    >;
typedef $$LocalServiceOrdersTableCreateCompanionBuilder =
    LocalServiceOrdersCompanion Function({
      required String organizationId,
      Value<int?> version,
      Value<String> syncStatus,
      required DateTime localUpdatedAt,
      Value<DateTime?> lastSyncedAt,
      Value<String?> syncError,
      Value<bool> deleted,
      required String id,
      required String clientId,
      Value<String?> locationId,
      Value<String?> equipmentId,
      Value<String?> serviceOrderTypeId,
      Value<String?> companyId,
      Value<String?> assignedUserId,
      Value<String> status,
      Value<String> reason,
      Value<String> diagnosis,
      Value<String> workPerformed,
      Value<String> recommendations,
      Value<String> finalCondition,
      Value<String> notes,
      Value<DateTime?> scheduledFor,
      Value<DateTime?> startedAt,
      Value<DateTime?> completedAt,
      Value<DateTime?> createdAt,
      Value<DateTime?> updatedAt,
      Value<int> rowid,
    });
typedef $$LocalServiceOrdersTableUpdateCompanionBuilder =
    LocalServiceOrdersCompanion Function({
      Value<String> organizationId,
      Value<int?> version,
      Value<String> syncStatus,
      Value<DateTime> localUpdatedAt,
      Value<DateTime?> lastSyncedAt,
      Value<String?> syncError,
      Value<bool> deleted,
      Value<String> id,
      Value<String> clientId,
      Value<String?> locationId,
      Value<String?> equipmentId,
      Value<String?> serviceOrderTypeId,
      Value<String?> companyId,
      Value<String?> assignedUserId,
      Value<String> status,
      Value<String> reason,
      Value<String> diagnosis,
      Value<String> workPerformed,
      Value<String> recommendations,
      Value<String> finalCondition,
      Value<String> notes,
      Value<DateTime?> scheduledFor,
      Value<DateTime?> startedAt,
      Value<DateTime?> completedAt,
      Value<DateTime?> createdAt,
      Value<DateTime?> updatedAt,
      Value<int> rowid,
    });

class $$LocalServiceOrdersTableFilterComposer
    extends Composer<_$AppDatabase, $LocalServiceOrdersTable> {
  $$LocalServiceOrdersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get organizationId => $composableBuilder(
    column: $table.organizationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get localUpdatedAt => $composableBuilder(
    column: $table.localUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncError => $composableBuilder(
    column: $table.syncError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get locationId => $composableBuilder(
    column: $table.locationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get equipmentId => $composableBuilder(
    column: $table.equipmentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serviceOrderTypeId => $composableBuilder(
    column: $table.serviceOrderTypeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get companyId => $composableBuilder(
    column: $table.companyId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get assignedUserId => $composableBuilder(
    column: $table.assignedUserId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get diagnosis => $composableBuilder(
    column: $table.diagnosis,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get workPerformed => $composableBuilder(
    column: $table.workPerformed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recommendations => $composableBuilder(
    column: $table.recommendations,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get finalCondition => $composableBuilder(
    column: $table.finalCondition,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get scheduledFor => $composableBuilder(
    column: $table.scheduledFor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalServiceOrdersTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalServiceOrdersTable> {
  $$LocalServiceOrdersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get organizationId => $composableBuilder(
    column: $table.organizationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get localUpdatedAt => $composableBuilder(
    column: $table.localUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncError => $composableBuilder(
    column: $table.syncError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get locationId => $composableBuilder(
    column: $table.locationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get equipmentId => $composableBuilder(
    column: $table.equipmentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serviceOrderTypeId => $composableBuilder(
    column: $table.serviceOrderTypeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get companyId => $composableBuilder(
    column: $table.companyId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get assignedUserId => $composableBuilder(
    column: $table.assignedUserId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get diagnosis => $composableBuilder(
    column: $table.diagnosis,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get workPerformed => $composableBuilder(
    column: $table.workPerformed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recommendations => $composableBuilder(
    column: $table.recommendations,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get finalCondition => $composableBuilder(
    column: $table.finalCondition,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get scheduledFor => $composableBuilder(
    column: $table.scheduledFor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalServiceOrdersTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalServiceOrdersTable> {
  $$LocalServiceOrdersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get organizationId => $composableBuilder(
    column: $table.organizationId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get localUpdatedAt => $composableBuilder(
    column: $table.localUpdatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncError =>
      $composableBuilder(column: $table.syncError, builder: (column) => column);

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get clientId =>
      $composableBuilder(column: $table.clientId, builder: (column) => column);

  GeneratedColumn<String> get locationId => $composableBuilder(
    column: $table.locationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get equipmentId => $composableBuilder(
    column: $table.equipmentId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get serviceOrderTypeId => $composableBuilder(
    column: $table.serviceOrderTypeId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get companyId =>
      $composableBuilder(column: $table.companyId, builder: (column) => column);

  GeneratedColumn<String> get assignedUserId => $composableBuilder(
    column: $table.assignedUserId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => column);

  GeneratedColumn<String> get diagnosis =>
      $composableBuilder(column: $table.diagnosis, builder: (column) => column);

  GeneratedColumn<String> get workPerformed => $composableBuilder(
    column: $table.workPerformed,
    builder: (column) => column,
  );

  GeneratedColumn<String> get recommendations => $composableBuilder(
    column: $table.recommendations,
    builder: (column) => column,
  );

  GeneratedColumn<String> get finalCondition => $composableBuilder(
    column: $table.finalCondition,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<DateTime> get scheduledFor => $composableBuilder(
    column: $table.scheduledFor,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$LocalServiceOrdersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalServiceOrdersTable,
          LocalServiceOrder,
          $$LocalServiceOrdersTableFilterComposer,
          $$LocalServiceOrdersTableOrderingComposer,
          $$LocalServiceOrdersTableAnnotationComposer,
          $$LocalServiceOrdersTableCreateCompanionBuilder,
          $$LocalServiceOrdersTableUpdateCompanionBuilder,
          (
            LocalServiceOrder,
            BaseReferences<
              _$AppDatabase,
              $LocalServiceOrdersTable,
              LocalServiceOrder
            >,
          ),
          LocalServiceOrder,
          PrefetchHooks Function()
        > {
  $$LocalServiceOrdersTableTableManager(
    _$AppDatabase db,
    $LocalServiceOrdersTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalServiceOrdersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalServiceOrdersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalServiceOrdersTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> organizationId = const Value.absent(),
                Value<int?> version = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<DateTime> localUpdatedAt = const Value.absent(),
                Value<DateTime?> lastSyncedAt = const Value.absent(),
                Value<String?> syncError = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<String> clientId = const Value.absent(),
                Value<String?> locationId = const Value.absent(),
                Value<String?> equipmentId = const Value.absent(),
                Value<String?> serviceOrderTypeId = const Value.absent(),
                Value<String?> companyId = const Value.absent(),
                Value<String?> assignedUserId = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> reason = const Value.absent(),
                Value<String> diagnosis = const Value.absent(),
                Value<String> workPerformed = const Value.absent(),
                Value<String> recommendations = const Value.absent(),
                Value<String> finalCondition = const Value.absent(),
                Value<String> notes = const Value.absent(),
                Value<DateTime?> scheduledFor = const Value.absent(),
                Value<DateTime?> startedAt = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<DateTime?> createdAt = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalServiceOrdersCompanion(
                organizationId: organizationId,
                version: version,
                syncStatus: syncStatus,
                localUpdatedAt: localUpdatedAt,
                lastSyncedAt: lastSyncedAt,
                syncError: syncError,
                deleted: deleted,
                id: id,
                clientId: clientId,
                locationId: locationId,
                equipmentId: equipmentId,
                serviceOrderTypeId: serviceOrderTypeId,
                companyId: companyId,
                assignedUserId: assignedUserId,
                status: status,
                reason: reason,
                diagnosis: diagnosis,
                workPerformed: workPerformed,
                recommendations: recommendations,
                finalCondition: finalCondition,
                notes: notes,
                scheduledFor: scheduledFor,
                startedAt: startedAt,
                completedAt: completedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String organizationId,
                Value<int?> version = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                required DateTime localUpdatedAt,
                Value<DateTime?> lastSyncedAt = const Value.absent(),
                Value<String?> syncError = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                required String id,
                required String clientId,
                Value<String?> locationId = const Value.absent(),
                Value<String?> equipmentId = const Value.absent(),
                Value<String?> serviceOrderTypeId = const Value.absent(),
                Value<String?> companyId = const Value.absent(),
                Value<String?> assignedUserId = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> reason = const Value.absent(),
                Value<String> diagnosis = const Value.absent(),
                Value<String> workPerformed = const Value.absent(),
                Value<String> recommendations = const Value.absent(),
                Value<String> finalCondition = const Value.absent(),
                Value<String> notes = const Value.absent(),
                Value<DateTime?> scheduledFor = const Value.absent(),
                Value<DateTime?> startedAt = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<DateTime?> createdAt = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalServiceOrdersCompanion.insert(
                organizationId: organizationId,
                version: version,
                syncStatus: syncStatus,
                localUpdatedAt: localUpdatedAt,
                lastSyncedAt: lastSyncedAt,
                syncError: syncError,
                deleted: deleted,
                id: id,
                clientId: clientId,
                locationId: locationId,
                equipmentId: equipmentId,
                serviceOrderTypeId: serviceOrderTypeId,
                companyId: companyId,
                assignedUserId: assignedUserId,
                status: status,
                reason: reason,
                diagnosis: diagnosis,
                workPerformed: workPerformed,
                recommendations: recommendations,
                finalCondition: finalCondition,
                notes: notes,
                scheduledFor: scheduledFor,
                startedAt: startedAt,
                completedAt: completedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LocalServiceOrdersTable, LocalServiceOrder>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $LocalServiceOrdersTable,
                    LocalServiceOrder
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalServiceOrdersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalServiceOrdersTable,
      LocalServiceOrder,
      $$LocalServiceOrdersTableFilterComposer,
      $$LocalServiceOrdersTableOrderingComposer,
      $$LocalServiceOrdersTableAnnotationComposer,
      $$LocalServiceOrdersTableCreateCompanionBuilder,
      $$LocalServiceOrdersTableUpdateCompanionBuilder,
      (
        LocalServiceOrder,
        BaseReferences<
          _$AppDatabase,
          $LocalServiceOrdersTable,
          LocalServiceOrder
        >,
      ),
      LocalServiceOrder,
      PrefetchHooks Function()
    >;
typedef $$LocalServiceOrderPartsTableCreateCompanionBuilder =
    LocalServiceOrderPartsCompanion Function({
      required String organizationId,
      Value<int?> version,
      Value<String> syncStatus,
      required DateTime localUpdatedAt,
      Value<DateTime?> lastSyncedAt,
      Value<String?> syncError,
      Value<bool> deleted,
      required String id,
      required String serviceOrderId,
      Value<String> description,
      Value<String> partNumber,
      Value<String> quantity,
      Value<String> unit,
      Value<String?> unitCost,
      Value<String?> unitPrice,
      Value<String> notes,
      Value<DateTime?> createdAt,
      Value<DateTime?> updatedAt,
      Value<int> rowid,
    });
typedef $$LocalServiceOrderPartsTableUpdateCompanionBuilder =
    LocalServiceOrderPartsCompanion Function({
      Value<String> organizationId,
      Value<int?> version,
      Value<String> syncStatus,
      Value<DateTime> localUpdatedAt,
      Value<DateTime?> lastSyncedAt,
      Value<String?> syncError,
      Value<bool> deleted,
      Value<String> id,
      Value<String> serviceOrderId,
      Value<String> description,
      Value<String> partNumber,
      Value<String> quantity,
      Value<String> unit,
      Value<String?> unitCost,
      Value<String?> unitPrice,
      Value<String> notes,
      Value<DateTime?> createdAt,
      Value<DateTime?> updatedAt,
      Value<int> rowid,
    });

class $$LocalServiceOrderPartsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalServiceOrderPartsTable> {
  $$LocalServiceOrderPartsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get organizationId => $composableBuilder(
    column: $table.organizationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get localUpdatedAt => $composableBuilder(
    column: $table.localUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncError => $composableBuilder(
    column: $table.syncError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serviceOrderId => $composableBuilder(
    column: $table.serviceOrderId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get partNumber => $composableBuilder(
    column: $table.partNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unitCost => $composableBuilder(
    column: $table.unitCost,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unitPrice => $composableBuilder(
    column: $table.unitPrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalServiceOrderPartsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalServiceOrderPartsTable> {
  $$LocalServiceOrderPartsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get organizationId => $composableBuilder(
    column: $table.organizationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get localUpdatedAt => $composableBuilder(
    column: $table.localUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncError => $composableBuilder(
    column: $table.syncError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serviceOrderId => $composableBuilder(
    column: $table.serviceOrderId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get partNumber => $composableBuilder(
    column: $table.partNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unitCost => $composableBuilder(
    column: $table.unitCost,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unitPrice => $composableBuilder(
    column: $table.unitPrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalServiceOrderPartsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalServiceOrderPartsTable> {
  $$LocalServiceOrderPartsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get organizationId => $composableBuilder(
    column: $table.organizationId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get localUpdatedAt => $composableBuilder(
    column: $table.localUpdatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncError =>
      $composableBuilder(column: $table.syncError, builder: (column) => column);

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get serviceOrderId => $composableBuilder(
    column: $table.serviceOrderId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get partNumber => $composableBuilder(
    column: $table.partNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<String> get unitCost =>
      $composableBuilder(column: $table.unitCost, builder: (column) => column);

  GeneratedColumn<String> get unitPrice =>
      $composableBuilder(column: $table.unitPrice, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$LocalServiceOrderPartsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalServiceOrderPartsTable,
          LocalServiceOrderPart,
          $$LocalServiceOrderPartsTableFilterComposer,
          $$LocalServiceOrderPartsTableOrderingComposer,
          $$LocalServiceOrderPartsTableAnnotationComposer,
          $$LocalServiceOrderPartsTableCreateCompanionBuilder,
          $$LocalServiceOrderPartsTableUpdateCompanionBuilder,
          (
            LocalServiceOrderPart,
            BaseReferences<
              _$AppDatabase,
              $LocalServiceOrderPartsTable,
              LocalServiceOrderPart
            >,
          ),
          LocalServiceOrderPart,
          PrefetchHooks Function()
        > {
  $$LocalServiceOrderPartsTableTableManager(
    _$AppDatabase db,
    $LocalServiceOrderPartsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalServiceOrderPartsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$LocalServiceOrderPartsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$LocalServiceOrderPartsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> organizationId = const Value.absent(),
                Value<int?> version = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<DateTime> localUpdatedAt = const Value.absent(),
                Value<DateTime?> lastSyncedAt = const Value.absent(),
                Value<String?> syncError = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<String> serviceOrderId = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<String> partNumber = const Value.absent(),
                Value<String> quantity = const Value.absent(),
                Value<String> unit = const Value.absent(),
                Value<String?> unitCost = const Value.absent(),
                Value<String?> unitPrice = const Value.absent(),
                Value<String> notes = const Value.absent(),
                Value<DateTime?> createdAt = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalServiceOrderPartsCompanion(
                organizationId: organizationId,
                version: version,
                syncStatus: syncStatus,
                localUpdatedAt: localUpdatedAt,
                lastSyncedAt: lastSyncedAt,
                syncError: syncError,
                deleted: deleted,
                id: id,
                serviceOrderId: serviceOrderId,
                description: description,
                partNumber: partNumber,
                quantity: quantity,
                unit: unit,
                unitCost: unitCost,
                unitPrice: unitPrice,
                notes: notes,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String organizationId,
                Value<int?> version = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                required DateTime localUpdatedAt,
                Value<DateTime?> lastSyncedAt = const Value.absent(),
                Value<String?> syncError = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                required String id,
                required String serviceOrderId,
                Value<String> description = const Value.absent(),
                Value<String> partNumber = const Value.absent(),
                Value<String> quantity = const Value.absent(),
                Value<String> unit = const Value.absent(),
                Value<String?> unitCost = const Value.absent(),
                Value<String?> unitPrice = const Value.absent(),
                Value<String> notes = const Value.absent(),
                Value<DateTime?> createdAt = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalServiceOrderPartsCompanion.insert(
                organizationId: organizationId,
                version: version,
                syncStatus: syncStatus,
                localUpdatedAt: localUpdatedAt,
                lastSyncedAt: lastSyncedAt,
                syncError: syncError,
                deleted: deleted,
                id: id,
                serviceOrderId: serviceOrderId,
                description: description,
                partNumber: partNumber,
                quantity: quantity,
                unit: unit,
                unitCost: unitCost,
                unitPrice: unitPrice,
                notes: notes,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $LocalServiceOrderPartsTable,
                    LocalServiceOrderPart
                  >(table),
                  BaseReferences<
                    _$AppDatabase,
                    $LocalServiceOrderPartsTable,
                    LocalServiceOrderPart
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalServiceOrderPartsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalServiceOrderPartsTable,
      LocalServiceOrderPart,
      $$LocalServiceOrderPartsTableFilterComposer,
      $$LocalServiceOrderPartsTableOrderingComposer,
      $$LocalServiceOrderPartsTableAnnotationComposer,
      $$LocalServiceOrderPartsTableCreateCompanionBuilder,
      $$LocalServiceOrderPartsTableUpdateCompanionBuilder,
      (
        LocalServiceOrderPart,
        BaseReferences<
          _$AppDatabase,
          $LocalServiceOrderPartsTable,
          LocalServiceOrderPart
        >,
      ),
      LocalServiceOrderPart,
      PrefetchHooks Function()
    >;
typedef $$LocalEquipmentTypesTableCreateCompanionBuilder =
    LocalEquipmentTypesCompanion Function({
      required String id,
      required String organizationId,
      required String name,
      Value<String> description,
      Value<int?> version,
      required DateTime cachedAt,
      Value<int> rowid,
    });
typedef $$LocalEquipmentTypesTableUpdateCompanionBuilder =
    LocalEquipmentTypesCompanion Function({
      Value<String> id,
      Value<String> organizationId,
      Value<String> name,
      Value<String> description,
      Value<int?> version,
      Value<DateTime> cachedAt,
      Value<int> rowid,
    });

class $$LocalEquipmentTypesTableFilterComposer
    extends Composer<_$AppDatabase, $LocalEquipmentTypesTable> {
  $$LocalEquipmentTypesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get organizationId => $composableBuilder(
    column: $table.organizationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalEquipmentTypesTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalEquipmentTypesTable> {
  $$LocalEquipmentTypesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get organizationId => $composableBuilder(
    column: $table.organizationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalEquipmentTypesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalEquipmentTypesTable> {
  $$LocalEquipmentTypesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get organizationId => $composableBuilder(
    column: $table.organizationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$LocalEquipmentTypesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalEquipmentTypesTable,
          LocalEquipmentType,
          $$LocalEquipmentTypesTableFilterComposer,
          $$LocalEquipmentTypesTableOrderingComposer,
          $$LocalEquipmentTypesTableAnnotationComposer,
          $$LocalEquipmentTypesTableCreateCompanionBuilder,
          $$LocalEquipmentTypesTableUpdateCompanionBuilder,
          (
            LocalEquipmentType,
            BaseReferences<
              _$AppDatabase,
              $LocalEquipmentTypesTable,
              LocalEquipmentType
            >,
          ),
          LocalEquipmentType,
          PrefetchHooks Function()
        > {
  $$LocalEquipmentTypesTableTableManager(
    _$AppDatabase db,
    $LocalEquipmentTypesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalEquipmentTypesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalEquipmentTypesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$LocalEquipmentTypesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> organizationId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<int?> version = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalEquipmentTypesCompanion(
                id: id,
                organizationId: organizationId,
                name: name,
                description: description,
                version: version,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String organizationId,
                required String name,
                Value<String> description = const Value.absent(),
                Value<int?> version = const Value.absent(),
                required DateTime cachedAt,
                Value<int> rowid = const Value.absent(),
              }) => LocalEquipmentTypesCompanion.insert(
                id: id,
                organizationId: organizationId,
                name: name,
                description: description,
                version: version,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LocalEquipmentTypesTable, LocalEquipmentType>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $LocalEquipmentTypesTable,
                    LocalEquipmentType
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalEquipmentTypesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalEquipmentTypesTable,
      LocalEquipmentType,
      $$LocalEquipmentTypesTableFilterComposer,
      $$LocalEquipmentTypesTableOrderingComposer,
      $$LocalEquipmentTypesTableAnnotationComposer,
      $$LocalEquipmentTypesTableCreateCompanionBuilder,
      $$LocalEquipmentTypesTableUpdateCompanionBuilder,
      (
        LocalEquipmentType,
        BaseReferences<
          _$AppDatabase,
          $LocalEquipmentTypesTable,
          LocalEquipmentType
        >,
      ),
      LocalEquipmentType,
      PrefetchHooks Function()
    >;
typedef $$LocalReferenceDataTableCreateCompanionBuilder =
    LocalReferenceDataCompanion Function({
      required String kind,
      required String id,
      required String organizationId,
      required String label,
      Value<String> subtitle,
      required DateTime cachedAt,
      Value<int> rowid,
    });
typedef $$LocalReferenceDataTableUpdateCompanionBuilder =
    LocalReferenceDataCompanion Function({
      Value<String> kind,
      Value<String> id,
      Value<String> organizationId,
      Value<String> label,
      Value<String> subtitle,
      Value<DateTime> cachedAt,
      Value<int> rowid,
    });

class $$LocalReferenceDataTableFilterComposer
    extends Composer<_$AppDatabase, $LocalReferenceDataTable> {
  $$LocalReferenceDataTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get organizationId => $composableBuilder(
    column: $table.organizationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subtitle => $composableBuilder(
    column: $table.subtitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalReferenceDataTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalReferenceDataTable> {
  $$LocalReferenceDataTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get organizationId => $composableBuilder(
    column: $table.organizationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subtitle => $composableBuilder(
    column: $table.subtitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalReferenceDataTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalReferenceDataTable> {
  $$LocalReferenceDataTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get organizationId => $composableBuilder(
    column: $table.organizationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<String> get subtitle =>
      $composableBuilder(column: $table.subtitle, builder: (column) => column);

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$LocalReferenceDataTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalReferenceDataTable,
          LocalReferenceDataData,
          $$LocalReferenceDataTableFilterComposer,
          $$LocalReferenceDataTableOrderingComposer,
          $$LocalReferenceDataTableAnnotationComposer,
          $$LocalReferenceDataTableCreateCompanionBuilder,
          $$LocalReferenceDataTableUpdateCompanionBuilder,
          (
            LocalReferenceDataData,
            BaseReferences<
              _$AppDatabase,
              $LocalReferenceDataTable,
              LocalReferenceDataData
            >,
          ),
          LocalReferenceDataData,
          PrefetchHooks Function()
        > {
  $$LocalReferenceDataTableTableManager(
    _$AppDatabase db,
    $LocalReferenceDataTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalReferenceDataTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalReferenceDataTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalReferenceDataTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> kind = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<String> organizationId = const Value.absent(),
                Value<String> label = const Value.absent(),
                Value<String> subtitle = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalReferenceDataCompanion(
                kind: kind,
                id: id,
                organizationId: organizationId,
                label: label,
                subtitle: subtitle,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String kind,
                required String id,
                required String organizationId,
                required String label,
                Value<String> subtitle = const Value.absent(),
                required DateTime cachedAt,
                Value<int> rowid = const Value.absent(),
              }) => LocalReferenceDataCompanion.insert(
                kind: kind,
                id: id,
                organizationId: organizationId,
                label: label,
                subtitle: subtitle,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LocalReferenceDataTable, LocalReferenceDataData>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $LocalReferenceDataTable,
                    LocalReferenceDataData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalReferenceDataTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalReferenceDataTable,
      LocalReferenceDataData,
      $$LocalReferenceDataTableFilterComposer,
      $$LocalReferenceDataTableOrderingComposer,
      $$LocalReferenceDataTableAnnotationComposer,
      $$LocalReferenceDataTableCreateCompanionBuilder,
      $$LocalReferenceDataTableUpdateCompanionBuilder,
      (
        LocalReferenceDataData,
        BaseReferences<
          _$AppDatabase,
          $LocalReferenceDataTable,
          LocalReferenceDataData
        >,
      ),
      LocalReferenceDataData,
      PrefetchHooks Function()
    >;
typedef $$LocalQrCodesTableCreateCompanionBuilder =
    LocalQrCodesCompanion Function({
      required String organizationId,
      Value<int?> version,
      Value<String> syncStatus,
      required DateTime localUpdatedAt,
      Value<DateTime?> lastSyncedAt,
      Value<String?> syncError,
      Value<bool> deleted,
      required String id,
      Value<String?> publicCode,
      required String status,
      Value<String?> batchId,
      Value<String?> clientId,
      Value<String?> locationId,
      Value<String?> equipmentId,
      Value<DateTime?> assignedAt,
      Value<DateTime?> createdAt,
      Value<int> rowid,
    });
typedef $$LocalQrCodesTableUpdateCompanionBuilder =
    LocalQrCodesCompanion Function({
      Value<String> organizationId,
      Value<int?> version,
      Value<String> syncStatus,
      Value<DateTime> localUpdatedAt,
      Value<DateTime?> lastSyncedAt,
      Value<String?> syncError,
      Value<bool> deleted,
      Value<String> id,
      Value<String?> publicCode,
      Value<String> status,
      Value<String?> batchId,
      Value<String?> clientId,
      Value<String?> locationId,
      Value<String?> equipmentId,
      Value<DateTime?> assignedAt,
      Value<DateTime?> createdAt,
      Value<int> rowid,
    });

class $$LocalQrCodesTableFilterComposer
    extends Composer<_$AppDatabase, $LocalQrCodesTable> {
  $$LocalQrCodesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get organizationId => $composableBuilder(
    column: $table.organizationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get localUpdatedAt => $composableBuilder(
    column: $table.localUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncError => $composableBuilder(
    column: $table.syncError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get publicCode => $composableBuilder(
    column: $table.publicCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get batchId => $composableBuilder(
    column: $table.batchId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get locationId => $composableBuilder(
    column: $table.locationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get equipmentId => $composableBuilder(
    column: $table.equipmentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get assignedAt => $composableBuilder(
    column: $table.assignedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalQrCodesTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalQrCodesTable> {
  $$LocalQrCodesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get organizationId => $composableBuilder(
    column: $table.organizationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get localUpdatedAt => $composableBuilder(
    column: $table.localUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncError => $composableBuilder(
    column: $table.syncError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get publicCode => $composableBuilder(
    column: $table.publicCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get batchId => $composableBuilder(
    column: $table.batchId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get locationId => $composableBuilder(
    column: $table.locationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get equipmentId => $composableBuilder(
    column: $table.equipmentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get assignedAt => $composableBuilder(
    column: $table.assignedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalQrCodesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalQrCodesTable> {
  $$LocalQrCodesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get organizationId => $composableBuilder(
    column: $table.organizationId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get localUpdatedAt => $composableBuilder(
    column: $table.localUpdatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncError =>
      $composableBuilder(column: $table.syncError, builder: (column) => column);

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get publicCode => $composableBuilder(
    column: $table.publicCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get batchId =>
      $composableBuilder(column: $table.batchId, builder: (column) => column);

  GeneratedColumn<String> get clientId =>
      $composableBuilder(column: $table.clientId, builder: (column) => column);

  GeneratedColumn<String> get locationId => $composableBuilder(
    column: $table.locationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get equipmentId => $composableBuilder(
    column: $table.equipmentId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get assignedAt => $composableBuilder(
    column: $table.assignedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$LocalQrCodesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalQrCodesTable,
          LocalQrCode,
          $$LocalQrCodesTableFilterComposer,
          $$LocalQrCodesTableOrderingComposer,
          $$LocalQrCodesTableAnnotationComposer,
          $$LocalQrCodesTableCreateCompanionBuilder,
          $$LocalQrCodesTableUpdateCompanionBuilder,
          (
            LocalQrCode,
            BaseReferences<_$AppDatabase, $LocalQrCodesTable, LocalQrCode>,
          ),
          LocalQrCode,
          PrefetchHooks Function()
        > {
  $$LocalQrCodesTableTableManager(_$AppDatabase db, $LocalQrCodesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalQrCodesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalQrCodesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalQrCodesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> organizationId = const Value.absent(),
                Value<int?> version = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<DateTime> localUpdatedAt = const Value.absent(),
                Value<DateTime?> lastSyncedAt = const Value.absent(),
                Value<String?> syncError = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<String?> publicCode = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> batchId = const Value.absent(),
                Value<String?> clientId = const Value.absent(),
                Value<String?> locationId = const Value.absent(),
                Value<String?> equipmentId = const Value.absent(),
                Value<DateTime?> assignedAt = const Value.absent(),
                Value<DateTime?> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalQrCodesCompanion(
                organizationId: organizationId,
                version: version,
                syncStatus: syncStatus,
                localUpdatedAt: localUpdatedAt,
                lastSyncedAt: lastSyncedAt,
                syncError: syncError,
                deleted: deleted,
                id: id,
                publicCode: publicCode,
                status: status,
                batchId: batchId,
                clientId: clientId,
                locationId: locationId,
                equipmentId: equipmentId,
                assignedAt: assignedAt,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String organizationId,
                Value<int?> version = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                required DateTime localUpdatedAt,
                Value<DateTime?> lastSyncedAt = const Value.absent(),
                Value<String?> syncError = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                required String id,
                Value<String?> publicCode = const Value.absent(),
                required String status,
                Value<String?> batchId = const Value.absent(),
                Value<String?> clientId = const Value.absent(),
                Value<String?> locationId = const Value.absent(),
                Value<String?> equipmentId = const Value.absent(),
                Value<DateTime?> assignedAt = const Value.absent(),
                Value<DateTime?> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalQrCodesCompanion.insert(
                organizationId: organizationId,
                version: version,
                syncStatus: syncStatus,
                localUpdatedAt: localUpdatedAt,
                lastSyncedAt: lastSyncedAt,
                syncError: syncError,
                deleted: deleted,
                id: id,
                publicCode: publicCode,
                status: status,
                batchId: batchId,
                clientId: clientId,
                locationId: locationId,
                equipmentId: equipmentId,
                assignedAt: assignedAt,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LocalQrCodesTable, LocalQrCode>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $LocalQrCodesTable,
                    LocalQrCode
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalQrCodesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalQrCodesTable,
      LocalQrCode,
      $$LocalQrCodesTableFilterComposer,
      $$LocalQrCodesTableOrderingComposer,
      $$LocalQrCodesTableAnnotationComposer,
      $$LocalQrCodesTableCreateCompanionBuilder,
      $$LocalQrCodesTableUpdateCompanionBuilder,
      (
        LocalQrCode,
        BaseReferences<_$AppDatabase, $LocalQrCodesTable, LocalQrCode>,
      ),
      LocalQrCode,
      PrefetchHooks Function()
    >;
typedef $$LocalQrBatchesTableCreateCompanionBuilder =
    LocalQrBatchesCompanion Function({
      required String organizationId,
      Value<int?> version,
      Value<String> syncStatus,
      required DateTime localUpdatedAt,
      Value<DateTime?> lastSyncedAt,
      Value<String?> syncError,
      Value<bool> deleted,
      required String id,
      Value<String> label,
      Value<int> quantity,
      required String status,
      Value<String?> reservedUserId,
      Value<String?> reservedDeviceId,
      Value<int> exportCount,
      Value<DateTime?> createdAt,
      Value<int> rowid,
    });
typedef $$LocalQrBatchesTableUpdateCompanionBuilder =
    LocalQrBatchesCompanion Function({
      Value<String> organizationId,
      Value<int?> version,
      Value<String> syncStatus,
      Value<DateTime> localUpdatedAt,
      Value<DateTime?> lastSyncedAt,
      Value<String?> syncError,
      Value<bool> deleted,
      Value<String> id,
      Value<String> label,
      Value<int> quantity,
      Value<String> status,
      Value<String?> reservedUserId,
      Value<String?> reservedDeviceId,
      Value<int> exportCount,
      Value<DateTime?> createdAt,
      Value<int> rowid,
    });

class $$LocalQrBatchesTableFilterComposer
    extends Composer<_$AppDatabase, $LocalQrBatchesTable> {
  $$LocalQrBatchesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get organizationId => $composableBuilder(
    column: $table.organizationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get localUpdatedAt => $composableBuilder(
    column: $table.localUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncError => $composableBuilder(
    column: $table.syncError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reservedUserId => $composableBuilder(
    column: $table.reservedUserId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reservedDeviceId => $composableBuilder(
    column: $table.reservedDeviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get exportCount => $composableBuilder(
    column: $table.exportCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalQrBatchesTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalQrBatchesTable> {
  $$LocalQrBatchesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get organizationId => $composableBuilder(
    column: $table.organizationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get localUpdatedAt => $composableBuilder(
    column: $table.localUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncError => $composableBuilder(
    column: $table.syncError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reservedUserId => $composableBuilder(
    column: $table.reservedUserId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reservedDeviceId => $composableBuilder(
    column: $table.reservedDeviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get exportCount => $composableBuilder(
    column: $table.exportCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalQrBatchesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalQrBatchesTable> {
  $$LocalQrBatchesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get organizationId => $composableBuilder(
    column: $table.organizationId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get localUpdatedAt => $composableBuilder(
    column: $table.localUpdatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncError =>
      $composableBuilder(column: $table.syncError, builder: (column) => column);

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<int> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get reservedUserId => $composableBuilder(
    column: $table.reservedUserId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reservedDeviceId => $composableBuilder(
    column: $table.reservedDeviceId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get exportCount => $composableBuilder(
    column: $table.exportCount,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$LocalQrBatchesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalQrBatchesTable,
          LocalQrBatch,
          $$LocalQrBatchesTableFilterComposer,
          $$LocalQrBatchesTableOrderingComposer,
          $$LocalQrBatchesTableAnnotationComposer,
          $$LocalQrBatchesTableCreateCompanionBuilder,
          $$LocalQrBatchesTableUpdateCompanionBuilder,
          (
            LocalQrBatch,
            BaseReferences<_$AppDatabase, $LocalQrBatchesTable, LocalQrBatch>,
          ),
          LocalQrBatch,
          PrefetchHooks Function()
        > {
  $$LocalQrBatchesTableTableManager(
    _$AppDatabase db,
    $LocalQrBatchesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalQrBatchesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalQrBatchesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalQrBatchesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> organizationId = const Value.absent(),
                Value<int?> version = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<DateTime> localUpdatedAt = const Value.absent(),
                Value<DateTime?> lastSyncedAt = const Value.absent(),
                Value<String?> syncError = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<String> label = const Value.absent(),
                Value<int> quantity = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> reservedUserId = const Value.absent(),
                Value<String?> reservedDeviceId = const Value.absent(),
                Value<int> exportCount = const Value.absent(),
                Value<DateTime?> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalQrBatchesCompanion(
                organizationId: organizationId,
                version: version,
                syncStatus: syncStatus,
                localUpdatedAt: localUpdatedAt,
                lastSyncedAt: lastSyncedAt,
                syncError: syncError,
                deleted: deleted,
                id: id,
                label: label,
                quantity: quantity,
                status: status,
                reservedUserId: reservedUserId,
                reservedDeviceId: reservedDeviceId,
                exportCount: exportCount,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String organizationId,
                Value<int?> version = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                required DateTime localUpdatedAt,
                Value<DateTime?> lastSyncedAt = const Value.absent(),
                Value<String?> syncError = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                required String id,
                Value<String> label = const Value.absent(),
                Value<int> quantity = const Value.absent(),
                required String status,
                Value<String?> reservedUserId = const Value.absent(),
                Value<String?> reservedDeviceId = const Value.absent(),
                Value<int> exportCount = const Value.absent(),
                Value<DateTime?> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalQrBatchesCompanion.insert(
                organizationId: organizationId,
                version: version,
                syncStatus: syncStatus,
                localUpdatedAt: localUpdatedAt,
                lastSyncedAt: lastSyncedAt,
                syncError: syncError,
                deleted: deleted,
                id: id,
                label: label,
                quantity: quantity,
                status: status,
                reservedUserId: reservedUserId,
                reservedDeviceId: reservedDeviceId,
                exportCount: exportCount,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LocalQrBatchesTable, LocalQrBatch>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $LocalQrBatchesTable,
                    LocalQrBatch
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalQrBatchesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalQrBatchesTable,
      LocalQrBatch,
      $$LocalQrBatchesTableFilterComposer,
      $$LocalQrBatchesTableOrderingComposer,
      $$LocalQrBatchesTableAnnotationComposer,
      $$LocalQrBatchesTableCreateCompanionBuilder,
      $$LocalQrBatchesTableUpdateCompanionBuilder,
      (
        LocalQrBatch,
        BaseReferences<_$AppDatabase, $LocalQrBatchesTable, LocalQrBatch>,
      ),
      LocalQrBatch,
      PrefetchHooks Function()
    >;
typedef $$SyncOutboxTableCreateCompanionBuilder =
    SyncOutboxCompanion Function({
      required String operationId,
      required String organizationId,
      required String entityType,
      required String entityId,
      required String operationType,
      required String payload,
      Value<int?> baseVersion,
      required DateTime occurredAt,
      Value<int> attempts,
      Value<String?> lastError,
      Value<int> rowid,
    });
typedef $$SyncOutboxTableUpdateCompanionBuilder =
    SyncOutboxCompanion Function({
      Value<String> operationId,
      Value<String> organizationId,
      Value<String> entityType,
      Value<String> entityId,
      Value<String> operationType,
      Value<String> payload,
      Value<int?> baseVersion,
      Value<DateTime> occurredAt,
      Value<int> attempts,
      Value<String?> lastError,
      Value<int> rowid,
    });

class $$SyncOutboxTableFilterComposer
    extends Composer<_$AppDatabase, $SyncOutboxTable> {
  $$SyncOutboxTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get operationId => $composableBuilder(
    column: $table.operationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get organizationId => $composableBuilder(
    column: $table.organizationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get operationType => $composableBuilder(
    column: $table.operationType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get baseVersion => $composableBuilder(
    column: $table.baseVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncOutboxTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncOutboxTable> {
  $$SyncOutboxTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get operationId => $composableBuilder(
    column: $table.operationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get organizationId => $composableBuilder(
    column: $table.organizationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get operationType => $composableBuilder(
    column: $table.operationType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get baseVersion => $composableBuilder(
    column: $table.baseVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncOutboxTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncOutboxTable> {
  $$SyncOutboxTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get operationId => $composableBuilder(
    column: $table.operationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get organizationId => $composableBuilder(
    column: $table.organizationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get operationType => $composableBuilder(
    column: $table.operationType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<int> get baseVersion => $composableBuilder(
    column: $table.baseVersion,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);
}

class $$SyncOutboxTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncOutboxTable,
          SyncOutboxData,
          $$SyncOutboxTableFilterComposer,
          $$SyncOutboxTableOrderingComposer,
          $$SyncOutboxTableAnnotationComposer,
          $$SyncOutboxTableCreateCompanionBuilder,
          $$SyncOutboxTableUpdateCompanionBuilder,
          (
            SyncOutboxData,
            BaseReferences<_$AppDatabase, $SyncOutboxTable, SyncOutboxData>,
          ),
          SyncOutboxData,
          PrefetchHooks Function()
        > {
  $$SyncOutboxTableTableManager(_$AppDatabase db, $SyncOutboxTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncOutboxTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncOutboxTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncOutboxTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> operationId = const Value.absent(),
                Value<String> organizationId = const Value.absent(),
                Value<String> entityType = const Value.absent(),
                Value<String> entityId = const Value.absent(),
                Value<String> operationType = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<int?> baseVersion = const Value.absent(),
                Value<DateTime> occurredAt = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncOutboxCompanion(
                operationId: operationId,
                organizationId: organizationId,
                entityType: entityType,
                entityId: entityId,
                operationType: operationType,
                payload: payload,
                baseVersion: baseVersion,
                occurredAt: occurredAt,
                attempts: attempts,
                lastError: lastError,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String operationId,
                required String organizationId,
                required String entityType,
                required String entityId,
                required String operationType,
                required String payload,
                Value<int?> baseVersion = const Value.absent(),
                required DateTime occurredAt,
                Value<int> attempts = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncOutboxCompanion.insert(
                operationId: operationId,
                organizationId: organizationId,
                entityType: entityType,
                entityId: entityId,
                operationType: operationType,
                payload: payload,
                baseVersion: baseVersion,
                occurredAt: occurredAt,
                attempts: attempts,
                lastError: lastError,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SyncOutboxTable, SyncOutboxData>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $SyncOutboxTable,
                    SyncOutboxData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncOutboxTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncOutboxTable,
      SyncOutboxData,
      $$SyncOutboxTableFilterComposer,
      $$SyncOutboxTableOrderingComposer,
      $$SyncOutboxTableAnnotationComposer,
      $$SyncOutboxTableCreateCompanionBuilder,
      $$SyncOutboxTableUpdateCompanionBuilder,
      (
        SyncOutboxData,
        BaseReferences<_$AppDatabase, $SyncOutboxTable, SyncOutboxData>,
      ),
      SyncOutboxData,
      PrefetchHooks Function()
    >;
typedef $$LocalSyncStateTableCreateCompanionBuilder =
    LocalSyncStateCompanion Function({
      required String organizationId,
      Value<int> cursor,
      Value<int> rowid,
    });
typedef $$LocalSyncStateTableUpdateCompanionBuilder =
    LocalSyncStateCompanion Function({
      Value<String> organizationId,
      Value<int> cursor,
      Value<int> rowid,
    });

class $$LocalSyncStateTableFilterComposer
    extends Composer<_$AppDatabase, $LocalSyncStateTable> {
  $$LocalSyncStateTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get organizationId => $composableBuilder(
    column: $table.organizationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cursor => $composableBuilder(
    column: $table.cursor,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalSyncStateTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalSyncStateTable> {
  $$LocalSyncStateTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get organizationId => $composableBuilder(
    column: $table.organizationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cursor => $composableBuilder(
    column: $table.cursor,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalSyncStateTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalSyncStateTable> {
  $$LocalSyncStateTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get organizationId => $composableBuilder(
    column: $table.organizationId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get cursor =>
      $composableBuilder(column: $table.cursor, builder: (column) => column);
}

class $$LocalSyncStateTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalSyncStateTable,
          LocalSyncStateData,
          $$LocalSyncStateTableFilterComposer,
          $$LocalSyncStateTableOrderingComposer,
          $$LocalSyncStateTableAnnotationComposer,
          $$LocalSyncStateTableCreateCompanionBuilder,
          $$LocalSyncStateTableUpdateCompanionBuilder,
          (
            LocalSyncStateData,
            BaseReferences<
              _$AppDatabase,
              $LocalSyncStateTable,
              LocalSyncStateData
            >,
          ),
          LocalSyncStateData,
          PrefetchHooks Function()
        > {
  $$LocalSyncStateTableTableManager(
    _$AppDatabase db,
    $LocalSyncStateTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalSyncStateTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalSyncStateTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalSyncStateTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> organizationId = const Value.absent(),
                Value<int> cursor = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalSyncStateCompanion(
                organizationId: organizationId,
                cursor: cursor,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String organizationId,
                Value<int> cursor = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalSyncStateCompanion.insert(
                organizationId: organizationId,
                cursor: cursor,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LocalSyncStateTable, LocalSyncStateData>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $LocalSyncStateTable,
                    LocalSyncStateData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalSyncStateTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalSyncStateTable,
      LocalSyncStateData,
      $$LocalSyncStateTableFilterComposer,
      $$LocalSyncStateTableOrderingComposer,
      $$LocalSyncStateTableAnnotationComposer,
      $$LocalSyncStateTableCreateCompanionBuilder,
      $$LocalSyncStateTableUpdateCompanionBuilder,
      (
        LocalSyncStateData,
        BaseReferences<_$AppDatabase, $LocalSyncStateTable, LocalSyncStateData>,
      ),
      LocalSyncStateData,
      PrefetchHooks Function()
    >;
typedef $$UploadQueueTableCreateCompanionBuilder =
    UploadQueueCompanion Function({
      required String id,
      required String organizationId,
      required String serviceOrderId,
      required String kind,
      required String filePath,
      required String sha256,
      Value<String?> photoKind,
      Value<String?> caption,
      required DateTime createdAt,
      Value<int> attempts,
      Value<String?> lastError,
      Value<int> rowid,
    });
typedef $$UploadQueueTableUpdateCompanionBuilder =
    UploadQueueCompanion Function({
      Value<String> id,
      Value<String> organizationId,
      Value<String> serviceOrderId,
      Value<String> kind,
      Value<String> filePath,
      Value<String> sha256,
      Value<String?> photoKind,
      Value<String?> caption,
      Value<DateTime> createdAt,
      Value<int> attempts,
      Value<String?> lastError,
      Value<int> rowid,
    });

class $$UploadQueueTableFilterComposer
    extends Composer<_$AppDatabase, $UploadQueueTable> {
  $$UploadQueueTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get organizationId => $composableBuilder(
    column: $table.organizationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serviceOrderId => $composableBuilder(
    column: $table.serviceOrderId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sha256 => $composableBuilder(
    column: $table.sha256,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get photoKind => $composableBuilder(
    column: $table.photoKind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get caption => $composableBuilder(
    column: $table.caption,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UploadQueueTableOrderingComposer
    extends Composer<_$AppDatabase, $UploadQueueTable> {
  $$UploadQueueTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get organizationId => $composableBuilder(
    column: $table.organizationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serviceOrderId => $composableBuilder(
    column: $table.serviceOrderId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sha256 => $composableBuilder(
    column: $table.sha256,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get photoKind => $composableBuilder(
    column: $table.photoKind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get caption => $composableBuilder(
    column: $table.caption,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UploadQueueTableAnnotationComposer
    extends Composer<_$AppDatabase, $UploadQueueTable> {
  $$UploadQueueTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get organizationId => $composableBuilder(
    column: $table.organizationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get serviceOrderId => $composableBuilder(
    column: $table.serviceOrderId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get filePath =>
      $composableBuilder(column: $table.filePath, builder: (column) => column);

  GeneratedColumn<String> get sha256 =>
      $composableBuilder(column: $table.sha256, builder: (column) => column);

  GeneratedColumn<String> get photoKind =>
      $composableBuilder(column: $table.photoKind, builder: (column) => column);

  GeneratedColumn<String> get caption =>
      $composableBuilder(column: $table.caption, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);
}

class $$UploadQueueTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UploadQueueTable,
          UploadQueueData,
          $$UploadQueueTableFilterComposer,
          $$UploadQueueTableOrderingComposer,
          $$UploadQueueTableAnnotationComposer,
          $$UploadQueueTableCreateCompanionBuilder,
          $$UploadQueueTableUpdateCompanionBuilder,
          (
            UploadQueueData,
            BaseReferences<_$AppDatabase, $UploadQueueTable, UploadQueueData>,
          ),
          UploadQueueData,
          PrefetchHooks Function()
        > {
  $$UploadQueueTableTableManager(_$AppDatabase db, $UploadQueueTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UploadQueueTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UploadQueueTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UploadQueueTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> organizationId = const Value.absent(),
                Value<String> serviceOrderId = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> filePath = const Value.absent(),
                Value<String> sha256 = const Value.absent(),
                Value<String?> photoKind = const Value.absent(),
                Value<String?> caption = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UploadQueueCompanion(
                id: id,
                organizationId: organizationId,
                serviceOrderId: serviceOrderId,
                kind: kind,
                filePath: filePath,
                sha256: sha256,
                photoKind: photoKind,
                caption: caption,
                createdAt: createdAt,
                attempts: attempts,
                lastError: lastError,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String organizationId,
                required String serviceOrderId,
                required String kind,
                required String filePath,
                required String sha256,
                Value<String?> photoKind = const Value.absent(),
                Value<String?> caption = const Value.absent(),
                required DateTime createdAt,
                Value<int> attempts = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UploadQueueCompanion.insert(
                id: id,
                organizationId: organizationId,
                serviceOrderId: serviceOrderId,
                kind: kind,
                filePath: filePath,
                sha256: sha256,
                photoKind: photoKind,
                caption: caption,
                createdAt: createdAt,
                attempts: attempts,
                lastError: lastError,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$UploadQueueTable, UploadQueueData>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $UploadQueueTable,
                    UploadQueueData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UploadQueueTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UploadQueueTable,
      UploadQueueData,
      $$UploadQueueTableFilterComposer,
      $$UploadQueueTableOrderingComposer,
      $$UploadQueueTableAnnotationComposer,
      $$UploadQueueTableCreateCompanionBuilder,
      $$UploadQueueTableUpdateCompanionBuilder,
      (
        UploadQueueData,
        BaseReferences<_$AppDatabase, $UploadQueueTable, UploadQueueData>,
      ),
      UploadQueueData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$LocalClientsTableTableManager get localClients =>
      $$LocalClientsTableTableManager(_db, _db.localClients);
  $$LocalLocationsTableTableManager get localLocations =>
      $$LocalLocationsTableTableManager(_db, _db.localLocations);
  $$LocalEquipmentsTableTableManager get localEquipments =>
      $$LocalEquipmentsTableTableManager(_db, _db.localEquipments);
  $$LocalServiceOrdersTableTableManager get localServiceOrders =>
      $$LocalServiceOrdersTableTableManager(_db, _db.localServiceOrders);
  $$LocalServiceOrderPartsTableTableManager get localServiceOrderParts =>
      $$LocalServiceOrderPartsTableTableManager(
        _db,
        _db.localServiceOrderParts,
      );
  $$LocalEquipmentTypesTableTableManager get localEquipmentTypes =>
      $$LocalEquipmentTypesTableTableManager(_db, _db.localEquipmentTypes);
  $$LocalReferenceDataTableTableManager get localReferenceData =>
      $$LocalReferenceDataTableTableManager(_db, _db.localReferenceData);
  $$LocalQrCodesTableTableManager get localQrCodes =>
      $$LocalQrCodesTableTableManager(_db, _db.localQrCodes);
  $$LocalQrBatchesTableTableManager get localQrBatches =>
      $$LocalQrBatchesTableTableManager(_db, _db.localQrBatches);
  $$SyncOutboxTableTableManager get syncOutbox =>
      $$SyncOutboxTableTableManager(_db, _db.syncOutbox);
  $$LocalSyncStateTableTableManager get localSyncState =>
      $$LocalSyncStateTableTableManager(_db, _db.localSyncState);
  $$UploadQueueTableTableManager get uploadQueue =>
      $$UploadQueueTableTableManager(_db, _db.uploadQueue);
}
