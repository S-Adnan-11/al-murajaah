// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class Reciters extends Table with TableInfo<Reciters, Reciter> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Reciters(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (length(trim(display_name)) > 0)',
  );
  static const VerificationMeta _arabicNameMeta = const VerificationMeta(
    'arabicName',
  );
  late final GeneratedColumn<String> arabicName = GeneratedColumn<String>(
    'arabic_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _attributionMeta = const VerificationMeta(
    'attribution',
  );
  late final GeneratedColumn<String> attribution = GeneratedColumn<String>(
    'attribution',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _sourceInfoMeta = const VerificationMeta(
    'sourceInfo',
  );
  late final GeneratedColumn<String> sourceInfo = GeneratedColumn<String>(
    'source_info',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    displayName,
    arabicName,
    attribution,
    sourceInfo,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reciters';
  @override
  VerificationContext validateIntegrity(
    Insertable<Reciter> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('arabic_name')) {
      context.handle(
        _arabicNameMeta,
        arabicName.isAcceptableOrUnknown(data['arabic_name']!, _arabicNameMeta),
      );
    }
    if (data.containsKey('attribution')) {
      context.handle(
        _attributionMeta,
        attribution.isAcceptableOrUnknown(
          data['attribution']!,
          _attributionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_attributionMeta);
    }
    if (data.containsKey('source_info')) {
      context.handle(
        _sourceInfoMeta,
        sourceInfo.isAcceptableOrUnknown(data['source_info']!, _sourceInfoMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceInfoMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Reciter map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Reciter(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
      arabicName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}arabic_name'],
      ),
      attribution: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}attribution'],
      )!,
      sourceInfo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_info'],
      )!,
    );
  }

  @override
  Reciters createAlias(String alias) {
    return Reciters(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class Reciter extends DataClass implements Insertable<Reciter> {
  final String id;
  final String displayName;
  final String? arabicName;
  final String attribution;
  final String sourceInfo;
  const Reciter({
    required this.id,
    required this.displayName,
    this.arabicName,
    required this.attribution,
    required this.sourceInfo,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['display_name'] = Variable<String>(displayName);
    if (!nullToAbsent || arabicName != null) {
      map['arabic_name'] = Variable<String>(arabicName);
    }
    map['attribution'] = Variable<String>(attribution);
    map['source_info'] = Variable<String>(sourceInfo);
    return map;
  }

  RecitersCompanion toCompanion(bool nullToAbsent) {
    return RecitersCompanion(
      id: Value(id),
      displayName: Value(displayName),
      arabicName: arabicName == null && nullToAbsent
          ? const Value.absent()
          : Value(arabicName),
      attribution: Value(attribution),
      sourceInfo: Value(sourceInfo),
    );
  }

  factory Reciter.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Reciter(
      id: serializer.fromJson<String>(json['id']),
      displayName: serializer.fromJson<String>(json['display_name']),
      arabicName: serializer.fromJson<String?>(json['arabic_name']),
      attribution: serializer.fromJson<String>(json['attribution']),
      sourceInfo: serializer.fromJson<String>(json['source_info']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'display_name': serializer.toJson<String>(displayName),
      'arabic_name': serializer.toJson<String?>(arabicName),
      'attribution': serializer.toJson<String>(attribution),
      'source_info': serializer.toJson<String>(sourceInfo),
    };
  }

  Reciter copyWith({
    String? id,
    String? displayName,
    Value<String?> arabicName = const Value.absent(),
    String? attribution,
    String? sourceInfo,
  }) => Reciter(
    id: id ?? this.id,
    displayName: displayName ?? this.displayName,
    arabicName: arabicName.present ? arabicName.value : this.arabicName,
    attribution: attribution ?? this.attribution,
    sourceInfo: sourceInfo ?? this.sourceInfo,
  );
  Reciter copyWithCompanion(RecitersCompanion data) {
    return Reciter(
      id: data.id.present ? data.id.value : this.id,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      arabicName: data.arabicName.present
          ? data.arabicName.value
          : this.arabicName,
      attribution: data.attribution.present
          ? data.attribution.value
          : this.attribution,
      sourceInfo: data.sourceInfo.present
          ? data.sourceInfo.value
          : this.sourceInfo,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Reciter(')
          ..write('id: $id, ')
          ..write('displayName: $displayName, ')
          ..write('arabicName: $arabicName, ')
          ..write('attribution: $attribution, ')
          ..write('sourceInfo: $sourceInfo')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, displayName, arabicName, attribution, sourceInfo);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Reciter &&
          other.id == this.id &&
          other.displayName == this.displayName &&
          other.arabicName == this.arabicName &&
          other.attribution == this.attribution &&
          other.sourceInfo == this.sourceInfo);
}

class RecitersCompanion extends UpdateCompanion<Reciter> {
  final Value<String> id;
  final Value<String> displayName;
  final Value<String?> arabicName;
  final Value<String> attribution;
  final Value<String> sourceInfo;
  final Value<int> rowid;
  const RecitersCompanion({
    this.id = const Value.absent(),
    this.displayName = const Value.absent(),
    this.arabicName = const Value.absent(),
    this.attribution = const Value.absent(),
    this.sourceInfo = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RecitersCompanion.insert({
    required String id,
    required String displayName,
    this.arabicName = const Value.absent(),
    required String attribution,
    required String sourceInfo,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       displayName = Value(displayName),
       attribution = Value(attribution),
       sourceInfo = Value(sourceInfo);
  static Insertable<Reciter> custom({
    Expression<String>? id,
    Expression<String>? displayName,
    Expression<String>? arabicName,
    Expression<String>? attribution,
    Expression<String>? sourceInfo,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (displayName != null) 'display_name': displayName,
      if (arabicName != null) 'arabic_name': arabicName,
      if (attribution != null) 'attribution': attribution,
      if (sourceInfo != null) 'source_info': sourceInfo,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RecitersCompanion copyWith({
    Value<String>? id,
    Value<String>? displayName,
    Value<String?>? arabicName,
    Value<String>? attribution,
    Value<String>? sourceInfo,
    Value<int>? rowid,
  }) {
    return RecitersCompanion(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      arabicName: arabicName ?? this.arabicName,
      attribution: attribution ?? this.attribution,
      sourceInfo: sourceInfo ?? this.sourceInfo,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (arabicName.present) {
      map['arabic_name'] = Variable<String>(arabicName.value);
    }
    if (attribution.present) {
      map['attribution'] = Variable<String>(attribution.value);
    }
    if (sourceInfo.present) {
      map['source_info'] = Variable<String>(sourceInfo.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecitersCompanion(')
          ..write('id: $id, ')
          ..write('displayName: $displayName, ')
          ..write('arabicName: $arabicName, ')
          ..write('attribution: $attribution, ')
          ..write('sourceInfo: $sourceInfo, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class AppSettings extends Table with TableInfo<AppSettings, AppSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  AppSettings(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL PRIMARY KEY CHECK (id = 1)',
  );
  static const VerificationMeta _themeMeta = const VerificationMeta('theme');
  late final GeneratedColumn<String> theme = GeneratedColumn<String>(
    'theme',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT \'system\' CHECK (theme IN (\'system\', \'light\', \'dark\'))',
    defaultValue: const CustomExpression('\'system\''),
  );
  static const VerificationMeta _reducedMotionMeta = const VerificationMeta(
    'reducedMotion',
  );
  late final GeneratedColumn<int> reducedMotion = GeneratedColumn<int>(
    'reduced_motion',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0 CHECK (reduced_motion IN (0, 1))',
    defaultValue: const CustomExpression('0'),
  );
  static const VerificationMeta _networkPolicyMeta = const VerificationMeta(
    'networkPolicy',
  );
  late final GeneratedColumn<String> networkPolicy = GeneratedColumn<String>(
    'network_policy',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT \'wifi\' CHECK (network_policy IN (\'wifi\', \'any\'))',
    defaultValue: const CustomExpression('\'wifi\''),
  );
  static const VerificationMeta _defaultReciterIdMeta = const VerificationMeta(
    'defaultReciterId',
  );
  late final GeneratedColumn<String> defaultReciterId = GeneratedColumn<String>(
    'default_reciter_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'REFERENCES reciters(id)',
  );
  static const VerificationMeta _dailyGoalMsMeta = const VerificationMeta(
    'dailyGoalMs',
  );
  late final GeneratedColumn<int> dailyGoalMs = GeneratedColumn<int>(
    'daily_goal_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 300000 CHECK (daily_goal_ms >= 0)',
    defaultValue: const CustomExpression('300000'),
  );
  static const VerificationMeta _preferencesVersionMeta =
      const VerificationMeta('preferencesVersion');
  late final GeneratedColumn<int> preferencesVersion = GeneratedColumn<int>(
    'preferences_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 1 CHECK (preferences_version > 0)',
    defaultValue: const CustomExpression('1'),
  );
  static const VerificationMeta _updatedUtcMsMeta = const VerificationMeta(
    'updatedUtcMs',
  );
  late final GeneratedColumn<int> updatedUtcMs = GeneratedColumn<int>(
    'updated_utc_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0',
    defaultValue: const CustomExpression('0'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    theme,
    reducedMotion,
    networkPolicy,
    defaultReciterId,
    dailyGoalMs,
    preferencesVersion,
    updatedUtcMs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppSetting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('theme')) {
      context.handle(
        _themeMeta,
        theme.isAcceptableOrUnknown(data['theme']!, _themeMeta),
      );
    }
    if (data.containsKey('reduced_motion')) {
      context.handle(
        _reducedMotionMeta,
        reducedMotion.isAcceptableOrUnknown(
          data['reduced_motion']!,
          _reducedMotionMeta,
        ),
      );
    }
    if (data.containsKey('network_policy')) {
      context.handle(
        _networkPolicyMeta,
        networkPolicy.isAcceptableOrUnknown(
          data['network_policy']!,
          _networkPolicyMeta,
        ),
      );
    }
    if (data.containsKey('default_reciter_id')) {
      context.handle(
        _defaultReciterIdMeta,
        defaultReciterId.isAcceptableOrUnknown(
          data['default_reciter_id']!,
          _defaultReciterIdMeta,
        ),
      );
    }
    if (data.containsKey('daily_goal_ms')) {
      context.handle(
        _dailyGoalMsMeta,
        dailyGoalMs.isAcceptableOrUnknown(
          data['daily_goal_ms']!,
          _dailyGoalMsMeta,
        ),
      );
    }
    if (data.containsKey('preferences_version')) {
      context.handle(
        _preferencesVersionMeta,
        preferencesVersion.isAcceptableOrUnknown(
          data['preferences_version']!,
          _preferencesVersionMeta,
        ),
      );
    }
    if (data.containsKey('updated_utc_ms')) {
      context.handle(
        _updatedUtcMsMeta,
        updatedUtcMs.isAcceptableOrUnknown(
          data['updated_utc_ms']!,
          _updatedUtcMsMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AppSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSetting(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      theme: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}theme'],
      )!,
      reducedMotion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reduced_motion'],
      )!,
      networkPolicy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}network_policy'],
      )!,
      defaultReciterId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}default_reciter_id'],
      ),
      dailyGoalMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}daily_goal_ms'],
      )!,
      preferencesVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}preferences_version'],
      )!,
      updatedUtcMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_utc_ms'],
      )!,
    );
  }

  @override
  AppSettings createAlias(String alias) {
    return AppSettings(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class AppSetting extends DataClass implements Insertable<AppSetting> {
  final int id;
  final String theme;
  final int reducedMotion;
  final String networkPolicy;
  final String? defaultReciterId;
  final int dailyGoalMs;
  final int preferencesVersion;
  final int updatedUtcMs;
  const AppSetting({
    required this.id,
    required this.theme,
    required this.reducedMotion,
    required this.networkPolicy,
    this.defaultReciterId,
    required this.dailyGoalMs,
    required this.preferencesVersion,
    required this.updatedUtcMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['theme'] = Variable<String>(theme);
    map['reduced_motion'] = Variable<int>(reducedMotion);
    map['network_policy'] = Variable<String>(networkPolicy);
    if (!nullToAbsent || defaultReciterId != null) {
      map['default_reciter_id'] = Variable<String>(defaultReciterId);
    }
    map['daily_goal_ms'] = Variable<int>(dailyGoalMs);
    map['preferences_version'] = Variable<int>(preferencesVersion);
    map['updated_utc_ms'] = Variable<int>(updatedUtcMs);
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(
      id: Value(id),
      theme: Value(theme),
      reducedMotion: Value(reducedMotion),
      networkPolicy: Value(networkPolicy),
      defaultReciterId: defaultReciterId == null && nullToAbsent
          ? const Value.absent()
          : Value(defaultReciterId),
      dailyGoalMs: Value(dailyGoalMs),
      preferencesVersion: Value(preferencesVersion),
      updatedUtcMs: Value(updatedUtcMs),
    );
  }

  factory AppSetting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSetting(
      id: serializer.fromJson<int>(json['id']),
      theme: serializer.fromJson<String>(json['theme']),
      reducedMotion: serializer.fromJson<int>(json['reduced_motion']),
      networkPolicy: serializer.fromJson<String>(json['network_policy']),
      defaultReciterId: serializer.fromJson<String?>(
        json['default_reciter_id'],
      ),
      dailyGoalMs: serializer.fromJson<int>(json['daily_goal_ms']),
      preferencesVersion: serializer.fromJson<int>(json['preferences_version']),
      updatedUtcMs: serializer.fromJson<int>(json['updated_utc_ms']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'theme': serializer.toJson<String>(theme),
      'reduced_motion': serializer.toJson<int>(reducedMotion),
      'network_policy': serializer.toJson<String>(networkPolicy),
      'default_reciter_id': serializer.toJson<String?>(defaultReciterId),
      'daily_goal_ms': serializer.toJson<int>(dailyGoalMs),
      'preferences_version': serializer.toJson<int>(preferencesVersion),
      'updated_utc_ms': serializer.toJson<int>(updatedUtcMs),
    };
  }

  AppSetting copyWith({
    int? id,
    String? theme,
    int? reducedMotion,
    String? networkPolicy,
    Value<String?> defaultReciterId = const Value.absent(),
    int? dailyGoalMs,
    int? preferencesVersion,
    int? updatedUtcMs,
  }) => AppSetting(
    id: id ?? this.id,
    theme: theme ?? this.theme,
    reducedMotion: reducedMotion ?? this.reducedMotion,
    networkPolicy: networkPolicy ?? this.networkPolicy,
    defaultReciterId: defaultReciterId.present
        ? defaultReciterId.value
        : this.defaultReciterId,
    dailyGoalMs: dailyGoalMs ?? this.dailyGoalMs,
    preferencesVersion: preferencesVersion ?? this.preferencesVersion,
    updatedUtcMs: updatedUtcMs ?? this.updatedUtcMs,
  );
  AppSetting copyWithCompanion(AppSettingsCompanion data) {
    return AppSetting(
      id: data.id.present ? data.id.value : this.id,
      theme: data.theme.present ? data.theme.value : this.theme,
      reducedMotion: data.reducedMotion.present
          ? data.reducedMotion.value
          : this.reducedMotion,
      networkPolicy: data.networkPolicy.present
          ? data.networkPolicy.value
          : this.networkPolicy,
      defaultReciterId: data.defaultReciterId.present
          ? data.defaultReciterId.value
          : this.defaultReciterId,
      dailyGoalMs: data.dailyGoalMs.present
          ? data.dailyGoalMs.value
          : this.dailyGoalMs,
      preferencesVersion: data.preferencesVersion.present
          ? data.preferencesVersion.value
          : this.preferencesVersion,
      updatedUtcMs: data.updatedUtcMs.present
          ? data.updatedUtcMs.value
          : this.updatedUtcMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSetting(')
          ..write('id: $id, ')
          ..write('theme: $theme, ')
          ..write('reducedMotion: $reducedMotion, ')
          ..write('networkPolicy: $networkPolicy, ')
          ..write('defaultReciterId: $defaultReciterId, ')
          ..write('dailyGoalMs: $dailyGoalMs, ')
          ..write('preferencesVersion: $preferencesVersion, ')
          ..write('updatedUtcMs: $updatedUtcMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    theme,
    reducedMotion,
    networkPolicy,
    defaultReciterId,
    dailyGoalMs,
    preferencesVersion,
    updatedUtcMs,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSetting &&
          other.id == this.id &&
          other.theme == this.theme &&
          other.reducedMotion == this.reducedMotion &&
          other.networkPolicy == this.networkPolicy &&
          other.defaultReciterId == this.defaultReciterId &&
          other.dailyGoalMs == this.dailyGoalMs &&
          other.preferencesVersion == this.preferencesVersion &&
          other.updatedUtcMs == this.updatedUtcMs);
}

class AppSettingsCompanion extends UpdateCompanion<AppSetting> {
  final Value<int> id;
  final Value<String> theme;
  final Value<int> reducedMotion;
  final Value<String> networkPolicy;
  final Value<String?> defaultReciterId;
  final Value<int> dailyGoalMs;
  final Value<int> preferencesVersion;
  final Value<int> updatedUtcMs;
  const AppSettingsCompanion({
    this.id = const Value.absent(),
    this.theme = const Value.absent(),
    this.reducedMotion = const Value.absent(),
    this.networkPolicy = const Value.absent(),
    this.defaultReciterId = const Value.absent(),
    this.dailyGoalMs = const Value.absent(),
    this.preferencesVersion = const Value.absent(),
    this.updatedUtcMs = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    this.id = const Value.absent(),
    this.theme = const Value.absent(),
    this.reducedMotion = const Value.absent(),
    this.networkPolicy = const Value.absent(),
    this.defaultReciterId = const Value.absent(),
    this.dailyGoalMs = const Value.absent(),
    this.preferencesVersion = const Value.absent(),
    this.updatedUtcMs = const Value.absent(),
  });
  static Insertable<AppSetting> custom({
    Expression<int>? id,
    Expression<String>? theme,
    Expression<int>? reducedMotion,
    Expression<String>? networkPolicy,
    Expression<String>? defaultReciterId,
    Expression<int>? dailyGoalMs,
    Expression<int>? preferencesVersion,
    Expression<int>? updatedUtcMs,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (theme != null) 'theme': theme,
      if (reducedMotion != null) 'reduced_motion': reducedMotion,
      if (networkPolicy != null) 'network_policy': networkPolicy,
      if (defaultReciterId != null) 'default_reciter_id': defaultReciterId,
      if (dailyGoalMs != null) 'daily_goal_ms': dailyGoalMs,
      if (preferencesVersion != null) 'preferences_version': preferencesVersion,
      if (updatedUtcMs != null) 'updated_utc_ms': updatedUtcMs,
    });
  }

  AppSettingsCompanion copyWith({
    Value<int>? id,
    Value<String>? theme,
    Value<int>? reducedMotion,
    Value<String>? networkPolicy,
    Value<String?>? defaultReciterId,
    Value<int>? dailyGoalMs,
    Value<int>? preferencesVersion,
    Value<int>? updatedUtcMs,
  }) {
    return AppSettingsCompanion(
      id: id ?? this.id,
      theme: theme ?? this.theme,
      reducedMotion: reducedMotion ?? this.reducedMotion,
      networkPolicy: networkPolicy ?? this.networkPolicy,
      defaultReciterId: defaultReciterId ?? this.defaultReciterId,
      dailyGoalMs: dailyGoalMs ?? this.dailyGoalMs,
      preferencesVersion: preferencesVersion ?? this.preferencesVersion,
      updatedUtcMs: updatedUtcMs ?? this.updatedUtcMs,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (theme.present) {
      map['theme'] = Variable<String>(theme.value);
    }
    if (reducedMotion.present) {
      map['reduced_motion'] = Variable<int>(reducedMotion.value);
    }
    if (networkPolicy.present) {
      map['network_policy'] = Variable<String>(networkPolicy.value);
    }
    if (defaultReciterId.present) {
      map['default_reciter_id'] = Variable<String>(defaultReciterId.value);
    }
    if (dailyGoalMs.present) {
      map['daily_goal_ms'] = Variable<int>(dailyGoalMs.value);
    }
    if (preferencesVersion.present) {
      map['preferences_version'] = Variable<int>(preferencesVersion.value);
    }
    if (updatedUtcMs.present) {
      map['updated_utc_ms'] = Variable<int>(updatedUtcMs.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsCompanion(')
          ..write('id: $id, ')
          ..write('theme: $theme, ')
          ..write('reducedMotion: $reducedMotion, ')
          ..write('networkPolicy: $networkPolicy, ')
          ..write('defaultReciterId: $defaultReciterId, ')
          ..write('dailyGoalMs: $dailyGoalMs, ')
          ..write('preferencesVersion: $preferencesVersion, ')
          ..write('updatedUtcMs: $updatedUtcMs')
          ..write(')'))
        .toString();
  }
}

class Surahs extends Table with TableInfo<Surahs, Surah> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Surahs(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _numberMeta = const VerificationMeta('number');
  late final GeneratedColumn<int> number = GeneratedColumn<int>(
    'number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL PRIMARY KEY CHECK (number BETWEEN 1 AND 114)',
  );
  static const VerificationMeta _arabicNameMeta = const VerificationMeta(
    'arabicName',
  );
  late final GeneratedColumn<String> arabicName = GeneratedColumn<String>(
    'arabic_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (length(trim(arabic_name)) > 0)',
  );
  static const VerificationMeta _transliterationMeta = const VerificationMeta(
    'transliteration',
  );
  late final GeneratedColumn<String> transliteration = GeneratedColumn<String>(
    'transliteration',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (length(trim(transliteration)) > 0)',
  );
  static const VerificationMeta _searchAliasesMeta = const VerificationMeta(
    'searchAliases',
  );
  late final GeneratedColumn<String> searchAliases = GeneratedColumn<String>(
    'search_aliases',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (json_valid(search_aliases))',
  );
  @override
  List<GeneratedColumn> get $columns => [
    number,
    arabicName,
    transliteration,
    searchAliases,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'surahs';
  @override
  VerificationContext validateIntegrity(
    Insertable<Surah> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('number')) {
      context.handle(
        _numberMeta,
        number.isAcceptableOrUnknown(data['number']!, _numberMeta),
      );
    }
    if (data.containsKey('arabic_name')) {
      context.handle(
        _arabicNameMeta,
        arabicName.isAcceptableOrUnknown(data['arabic_name']!, _arabicNameMeta),
      );
    } else if (isInserting) {
      context.missing(_arabicNameMeta);
    }
    if (data.containsKey('transliteration')) {
      context.handle(
        _transliterationMeta,
        transliteration.isAcceptableOrUnknown(
          data['transliteration']!,
          _transliterationMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_transliterationMeta);
    }
    if (data.containsKey('search_aliases')) {
      context.handle(
        _searchAliasesMeta,
        searchAliases.isAcceptableOrUnknown(
          data['search_aliases']!,
          _searchAliasesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_searchAliasesMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {number};
  @override
  Surah map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Surah(
      number: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}number'],
      )!,
      arabicName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}arabic_name'],
      )!,
      transliteration: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}transliteration'],
      )!,
      searchAliases: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}search_aliases'],
      )!,
    );
  }

  @override
  Surahs createAlias(String alias) {
    return Surahs(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class Surah extends DataClass implements Insertable<Surah> {
  final int number;
  final String arabicName;
  final String transliteration;
  final String searchAliases;
  const Surah({
    required this.number,
    required this.arabicName,
    required this.transliteration,
    required this.searchAliases,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['number'] = Variable<int>(number);
    map['arabic_name'] = Variable<String>(arabicName);
    map['transliteration'] = Variable<String>(transliteration);
    map['search_aliases'] = Variable<String>(searchAliases);
    return map;
  }

  SurahsCompanion toCompanion(bool nullToAbsent) {
    return SurahsCompanion(
      number: Value(number),
      arabicName: Value(arabicName),
      transliteration: Value(transliteration),
      searchAliases: Value(searchAliases),
    );
  }

  factory Surah.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Surah(
      number: serializer.fromJson<int>(json['number']),
      arabicName: serializer.fromJson<String>(json['arabic_name']),
      transliteration: serializer.fromJson<String>(json['transliteration']),
      searchAliases: serializer.fromJson<String>(json['search_aliases']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'number': serializer.toJson<int>(number),
      'arabic_name': serializer.toJson<String>(arabicName),
      'transliteration': serializer.toJson<String>(transliteration),
      'search_aliases': serializer.toJson<String>(searchAliases),
    };
  }

  Surah copyWith({
    int? number,
    String? arabicName,
    String? transliteration,
    String? searchAliases,
  }) => Surah(
    number: number ?? this.number,
    arabicName: arabicName ?? this.arabicName,
    transliteration: transliteration ?? this.transliteration,
    searchAliases: searchAliases ?? this.searchAliases,
  );
  Surah copyWithCompanion(SurahsCompanion data) {
    return Surah(
      number: data.number.present ? data.number.value : this.number,
      arabicName: data.arabicName.present
          ? data.arabicName.value
          : this.arabicName,
      transliteration: data.transliteration.present
          ? data.transliteration.value
          : this.transliteration,
      searchAliases: data.searchAliases.present
          ? data.searchAliases.value
          : this.searchAliases,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Surah(')
          ..write('number: $number, ')
          ..write('arabicName: $arabicName, ')
          ..write('transliteration: $transliteration, ')
          ..write('searchAliases: $searchAliases')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(number, arabicName, transliteration, searchAliases);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Surah &&
          other.number == this.number &&
          other.arabicName == this.arabicName &&
          other.transliteration == this.transliteration &&
          other.searchAliases == this.searchAliases);
}

class SurahsCompanion extends UpdateCompanion<Surah> {
  final Value<int> number;
  final Value<String> arabicName;
  final Value<String> transliteration;
  final Value<String> searchAliases;
  const SurahsCompanion({
    this.number = const Value.absent(),
    this.arabicName = const Value.absent(),
    this.transliteration = const Value.absent(),
    this.searchAliases = const Value.absent(),
  });
  SurahsCompanion.insert({
    this.number = const Value.absent(),
    required String arabicName,
    required String transliteration,
    required String searchAliases,
  }) : arabicName = Value(arabicName),
       transliteration = Value(transliteration),
       searchAliases = Value(searchAliases);
  static Insertable<Surah> custom({
    Expression<int>? number,
    Expression<String>? arabicName,
    Expression<String>? transliteration,
    Expression<String>? searchAliases,
  }) {
    return RawValuesInsertable({
      if (number != null) 'number': number,
      if (arabicName != null) 'arabic_name': arabicName,
      if (transliteration != null) 'transliteration': transliteration,
      if (searchAliases != null) 'search_aliases': searchAliases,
    });
  }

  SurahsCompanion copyWith({
    Value<int>? number,
    Value<String>? arabicName,
    Value<String>? transliteration,
    Value<String>? searchAliases,
  }) {
    return SurahsCompanion(
      number: number ?? this.number,
      arabicName: arabicName ?? this.arabicName,
      transliteration: transliteration ?? this.transliteration,
      searchAliases: searchAliases ?? this.searchAliases,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (number.present) {
      map['number'] = Variable<int>(number.value);
    }
    if (arabicName.present) {
      map['arabic_name'] = Variable<String>(arabicName.value);
    }
    if (transliteration.present) {
      map['transliteration'] = Variable<String>(transliteration.value);
    }
    if (searchAliases.present) {
      map['search_aliases'] = Variable<String>(searchAliases.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SurahsCompanion(')
          ..write('number: $number, ')
          ..write('arabicName: $arabicName, ')
          ..write('transliteration: $transliteration, ')
          ..write('searchAliases: $searchAliases')
          ..write(')'))
        .toString();
  }
}

class RecordingEditions extends Table
    with TableInfo<RecordingEditions, RecordingEdition> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  RecordingEditions(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _reciterIdMeta = const VerificationMeta(
    'reciterId',
  );
  late final GeneratedColumn<String> reciterId = GeneratedColumn<String>(
    'reciter_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES reciters(id)',
  );
  static const VerificationMeta _riwayahMeta = const VerificationMeta(
    'riwayah',
  );
  late final GeneratedColumn<String> riwayah = GeneratedColumn<String>(
    'riwayah',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _sourceNotesMeta = const VerificationMeta(
    'sourceNotes',
  );
  late final GeneratedColumn<String> sourceNotes = GeneratedColumn<String>(
    'source_notes',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [id, reciterId, riwayah, sourceNotes];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'recording_editions';
  @override
  VerificationContext validateIntegrity(
    Insertable<RecordingEdition> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('reciter_id')) {
      context.handle(
        _reciterIdMeta,
        reciterId.isAcceptableOrUnknown(data['reciter_id']!, _reciterIdMeta),
      );
    } else if (isInserting) {
      context.missing(_reciterIdMeta);
    }
    if (data.containsKey('riwayah')) {
      context.handle(
        _riwayahMeta,
        riwayah.isAcceptableOrUnknown(data['riwayah']!, _riwayahMeta),
      );
    }
    if (data.containsKey('source_notes')) {
      context.handle(
        _sourceNotesMeta,
        sourceNotes.isAcceptableOrUnknown(
          data['source_notes']!,
          _sourceNotesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sourceNotesMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RecordingEdition map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RecordingEdition(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      reciterId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reciter_id'],
      )!,
      riwayah: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}riwayah'],
      ),
      sourceNotes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_notes'],
      )!,
    );
  }

  @override
  RecordingEditions createAlias(String alias) {
    return RecordingEditions(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class RecordingEdition extends DataClass
    implements Insertable<RecordingEdition> {
  final String id;
  final String reciterId;
  final String? riwayah;
  final String sourceNotes;
  const RecordingEdition({
    required this.id,
    required this.reciterId,
    this.riwayah,
    required this.sourceNotes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['reciter_id'] = Variable<String>(reciterId);
    if (!nullToAbsent || riwayah != null) {
      map['riwayah'] = Variable<String>(riwayah);
    }
    map['source_notes'] = Variable<String>(sourceNotes);
    return map;
  }

  RecordingEditionsCompanion toCompanion(bool nullToAbsent) {
    return RecordingEditionsCompanion(
      id: Value(id),
      reciterId: Value(reciterId),
      riwayah: riwayah == null && nullToAbsent
          ? const Value.absent()
          : Value(riwayah),
      sourceNotes: Value(sourceNotes),
    );
  }

  factory RecordingEdition.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RecordingEdition(
      id: serializer.fromJson<String>(json['id']),
      reciterId: serializer.fromJson<String>(json['reciter_id']),
      riwayah: serializer.fromJson<String?>(json['riwayah']),
      sourceNotes: serializer.fromJson<String>(json['source_notes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'reciter_id': serializer.toJson<String>(reciterId),
      'riwayah': serializer.toJson<String?>(riwayah),
      'source_notes': serializer.toJson<String>(sourceNotes),
    };
  }

  RecordingEdition copyWith({
    String? id,
    String? reciterId,
    Value<String?> riwayah = const Value.absent(),
    String? sourceNotes,
  }) => RecordingEdition(
    id: id ?? this.id,
    reciterId: reciterId ?? this.reciterId,
    riwayah: riwayah.present ? riwayah.value : this.riwayah,
    sourceNotes: sourceNotes ?? this.sourceNotes,
  );
  RecordingEdition copyWithCompanion(RecordingEditionsCompanion data) {
    return RecordingEdition(
      id: data.id.present ? data.id.value : this.id,
      reciterId: data.reciterId.present ? data.reciterId.value : this.reciterId,
      riwayah: data.riwayah.present ? data.riwayah.value : this.riwayah,
      sourceNotes: data.sourceNotes.present
          ? data.sourceNotes.value
          : this.sourceNotes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RecordingEdition(')
          ..write('id: $id, ')
          ..write('reciterId: $reciterId, ')
          ..write('riwayah: $riwayah, ')
          ..write('sourceNotes: $sourceNotes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, reciterId, riwayah, sourceNotes);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecordingEdition &&
          other.id == this.id &&
          other.reciterId == this.reciterId &&
          other.riwayah == this.riwayah &&
          other.sourceNotes == this.sourceNotes);
}

class RecordingEditionsCompanion extends UpdateCompanion<RecordingEdition> {
  final Value<String> id;
  final Value<String> reciterId;
  final Value<String?> riwayah;
  final Value<String> sourceNotes;
  final Value<int> rowid;
  const RecordingEditionsCompanion({
    this.id = const Value.absent(),
    this.reciterId = const Value.absent(),
    this.riwayah = const Value.absent(),
    this.sourceNotes = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RecordingEditionsCompanion.insert({
    required String id,
    required String reciterId,
    this.riwayah = const Value.absent(),
    required String sourceNotes,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       reciterId = Value(reciterId),
       sourceNotes = Value(sourceNotes);
  static Insertable<RecordingEdition> custom({
    Expression<String>? id,
    Expression<String>? reciterId,
    Expression<String>? riwayah,
    Expression<String>? sourceNotes,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (reciterId != null) 'reciter_id': reciterId,
      if (riwayah != null) 'riwayah': riwayah,
      if (sourceNotes != null) 'source_notes': sourceNotes,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RecordingEditionsCompanion copyWith({
    Value<String>? id,
    Value<String>? reciterId,
    Value<String?>? riwayah,
    Value<String>? sourceNotes,
    Value<int>? rowid,
  }) {
    return RecordingEditionsCompanion(
      id: id ?? this.id,
      reciterId: reciterId ?? this.reciterId,
      riwayah: riwayah ?? this.riwayah,
      sourceNotes: sourceNotes ?? this.sourceNotes,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (reciterId.present) {
      map['reciter_id'] = Variable<String>(reciterId.value);
    }
    if (riwayah.present) {
      map['riwayah'] = Variable<String>(riwayah.value);
    }
    if (sourceNotes.present) {
      map['source_notes'] = Variable<String>(sourceNotes.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecordingEditionsCompanion(')
          ..write('id: $id, ')
          ..write('reciterId: $reciterId, ')
          ..write('riwayah: $riwayah, ')
          ..write('sourceNotes: $sourceNotes, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class AudioAssets extends Table with TableInfo<AudioAssets, AudioAsset> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  AudioAssets(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _editionIdMeta = const VerificationMeta(
    'editionId',
  );
  late final GeneratedColumn<String> editionId = GeneratedColumn<String>(
    'edition_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES recording_editions(id)',
  );
  static const VerificationMeta _surahNumberMeta = const VerificationMeta(
    'surahNumber',
  );
  late final GeneratedColumn<int> surahNumber = GeneratedColumn<int>(
    'surah_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES surahs(number)',
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (version > 0)',
  );
  static const VerificationMeta _urlMeta = const VerificationMeta('url');
  late final GeneratedColumn<String> url = GeneratedColumn<String>(
    'url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (url LIKE \'https://%\')',
  );
  static const VerificationMeta _mimeTypeMeta = const VerificationMeta(
    'mimeType',
  );
  late final GeneratedColumn<String> mimeType = GeneratedColumn<String>(
    'mime_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _durationMsMeta = const VerificationMeta(
    'durationMs',
  );
  late final GeneratedColumn<int> durationMs = GeneratedColumn<int>(
    'duration_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'CHECK (duration_ms > 0)',
  );
  static const VerificationMeta _byteSizeMeta = const VerificationMeta(
    'byteSize',
  );
  late final GeneratedColumn<int> byteSize = GeneratedColumn<int>(
    'byte_size',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'CHECK (byte_size > 0)',
  );
  static const VerificationMeta _sha256Meta = const VerificationMeta('sha256');
  late final GeneratedColumn<String> sha256 = GeneratedColumn<String>(
    'sha256',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints:
        'CHECK (length(sha256) = 64 AND sha256 NOT GLOB \'*[^0-9a-f]*\')',
  );
  static const VerificationMeta _availabilityMeta = const VerificationMeta(
    'availability',
  );
  late final GeneratedColumn<String> availability = GeneratedColumn<String>(
    'availability',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (availability IN (\'unavailable\', \'published\', \'retired\'))',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    editionId,
    surahNumber,
    version,
    url,
    mimeType,
    durationMs,
    byteSize,
    sha256,
    availability,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'audio_assets';
  @override
  VerificationContext validateIntegrity(
    Insertable<AudioAsset> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('edition_id')) {
      context.handle(
        _editionIdMeta,
        editionId.isAcceptableOrUnknown(data['edition_id']!, _editionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_editionIdMeta);
    }
    if (data.containsKey('surah_number')) {
      context.handle(
        _surahNumberMeta,
        surahNumber.isAcceptableOrUnknown(
          data['surah_number']!,
          _surahNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_surahNumberMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    } else if (isInserting) {
      context.missing(_versionMeta);
    }
    if (data.containsKey('url')) {
      context.handle(
        _urlMeta,
        url.isAcceptableOrUnknown(data['url']!, _urlMeta),
      );
    } else if (isInserting) {
      context.missing(_urlMeta);
    }
    if (data.containsKey('mime_type')) {
      context.handle(
        _mimeTypeMeta,
        mimeType.isAcceptableOrUnknown(data['mime_type']!, _mimeTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_mimeTypeMeta);
    }
    if (data.containsKey('duration_ms')) {
      context.handle(
        _durationMsMeta,
        durationMs.isAcceptableOrUnknown(data['duration_ms']!, _durationMsMeta),
      );
    }
    if (data.containsKey('byte_size')) {
      context.handle(
        _byteSizeMeta,
        byteSize.isAcceptableOrUnknown(data['byte_size']!, _byteSizeMeta),
      );
    }
    if (data.containsKey('sha256')) {
      context.handle(
        _sha256Meta,
        sha256.isAcceptableOrUnknown(data['sha256']!, _sha256Meta),
      );
    }
    if (data.containsKey('availability')) {
      context.handle(
        _availabilityMeta,
        availability.isAcceptableOrUnknown(
          data['availability']!,
          _availabilityMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_availabilityMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {editionId, surahNumber, version},
  ];
  @override
  AudioAsset map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AudioAsset(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      editionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}edition_id'],
      )!,
      surahNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}surah_number'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      url: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}url'],
      )!,
      mimeType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mime_type'],
      )!,
      durationMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_ms'],
      ),
      byteSize: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}byte_size'],
      ),
      sha256: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sha256'],
      ),
      availability: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}availability'],
      )!,
    );
  }

  @override
  AudioAssets createAlias(String alias) {
    return AudioAssets(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const [
    'CHECK(availability <> \'published\' OR(duration_ms IS NOT NULL AND byte_size IS NOT NULL AND sha256 IS NOT NULL))',
    'UNIQUE(edition_id, surah_number, version)',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class AudioAsset extends DataClass implements Insertable<AudioAsset> {
  final String id;
  final String editionId;
  final int surahNumber;
  final int version;
  final String url;
  final String mimeType;
  final int? durationMs;
  final int? byteSize;
  final String? sha256;
  final String availability;
  const AudioAsset({
    required this.id,
    required this.editionId,
    required this.surahNumber,
    required this.version,
    required this.url,
    required this.mimeType,
    this.durationMs,
    this.byteSize,
    this.sha256,
    required this.availability,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['edition_id'] = Variable<String>(editionId);
    map['surah_number'] = Variable<int>(surahNumber);
    map['version'] = Variable<int>(version);
    map['url'] = Variable<String>(url);
    map['mime_type'] = Variable<String>(mimeType);
    if (!nullToAbsent || durationMs != null) {
      map['duration_ms'] = Variable<int>(durationMs);
    }
    if (!nullToAbsent || byteSize != null) {
      map['byte_size'] = Variable<int>(byteSize);
    }
    if (!nullToAbsent || sha256 != null) {
      map['sha256'] = Variable<String>(sha256);
    }
    map['availability'] = Variable<String>(availability);
    return map;
  }

  AudioAssetsCompanion toCompanion(bool nullToAbsent) {
    return AudioAssetsCompanion(
      id: Value(id),
      editionId: Value(editionId),
      surahNumber: Value(surahNumber),
      version: Value(version),
      url: Value(url),
      mimeType: Value(mimeType),
      durationMs: durationMs == null && nullToAbsent
          ? const Value.absent()
          : Value(durationMs),
      byteSize: byteSize == null && nullToAbsent
          ? const Value.absent()
          : Value(byteSize),
      sha256: sha256 == null && nullToAbsent
          ? const Value.absent()
          : Value(sha256),
      availability: Value(availability),
    );
  }

  factory AudioAsset.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AudioAsset(
      id: serializer.fromJson<String>(json['id']),
      editionId: serializer.fromJson<String>(json['edition_id']),
      surahNumber: serializer.fromJson<int>(json['surah_number']),
      version: serializer.fromJson<int>(json['version']),
      url: serializer.fromJson<String>(json['url']),
      mimeType: serializer.fromJson<String>(json['mime_type']),
      durationMs: serializer.fromJson<int?>(json['duration_ms']),
      byteSize: serializer.fromJson<int?>(json['byte_size']),
      sha256: serializer.fromJson<String?>(json['sha256']),
      availability: serializer.fromJson<String>(json['availability']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'edition_id': serializer.toJson<String>(editionId),
      'surah_number': serializer.toJson<int>(surahNumber),
      'version': serializer.toJson<int>(version),
      'url': serializer.toJson<String>(url),
      'mime_type': serializer.toJson<String>(mimeType),
      'duration_ms': serializer.toJson<int?>(durationMs),
      'byte_size': serializer.toJson<int?>(byteSize),
      'sha256': serializer.toJson<String?>(sha256),
      'availability': serializer.toJson<String>(availability),
    };
  }

  AudioAsset copyWith({
    String? id,
    String? editionId,
    int? surahNumber,
    int? version,
    String? url,
    String? mimeType,
    Value<int?> durationMs = const Value.absent(),
    Value<int?> byteSize = const Value.absent(),
    Value<String?> sha256 = const Value.absent(),
    String? availability,
  }) => AudioAsset(
    id: id ?? this.id,
    editionId: editionId ?? this.editionId,
    surahNumber: surahNumber ?? this.surahNumber,
    version: version ?? this.version,
    url: url ?? this.url,
    mimeType: mimeType ?? this.mimeType,
    durationMs: durationMs.present ? durationMs.value : this.durationMs,
    byteSize: byteSize.present ? byteSize.value : this.byteSize,
    sha256: sha256.present ? sha256.value : this.sha256,
    availability: availability ?? this.availability,
  );
  AudioAsset copyWithCompanion(AudioAssetsCompanion data) {
    return AudioAsset(
      id: data.id.present ? data.id.value : this.id,
      editionId: data.editionId.present ? data.editionId.value : this.editionId,
      surahNumber: data.surahNumber.present
          ? data.surahNumber.value
          : this.surahNumber,
      version: data.version.present ? data.version.value : this.version,
      url: data.url.present ? data.url.value : this.url,
      mimeType: data.mimeType.present ? data.mimeType.value : this.mimeType,
      durationMs: data.durationMs.present
          ? data.durationMs.value
          : this.durationMs,
      byteSize: data.byteSize.present ? data.byteSize.value : this.byteSize,
      sha256: data.sha256.present ? data.sha256.value : this.sha256,
      availability: data.availability.present
          ? data.availability.value
          : this.availability,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AudioAsset(')
          ..write('id: $id, ')
          ..write('editionId: $editionId, ')
          ..write('surahNumber: $surahNumber, ')
          ..write('version: $version, ')
          ..write('url: $url, ')
          ..write('mimeType: $mimeType, ')
          ..write('durationMs: $durationMs, ')
          ..write('byteSize: $byteSize, ')
          ..write('sha256: $sha256, ')
          ..write('availability: $availability')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    editionId,
    surahNumber,
    version,
    url,
    mimeType,
    durationMs,
    byteSize,
    sha256,
    availability,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AudioAsset &&
          other.id == this.id &&
          other.editionId == this.editionId &&
          other.surahNumber == this.surahNumber &&
          other.version == this.version &&
          other.url == this.url &&
          other.mimeType == this.mimeType &&
          other.durationMs == this.durationMs &&
          other.byteSize == this.byteSize &&
          other.sha256 == this.sha256 &&
          other.availability == this.availability);
}

class AudioAssetsCompanion extends UpdateCompanion<AudioAsset> {
  final Value<String> id;
  final Value<String> editionId;
  final Value<int> surahNumber;
  final Value<int> version;
  final Value<String> url;
  final Value<String> mimeType;
  final Value<int?> durationMs;
  final Value<int?> byteSize;
  final Value<String?> sha256;
  final Value<String> availability;
  final Value<int> rowid;
  const AudioAssetsCompanion({
    this.id = const Value.absent(),
    this.editionId = const Value.absent(),
    this.surahNumber = const Value.absent(),
    this.version = const Value.absent(),
    this.url = const Value.absent(),
    this.mimeType = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.byteSize = const Value.absent(),
    this.sha256 = const Value.absent(),
    this.availability = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AudioAssetsCompanion.insert({
    required String id,
    required String editionId,
    required int surahNumber,
    required int version,
    required String url,
    required String mimeType,
    this.durationMs = const Value.absent(),
    this.byteSize = const Value.absent(),
    this.sha256 = const Value.absent(),
    required String availability,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       editionId = Value(editionId),
       surahNumber = Value(surahNumber),
       version = Value(version),
       url = Value(url),
       mimeType = Value(mimeType),
       availability = Value(availability);
  static Insertable<AudioAsset> custom({
    Expression<String>? id,
    Expression<String>? editionId,
    Expression<int>? surahNumber,
    Expression<int>? version,
    Expression<String>? url,
    Expression<String>? mimeType,
    Expression<int>? durationMs,
    Expression<int>? byteSize,
    Expression<String>? sha256,
    Expression<String>? availability,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (editionId != null) 'edition_id': editionId,
      if (surahNumber != null) 'surah_number': surahNumber,
      if (version != null) 'version': version,
      if (url != null) 'url': url,
      if (mimeType != null) 'mime_type': mimeType,
      if (durationMs != null) 'duration_ms': durationMs,
      if (byteSize != null) 'byte_size': byteSize,
      if (sha256 != null) 'sha256': sha256,
      if (availability != null) 'availability': availability,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AudioAssetsCompanion copyWith({
    Value<String>? id,
    Value<String>? editionId,
    Value<int>? surahNumber,
    Value<int>? version,
    Value<String>? url,
    Value<String>? mimeType,
    Value<int?>? durationMs,
    Value<int?>? byteSize,
    Value<String?>? sha256,
    Value<String>? availability,
    Value<int>? rowid,
  }) {
    return AudioAssetsCompanion(
      id: id ?? this.id,
      editionId: editionId ?? this.editionId,
      surahNumber: surahNumber ?? this.surahNumber,
      version: version ?? this.version,
      url: url ?? this.url,
      mimeType: mimeType ?? this.mimeType,
      durationMs: durationMs ?? this.durationMs,
      byteSize: byteSize ?? this.byteSize,
      sha256: sha256 ?? this.sha256,
      availability: availability ?? this.availability,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (editionId.present) {
      map['edition_id'] = Variable<String>(editionId.value);
    }
    if (surahNumber.present) {
      map['surah_number'] = Variable<int>(surahNumber.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (url.present) {
      map['url'] = Variable<String>(url.value);
    }
    if (mimeType.present) {
      map['mime_type'] = Variable<String>(mimeType.value);
    }
    if (durationMs.present) {
      map['duration_ms'] = Variable<int>(durationMs.value);
    }
    if (byteSize.present) {
      map['byte_size'] = Variable<int>(byteSize.value);
    }
    if (sha256.present) {
      map['sha256'] = Variable<String>(sha256.value);
    }
    if (availability.present) {
      map['availability'] = Variable<String>(availability.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AudioAssetsCompanion(')
          ..write('id: $id, ')
          ..write('editionId: $editionId, ')
          ..write('surahNumber: $surahNumber, ')
          ..write('version: $version, ')
          ..write('url: $url, ')
          ..write('mimeType: $mimeType, ')
          ..write('durationMs: $durationMs, ')
          ..write('byteSize: $byteSize, ')
          ..write('sha256: $sha256, ')
          ..write('availability: $availability, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class SavedPassages extends Table with TableInfo<SavedPassages, SavedPassage> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  SavedPassages(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _assetIdMeta = const VerificationMeta(
    'assetId',
  );
  late final GeneratedColumn<String> assetId = GeneratedColumn<String>(
    'asset_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES audio_assets(id)',
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (length(trim(title)) > 0)',
  );
  static const VerificationMeta _startMsMeta = const VerificationMeta(
    'startMs',
  );
  late final GeneratedColumn<int> startMs = GeneratedColumn<int>(
    'start_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (start_ms >= 0)',
  );
  static const VerificationMeta _endMsMeta = const VerificationMeta('endMs');
  late final GeneratedColumn<int> endMs = GeneratedColumn<int>(
    'end_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (end_ms - start_ms >= 1000)',
  );
  static const VerificationMeta _repeatModeMeta = const VerificationMeta(
    'repeatMode',
  );
  late final GeneratedColumn<String> repeatMode = GeneratedColumn<String>(
    'repeat_mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK (repeat_mode IN (\'finite\', \'continuous\'))',
  );
  static const VerificationMeta _playCountMeta = const VerificationMeta(
    'playCount',
  );
  late final GeneratedColumn<int> playCount = GeneratedColumn<int>(
    'play_count',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _gapMsMeta = const VerificationMeta('gapMs');
  late final GeneratedColumn<int> gapMs = GeneratedColumn<int>(
    'gap_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints:
        'NOT NULL DEFAULT 0 CHECK (gap_ms IN (0, 2000, 5000, 10000))',
    defaultValue: const CustomExpression('0'),
  );
  static const VerificationMeta _speedMeta = const VerificationMeta('speed');
  late final GeneratedColumn<double> speed = GeneratedColumn<double>(
    'speed',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    $customConstraints:
        'NOT NULL DEFAULT 1.0 CHECK (speed BETWEEN 0.5 AND 2.0)',
    defaultValue: const CustomExpression('1.0'),
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _createdUtcMsMeta = const VerificationMeta(
    'createdUtcMs',
  );
  late final GeneratedColumn<int> createdUtcMs = GeneratedColumn<int>(
    'created_utc_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _updatedUtcMsMeta = const VerificationMeta(
    'updatedUtcMs',
  );
  late final GeneratedColumn<int> updatedUtcMs = GeneratedColumn<int>(
    'updated_utc_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (updated_utc_ms >= created_utc_ms)',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    assetId,
    title,
    startMs,
    endMs,
    repeatMode,
    playCount,
    gapMs,
    speed,
    note,
    createdUtcMs,
    updatedUtcMs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'saved_passages';
  @override
  VerificationContext validateIntegrity(
    Insertable<SavedPassage> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('asset_id')) {
      context.handle(
        _assetIdMeta,
        assetId.isAcceptableOrUnknown(data['asset_id']!, _assetIdMeta),
      );
    } else if (isInserting) {
      context.missing(_assetIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('start_ms')) {
      context.handle(
        _startMsMeta,
        startMs.isAcceptableOrUnknown(data['start_ms']!, _startMsMeta),
      );
    } else if (isInserting) {
      context.missing(_startMsMeta);
    }
    if (data.containsKey('end_ms')) {
      context.handle(
        _endMsMeta,
        endMs.isAcceptableOrUnknown(data['end_ms']!, _endMsMeta),
      );
    } else if (isInserting) {
      context.missing(_endMsMeta);
    }
    if (data.containsKey('repeat_mode')) {
      context.handle(
        _repeatModeMeta,
        repeatMode.isAcceptableOrUnknown(data['repeat_mode']!, _repeatModeMeta),
      );
    } else if (isInserting) {
      context.missing(_repeatModeMeta);
    }
    if (data.containsKey('play_count')) {
      context.handle(
        _playCountMeta,
        playCount.isAcceptableOrUnknown(data['play_count']!, _playCountMeta),
      );
    }
    if (data.containsKey('gap_ms')) {
      context.handle(
        _gapMsMeta,
        gapMs.isAcceptableOrUnknown(data['gap_ms']!, _gapMsMeta),
      );
    }
    if (data.containsKey('speed')) {
      context.handle(
        _speedMeta,
        speed.isAcceptableOrUnknown(data['speed']!, _speedMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('created_utc_ms')) {
      context.handle(
        _createdUtcMsMeta,
        createdUtcMs.isAcceptableOrUnknown(
          data['created_utc_ms']!,
          _createdUtcMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdUtcMsMeta);
    }
    if (data.containsKey('updated_utc_ms')) {
      context.handle(
        _updatedUtcMsMeta,
        updatedUtcMs.isAcceptableOrUnknown(
          data['updated_utc_ms']!,
          _updatedUtcMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_updatedUtcMsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SavedPassage map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SavedPassage(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      assetId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}asset_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      startMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_ms'],
      )!,
      endMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}end_ms'],
      )!,
      repeatMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}repeat_mode'],
      )!,
      playCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}play_count'],
      ),
      gapMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}gap_ms'],
      )!,
      speed: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}speed'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      createdUtcMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_utc_ms'],
      )!,
      updatedUtcMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_utc_ms'],
      )!,
    );
  }

  @override
  SavedPassages createAlias(String alias) {
    return SavedPassages(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const [
    'CHECK((repeat_mode = \'finite\' AND play_count IS NOT NULL AND play_count BETWEEN 1 AND 999)OR(repeat_mode = \'continuous\' AND play_count IS NULL))',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class SavedPassage extends DataClass implements Insertable<SavedPassage> {
  final String id;
  final String assetId;
  final String title;
  final int startMs;
  final int endMs;
  final String repeatMode;
  final int? playCount;
  final int gapMs;
  final double speed;
  final String? note;
  final int createdUtcMs;
  final int updatedUtcMs;
  const SavedPassage({
    required this.id,
    required this.assetId,
    required this.title,
    required this.startMs,
    required this.endMs,
    required this.repeatMode,
    this.playCount,
    required this.gapMs,
    required this.speed,
    this.note,
    required this.createdUtcMs,
    required this.updatedUtcMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['asset_id'] = Variable<String>(assetId);
    map['title'] = Variable<String>(title);
    map['start_ms'] = Variable<int>(startMs);
    map['end_ms'] = Variable<int>(endMs);
    map['repeat_mode'] = Variable<String>(repeatMode);
    if (!nullToAbsent || playCount != null) {
      map['play_count'] = Variable<int>(playCount);
    }
    map['gap_ms'] = Variable<int>(gapMs);
    map['speed'] = Variable<double>(speed);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['created_utc_ms'] = Variable<int>(createdUtcMs);
    map['updated_utc_ms'] = Variable<int>(updatedUtcMs);
    return map;
  }

  SavedPassagesCompanion toCompanion(bool nullToAbsent) {
    return SavedPassagesCompanion(
      id: Value(id),
      assetId: Value(assetId),
      title: Value(title),
      startMs: Value(startMs),
      endMs: Value(endMs),
      repeatMode: Value(repeatMode),
      playCount: playCount == null && nullToAbsent
          ? const Value.absent()
          : Value(playCount),
      gapMs: Value(gapMs),
      speed: Value(speed),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      createdUtcMs: Value(createdUtcMs),
      updatedUtcMs: Value(updatedUtcMs),
    );
  }

  factory SavedPassage.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SavedPassage(
      id: serializer.fromJson<String>(json['id']),
      assetId: serializer.fromJson<String>(json['asset_id']),
      title: serializer.fromJson<String>(json['title']),
      startMs: serializer.fromJson<int>(json['start_ms']),
      endMs: serializer.fromJson<int>(json['end_ms']),
      repeatMode: serializer.fromJson<String>(json['repeat_mode']),
      playCount: serializer.fromJson<int?>(json['play_count']),
      gapMs: serializer.fromJson<int>(json['gap_ms']),
      speed: serializer.fromJson<double>(json['speed']),
      note: serializer.fromJson<String?>(json['note']),
      createdUtcMs: serializer.fromJson<int>(json['created_utc_ms']),
      updatedUtcMs: serializer.fromJson<int>(json['updated_utc_ms']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'asset_id': serializer.toJson<String>(assetId),
      'title': serializer.toJson<String>(title),
      'start_ms': serializer.toJson<int>(startMs),
      'end_ms': serializer.toJson<int>(endMs),
      'repeat_mode': serializer.toJson<String>(repeatMode),
      'play_count': serializer.toJson<int?>(playCount),
      'gap_ms': serializer.toJson<int>(gapMs),
      'speed': serializer.toJson<double>(speed),
      'note': serializer.toJson<String?>(note),
      'created_utc_ms': serializer.toJson<int>(createdUtcMs),
      'updated_utc_ms': serializer.toJson<int>(updatedUtcMs),
    };
  }

  SavedPassage copyWith({
    String? id,
    String? assetId,
    String? title,
    int? startMs,
    int? endMs,
    String? repeatMode,
    Value<int?> playCount = const Value.absent(),
    int? gapMs,
    double? speed,
    Value<String?> note = const Value.absent(),
    int? createdUtcMs,
    int? updatedUtcMs,
  }) => SavedPassage(
    id: id ?? this.id,
    assetId: assetId ?? this.assetId,
    title: title ?? this.title,
    startMs: startMs ?? this.startMs,
    endMs: endMs ?? this.endMs,
    repeatMode: repeatMode ?? this.repeatMode,
    playCount: playCount.present ? playCount.value : this.playCount,
    gapMs: gapMs ?? this.gapMs,
    speed: speed ?? this.speed,
    note: note.present ? note.value : this.note,
    createdUtcMs: createdUtcMs ?? this.createdUtcMs,
    updatedUtcMs: updatedUtcMs ?? this.updatedUtcMs,
  );
  SavedPassage copyWithCompanion(SavedPassagesCompanion data) {
    return SavedPassage(
      id: data.id.present ? data.id.value : this.id,
      assetId: data.assetId.present ? data.assetId.value : this.assetId,
      title: data.title.present ? data.title.value : this.title,
      startMs: data.startMs.present ? data.startMs.value : this.startMs,
      endMs: data.endMs.present ? data.endMs.value : this.endMs,
      repeatMode: data.repeatMode.present
          ? data.repeatMode.value
          : this.repeatMode,
      playCount: data.playCount.present ? data.playCount.value : this.playCount,
      gapMs: data.gapMs.present ? data.gapMs.value : this.gapMs,
      speed: data.speed.present ? data.speed.value : this.speed,
      note: data.note.present ? data.note.value : this.note,
      createdUtcMs: data.createdUtcMs.present
          ? data.createdUtcMs.value
          : this.createdUtcMs,
      updatedUtcMs: data.updatedUtcMs.present
          ? data.updatedUtcMs.value
          : this.updatedUtcMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SavedPassage(')
          ..write('id: $id, ')
          ..write('assetId: $assetId, ')
          ..write('title: $title, ')
          ..write('startMs: $startMs, ')
          ..write('endMs: $endMs, ')
          ..write('repeatMode: $repeatMode, ')
          ..write('playCount: $playCount, ')
          ..write('gapMs: $gapMs, ')
          ..write('speed: $speed, ')
          ..write('note: $note, ')
          ..write('createdUtcMs: $createdUtcMs, ')
          ..write('updatedUtcMs: $updatedUtcMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    assetId,
    title,
    startMs,
    endMs,
    repeatMode,
    playCount,
    gapMs,
    speed,
    note,
    createdUtcMs,
    updatedUtcMs,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SavedPassage &&
          other.id == this.id &&
          other.assetId == this.assetId &&
          other.title == this.title &&
          other.startMs == this.startMs &&
          other.endMs == this.endMs &&
          other.repeatMode == this.repeatMode &&
          other.playCount == this.playCount &&
          other.gapMs == this.gapMs &&
          other.speed == this.speed &&
          other.note == this.note &&
          other.createdUtcMs == this.createdUtcMs &&
          other.updatedUtcMs == this.updatedUtcMs);
}

class SavedPassagesCompanion extends UpdateCompanion<SavedPassage> {
  final Value<String> id;
  final Value<String> assetId;
  final Value<String> title;
  final Value<int> startMs;
  final Value<int> endMs;
  final Value<String> repeatMode;
  final Value<int?> playCount;
  final Value<int> gapMs;
  final Value<double> speed;
  final Value<String?> note;
  final Value<int> createdUtcMs;
  final Value<int> updatedUtcMs;
  final Value<int> rowid;
  const SavedPassagesCompanion({
    this.id = const Value.absent(),
    this.assetId = const Value.absent(),
    this.title = const Value.absent(),
    this.startMs = const Value.absent(),
    this.endMs = const Value.absent(),
    this.repeatMode = const Value.absent(),
    this.playCount = const Value.absent(),
    this.gapMs = const Value.absent(),
    this.speed = const Value.absent(),
    this.note = const Value.absent(),
    this.createdUtcMs = const Value.absent(),
    this.updatedUtcMs = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SavedPassagesCompanion.insert({
    required String id,
    required String assetId,
    required String title,
    required int startMs,
    required int endMs,
    required String repeatMode,
    this.playCount = const Value.absent(),
    this.gapMs = const Value.absent(),
    this.speed = const Value.absent(),
    this.note = const Value.absent(),
    required int createdUtcMs,
    required int updatedUtcMs,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       assetId = Value(assetId),
       title = Value(title),
       startMs = Value(startMs),
       endMs = Value(endMs),
       repeatMode = Value(repeatMode),
       createdUtcMs = Value(createdUtcMs),
       updatedUtcMs = Value(updatedUtcMs);
  static Insertable<SavedPassage> custom({
    Expression<String>? id,
    Expression<String>? assetId,
    Expression<String>? title,
    Expression<int>? startMs,
    Expression<int>? endMs,
    Expression<String>? repeatMode,
    Expression<int>? playCount,
    Expression<int>? gapMs,
    Expression<double>? speed,
    Expression<String>? note,
    Expression<int>? createdUtcMs,
    Expression<int>? updatedUtcMs,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (assetId != null) 'asset_id': assetId,
      if (title != null) 'title': title,
      if (startMs != null) 'start_ms': startMs,
      if (endMs != null) 'end_ms': endMs,
      if (repeatMode != null) 'repeat_mode': repeatMode,
      if (playCount != null) 'play_count': playCount,
      if (gapMs != null) 'gap_ms': gapMs,
      if (speed != null) 'speed': speed,
      if (note != null) 'note': note,
      if (createdUtcMs != null) 'created_utc_ms': createdUtcMs,
      if (updatedUtcMs != null) 'updated_utc_ms': updatedUtcMs,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SavedPassagesCompanion copyWith({
    Value<String>? id,
    Value<String>? assetId,
    Value<String>? title,
    Value<int>? startMs,
    Value<int>? endMs,
    Value<String>? repeatMode,
    Value<int?>? playCount,
    Value<int>? gapMs,
    Value<double>? speed,
    Value<String?>? note,
    Value<int>? createdUtcMs,
    Value<int>? updatedUtcMs,
    Value<int>? rowid,
  }) {
    return SavedPassagesCompanion(
      id: id ?? this.id,
      assetId: assetId ?? this.assetId,
      title: title ?? this.title,
      startMs: startMs ?? this.startMs,
      endMs: endMs ?? this.endMs,
      repeatMode: repeatMode ?? this.repeatMode,
      playCount: playCount ?? this.playCount,
      gapMs: gapMs ?? this.gapMs,
      speed: speed ?? this.speed,
      note: note ?? this.note,
      createdUtcMs: createdUtcMs ?? this.createdUtcMs,
      updatedUtcMs: updatedUtcMs ?? this.updatedUtcMs,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (assetId.present) {
      map['asset_id'] = Variable<String>(assetId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (startMs.present) {
      map['start_ms'] = Variable<int>(startMs.value);
    }
    if (endMs.present) {
      map['end_ms'] = Variable<int>(endMs.value);
    }
    if (repeatMode.present) {
      map['repeat_mode'] = Variable<String>(repeatMode.value);
    }
    if (playCount.present) {
      map['play_count'] = Variable<int>(playCount.value);
    }
    if (gapMs.present) {
      map['gap_ms'] = Variable<int>(gapMs.value);
    }
    if (speed.present) {
      map['speed'] = Variable<double>(speed.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (createdUtcMs.present) {
      map['created_utc_ms'] = Variable<int>(createdUtcMs.value);
    }
    if (updatedUtcMs.present) {
      map['updated_utc_ms'] = Variable<int>(updatedUtcMs.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SavedPassagesCompanion(')
          ..write('id: $id, ')
          ..write('assetId: $assetId, ')
          ..write('title: $title, ')
          ..write('startMs: $startMs, ')
          ..write('endMs: $endMs, ')
          ..write('repeatMode: $repeatMode, ')
          ..write('playCount: $playCount, ')
          ..write('gapMs: $gapMs, ')
          ..write('speed: $speed, ')
          ..write('note: $note, ')
          ..write('createdUtcMs: $createdUtcMs, ')
          ..write('updatedUtcMs: $updatedUtcMs, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class Favorites extends Table with TableInfo<Favorites, Favorite> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Favorites(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (type IN (\'surah\', \'passage\'))',
  );
  static const VerificationMeta _targetIdMeta = const VerificationMeta(
    'targetId',
  );
  late final GeneratedColumn<String> targetId = GeneratedColumn<String>(
    'target_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _createdUtcMsMeta = const VerificationMeta(
    'createdUtcMs',
  );
  late final GeneratedColumn<int> createdUtcMs = GeneratedColumn<int>(
    'created_utc_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [type, targetId, createdUtcMs];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'favorites';
  @override
  VerificationContext validateIntegrity(
    Insertable<Favorite> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('target_id')) {
      context.handle(
        _targetIdMeta,
        targetId.isAcceptableOrUnknown(data['target_id']!, _targetIdMeta),
      );
    } else if (isInserting) {
      context.missing(_targetIdMeta);
    }
    if (data.containsKey('created_utc_ms')) {
      context.handle(
        _createdUtcMsMeta,
        createdUtcMs.isAcceptableOrUnknown(
          data['created_utc_ms']!,
          _createdUtcMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdUtcMsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {type, targetId};
  @override
  Favorite map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Favorite(
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      targetId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_id'],
      )!,
      createdUtcMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_utc_ms'],
      )!,
    );
  }

  @override
  Favorites createAlias(String alias) {
    return Favorites(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const ['PRIMARY KEY(type, target_id)'];
  @override
  bool get dontWriteConstraints => true;
}

class Favorite extends DataClass implements Insertable<Favorite> {
  final String type;
  final String targetId;
  final int createdUtcMs;
  const Favorite({
    required this.type,
    required this.targetId,
    required this.createdUtcMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['type'] = Variable<String>(type);
    map['target_id'] = Variable<String>(targetId);
    map['created_utc_ms'] = Variable<int>(createdUtcMs);
    return map;
  }

  FavoritesCompanion toCompanion(bool nullToAbsent) {
    return FavoritesCompanion(
      type: Value(type),
      targetId: Value(targetId),
      createdUtcMs: Value(createdUtcMs),
    );
  }

  factory Favorite.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Favorite(
      type: serializer.fromJson<String>(json['type']),
      targetId: serializer.fromJson<String>(json['target_id']),
      createdUtcMs: serializer.fromJson<int>(json['created_utc_ms']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'type': serializer.toJson<String>(type),
      'target_id': serializer.toJson<String>(targetId),
      'created_utc_ms': serializer.toJson<int>(createdUtcMs),
    };
  }

  Favorite copyWith({String? type, String? targetId, int? createdUtcMs}) =>
      Favorite(
        type: type ?? this.type,
        targetId: targetId ?? this.targetId,
        createdUtcMs: createdUtcMs ?? this.createdUtcMs,
      );
  Favorite copyWithCompanion(FavoritesCompanion data) {
    return Favorite(
      type: data.type.present ? data.type.value : this.type,
      targetId: data.targetId.present ? data.targetId.value : this.targetId,
      createdUtcMs: data.createdUtcMs.present
          ? data.createdUtcMs.value
          : this.createdUtcMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Favorite(')
          ..write('type: $type, ')
          ..write('targetId: $targetId, ')
          ..write('createdUtcMs: $createdUtcMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(type, targetId, createdUtcMs);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Favorite &&
          other.type == this.type &&
          other.targetId == this.targetId &&
          other.createdUtcMs == this.createdUtcMs);
}

class FavoritesCompanion extends UpdateCompanion<Favorite> {
  final Value<String> type;
  final Value<String> targetId;
  final Value<int> createdUtcMs;
  final Value<int> rowid;
  const FavoritesCompanion({
    this.type = const Value.absent(),
    this.targetId = const Value.absent(),
    this.createdUtcMs = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FavoritesCompanion.insert({
    required String type,
    required String targetId,
    required int createdUtcMs,
    this.rowid = const Value.absent(),
  }) : type = Value(type),
       targetId = Value(targetId),
       createdUtcMs = Value(createdUtcMs);
  static Insertable<Favorite> custom({
    Expression<String>? type,
    Expression<String>? targetId,
    Expression<int>? createdUtcMs,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (type != null) 'type': type,
      if (targetId != null) 'target_id': targetId,
      if (createdUtcMs != null) 'created_utc_ms': createdUtcMs,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FavoritesCompanion copyWith({
    Value<String>? type,
    Value<String>? targetId,
    Value<int>? createdUtcMs,
    Value<int>? rowid,
  }) {
    return FavoritesCompanion(
      type: type ?? this.type,
      targetId: targetId ?? this.targetId,
      createdUtcMs: createdUtcMs ?? this.createdUtcMs,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (targetId.present) {
      map['target_id'] = Variable<String>(targetId.value);
    }
    if (createdUtcMs.present) {
      map['created_utc_ms'] = Variable<int>(createdUtcMs.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FavoritesCompanion(')
          ..write('type: $type, ')
          ..write('targetId: $targetId, ')
          ..write('createdUtcMs: $createdUtcMs, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class Downloads extends Table with TableInfo<Downloads, Download> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Downloads(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _assetIdMeta = const VerificationMeta(
    'assetId',
  );
  late final GeneratedColumn<String> assetId = GeneratedColumn<String>(
    'asset_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY REFERENCES audio_assets(id)',
  );
  static const VerificationMeta _relativePathMeta = const VerificationMeta(
    'relativePath',
  );
  late final GeneratedColumn<String> relativePath = GeneratedColumn<String>(
    'relative_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'CHECK (relative_path <> \'\' AND relative_path NOT LIKE \'/%\' AND relative_path NOT LIKE \'%..%\' AND relative_path NOT LIKE \'%:%\' AND relative_path NOT LIKE \'%\\%\')',
  );
  static const VerificationMeta _nativeTaskIdMeta = const VerificationMeta(
    'nativeTaskId',
  );
  late final GeneratedColumn<String> nativeTaskId = GeneratedColumn<String>(
    'native_task_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  late final GeneratedColumn<String> state = GeneratedColumn<String>(
    'state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (state IN (\'queued\', \'running\', \'verifying\', \'verified\', \'failed\', \'cancelled\'))',
  );
  static const VerificationMeta _receivedBytesMeta = const VerificationMeta(
    'receivedBytes',
  );
  late final GeneratedColumn<int> receivedBytes = GeneratedColumn<int>(
    'received_bytes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (received_bytes >= 0)',
  );
  static const VerificationMeta _verifiedSha256Meta = const VerificationMeta(
    'verifiedSha256',
  );
  late final GeneratedColumn<String> verifiedSha256 = GeneratedColumn<String>(
    'verified_sha256',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _updatedUtcMsMeta = const VerificationMeta(
    'updatedUtcMs',
  );
  late final GeneratedColumn<int> updatedUtcMs = GeneratedColumn<int>(
    'updated_utc_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [
    assetId,
    relativePath,
    nativeTaskId,
    state,
    receivedBytes,
    verifiedSha256,
    updatedUtcMs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'downloads';
  @override
  VerificationContext validateIntegrity(
    Insertable<Download> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('asset_id')) {
      context.handle(
        _assetIdMeta,
        assetId.isAcceptableOrUnknown(data['asset_id']!, _assetIdMeta),
      );
    } else if (isInserting) {
      context.missing(_assetIdMeta);
    }
    if (data.containsKey('relative_path')) {
      context.handle(
        _relativePathMeta,
        relativePath.isAcceptableOrUnknown(
          data['relative_path']!,
          _relativePathMeta,
        ),
      );
    }
    if (data.containsKey('native_task_id')) {
      context.handle(
        _nativeTaskIdMeta,
        nativeTaskId.isAcceptableOrUnknown(
          data['native_task_id']!,
          _nativeTaskIdMeta,
        ),
      );
    }
    if (data.containsKey('state')) {
      context.handle(
        _stateMeta,
        state.isAcceptableOrUnknown(data['state']!, _stateMeta),
      );
    } else if (isInserting) {
      context.missing(_stateMeta);
    }
    if (data.containsKey('received_bytes')) {
      context.handle(
        _receivedBytesMeta,
        receivedBytes.isAcceptableOrUnknown(
          data['received_bytes']!,
          _receivedBytesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_receivedBytesMeta);
    }
    if (data.containsKey('verified_sha256')) {
      context.handle(
        _verifiedSha256Meta,
        verifiedSha256.isAcceptableOrUnknown(
          data['verified_sha256']!,
          _verifiedSha256Meta,
        ),
      );
    }
    if (data.containsKey('updated_utc_ms')) {
      context.handle(
        _updatedUtcMsMeta,
        updatedUtcMs.isAcceptableOrUnknown(
          data['updated_utc_ms']!,
          _updatedUtcMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_updatedUtcMsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {assetId};
  @override
  Download map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Download(
      assetId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}asset_id'],
      )!,
      relativePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}relative_path'],
      ),
      nativeTaskId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}native_task_id'],
      ),
      state: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}state'],
      )!,
      receivedBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}received_bytes'],
      )!,
      verifiedSha256: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}verified_sha256'],
      ),
      updatedUtcMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_utc_ms'],
      )!,
    );
  }

  @override
  Downloads createAlias(String alias) {
    return Downloads(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const [
    'CHECK(state <> \'verified\' OR(relative_path IS NOT NULL AND verified_sha256 IS NOT NULL))',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class Download extends DataClass implements Insertable<Download> {
  final String assetId;
  final String? relativePath;
  final String? nativeTaskId;
  final String state;
  final int receivedBytes;
  final String? verifiedSha256;
  final int updatedUtcMs;
  const Download({
    required this.assetId,
    this.relativePath,
    this.nativeTaskId,
    required this.state,
    required this.receivedBytes,
    this.verifiedSha256,
    required this.updatedUtcMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['asset_id'] = Variable<String>(assetId);
    if (!nullToAbsent || relativePath != null) {
      map['relative_path'] = Variable<String>(relativePath);
    }
    if (!nullToAbsent || nativeTaskId != null) {
      map['native_task_id'] = Variable<String>(nativeTaskId);
    }
    map['state'] = Variable<String>(state);
    map['received_bytes'] = Variable<int>(receivedBytes);
    if (!nullToAbsent || verifiedSha256 != null) {
      map['verified_sha256'] = Variable<String>(verifiedSha256);
    }
    map['updated_utc_ms'] = Variable<int>(updatedUtcMs);
    return map;
  }

  DownloadsCompanion toCompanion(bool nullToAbsent) {
    return DownloadsCompanion(
      assetId: Value(assetId),
      relativePath: relativePath == null && nullToAbsent
          ? const Value.absent()
          : Value(relativePath),
      nativeTaskId: nativeTaskId == null && nullToAbsent
          ? const Value.absent()
          : Value(nativeTaskId),
      state: Value(state),
      receivedBytes: Value(receivedBytes),
      verifiedSha256: verifiedSha256 == null && nullToAbsent
          ? const Value.absent()
          : Value(verifiedSha256),
      updatedUtcMs: Value(updatedUtcMs),
    );
  }

  factory Download.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Download(
      assetId: serializer.fromJson<String>(json['asset_id']),
      relativePath: serializer.fromJson<String?>(json['relative_path']),
      nativeTaskId: serializer.fromJson<String?>(json['native_task_id']),
      state: serializer.fromJson<String>(json['state']),
      receivedBytes: serializer.fromJson<int>(json['received_bytes']),
      verifiedSha256: serializer.fromJson<String?>(json['verified_sha256']),
      updatedUtcMs: serializer.fromJson<int>(json['updated_utc_ms']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'asset_id': serializer.toJson<String>(assetId),
      'relative_path': serializer.toJson<String?>(relativePath),
      'native_task_id': serializer.toJson<String?>(nativeTaskId),
      'state': serializer.toJson<String>(state),
      'received_bytes': serializer.toJson<int>(receivedBytes),
      'verified_sha256': serializer.toJson<String?>(verifiedSha256),
      'updated_utc_ms': serializer.toJson<int>(updatedUtcMs),
    };
  }

  Download copyWith({
    String? assetId,
    Value<String?> relativePath = const Value.absent(),
    Value<String?> nativeTaskId = const Value.absent(),
    String? state,
    int? receivedBytes,
    Value<String?> verifiedSha256 = const Value.absent(),
    int? updatedUtcMs,
  }) => Download(
    assetId: assetId ?? this.assetId,
    relativePath: relativePath.present ? relativePath.value : this.relativePath,
    nativeTaskId: nativeTaskId.present ? nativeTaskId.value : this.nativeTaskId,
    state: state ?? this.state,
    receivedBytes: receivedBytes ?? this.receivedBytes,
    verifiedSha256: verifiedSha256.present
        ? verifiedSha256.value
        : this.verifiedSha256,
    updatedUtcMs: updatedUtcMs ?? this.updatedUtcMs,
  );
  Download copyWithCompanion(DownloadsCompanion data) {
    return Download(
      assetId: data.assetId.present ? data.assetId.value : this.assetId,
      relativePath: data.relativePath.present
          ? data.relativePath.value
          : this.relativePath,
      nativeTaskId: data.nativeTaskId.present
          ? data.nativeTaskId.value
          : this.nativeTaskId,
      state: data.state.present ? data.state.value : this.state,
      receivedBytes: data.receivedBytes.present
          ? data.receivedBytes.value
          : this.receivedBytes,
      verifiedSha256: data.verifiedSha256.present
          ? data.verifiedSha256.value
          : this.verifiedSha256,
      updatedUtcMs: data.updatedUtcMs.present
          ? data.updatedUtcMs.value
          : this.updatedUtcMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Download(')
          ..write('assetId: $assetId, ')
          ..write('relativePath: $relativePath, ')
          ..write('nativeTaskId: $nativeTaskId, ')
          ..write('state: $state, ')
          ..write('receivedBytes: $receivedBytes, ')
          ..write('verifiedSha256: $verifiedSha256, ')
          ..write('updatedUtcMs: $updatedUtcMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    assetId,
    relativePath,
    nativeTaskId,
    state,
    receivedBytes,
    verifiedSha256,
    updatedUtcMs,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Download &&
          other.assetId == this.assetId &&
          other.relativePath == this.relativePath &&
          other.nativeTaskId == this.nativeTaskId &&
          other.state == this.state &&
          other.receivedBytes == this.receivedBytes &&
          other.verifiedSha256 == this.verifiedSha256 &&
          other.updatedUtcMs == this.updatedUtcMs);
}

class DownloadsCompanion extends UpdateCompanion<Download> {
  final Value<String> assetId;
  final Value<String?> relativePath;
  final Value<String?> nativeTaskId;
  final Value<String> state;
  final Value<int> receivedBytes;
  final Value<String?> verifiedSha256;
  final Value<int> updatedUtcMs;
  final Value<int> rowid;
  const DownloadsCompanion({
    this.assetId = const Value.absent(),
    this.relativePath = const Value.absent(),
    this.nativeTaskId = const Value.absent(),
    this.state = const Value.absent(),
    this.receivedBytes = const Value.absent(),
    this.verifiedSha256 = const Value.absent(),
    this.updatedUtcMs = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DownloadsCompanion.insert({
    required String assetId,
    this.relativePath = const Value.absent(),
    this.nativeTaskId = const Value.absent(),
    required String state,
    required int receivedBytes,
    this.verifiedSha256 = const Value.absent(),
    required int updatedUtcMs,
    this.rowid = const Value.absent(),
  }) : assetId = Value(assetId),
       state = Value(state),
       receivedBytes = Value(receivedBytes),
       updatedUtcMs = Value(updatedUtcMs);
  static Insertable<Download> custom({
    Expression<String>? assetId,
    Expression<String>? relativePath,
    Expression<String>? nativeTaskId,
    Expression<String>? state,
    Expression<int>? receivedBytes,
    Expression<String>? verifiedSha256,
    Expression<int>? updatedUtcMs,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (assetId != null) 'asset_id': assetId,
      if (relativePath != null) 'relative_path': relativePath,
      if (nativeTaskId != null) 'native_task_id': nativeTaskId,
      if (state != null) 'state': state,
      if (receivedBytes != null) 'received_bytes': receivedBytes,
      if (verifiedSha256 != null) 'verified_sha256': verifiedSha256,
      if (updatedUtcMs != null) 'updated_utc_ms': updatedUtcMs,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DownloadsCompanion copyWith({
    Value<String>? assetId,
    Value<String?>? relativePath,
    Value<String?>? nativeTaskId,
    Value<String>? state,
    Value<int>? receivedBytes,
    Value<String?>? verifiedSha256,
    Value<int>? updatedUtcMs,
    Value<int>? rowid,
  }) {
    return DownloadsCompanion(
      assetId: assetId ?? this.assetId,
      relativePath: relativePath ?? this.relativePath,
      nativeTaskId: nativeTaskId ?? this.nativeTaskId,
      state: state ?? this.state,
      receivedBytes: receivedBytes ?? this.receivedBytes,
      verifiedSha256: verifiedSha256 ?? this.verifiedSha256,
      updatedUtcMs: updatedUtcMs ?? this.updatedUtcMs,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (assetId.present) {
      map['asset_id'] = Variable<String>(assetId.value);
    }
    if (relativePath.present) {
      map['relative_path'] = Variable<String>(relativePath.value);
    }
    if (nativeTaskId.present) {
      map['native_task_id'] = Variable<String>(nativeTaskId.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(state.value);
    }
    if (receivedBytes.present) {
      map['received_bytes'] = Variable<int>(receivedBytes.value);
    }
    if (verifiedSha256.present) {
      map['verified_sha256'] = Variable<String>(verifiedSha256.value);
    }
    if (updatedUtcMs.present) {
      map['updated_utc_ms'] = Variable<int>(updatedUtcMs.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DownloadsCompanion(')
          ..write('assetId: $assetId, ')
          ..write('relativePath: $relativePath, ')
          ..write('nativeTaskId: $nativeTaskId, ')
          ..write('state: $state, ')
          ..write('receivedBytes: $receivedBytes, ')
          ..write('verifiedSha256: $verifiedSha256, ')
          ..write('updatedUtcMs: $updatedUtcMs, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class PlaybackCheckpoints extends Table
    with TableInfo<PlaybackCheckpoints, PlaybackCheckpoint> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  PlaybackCheckpoints(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _scopeMeta = const VerificationMeta('scope');
  late final GeneratedColumn<String> scope = GeneratedColumn<String>(
    'scope',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (scope IN (\'full\', \'passage\'))',
  );
  static const VerificationMeta _assetIdMeta = const VerificationMeta(
    'assetId',
  );
  late final GeneratedColumn<String> assetId = GeneratedColumn<String>(
    'asset_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES audio_assets(id)',
  );
  static const VerificationMeta _passageIdMeta = const VerificationMeta(
    'passageId',
  );
  late final GeneratedColumn<String> passageId = GeneratedColumn<String>(
    'passage_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'REFERENCES saved_passages(id)ON DELETE SET NULL',
  );
  static const VerificationMeta _currentPassMeta = const VerificationMeta(
    'currentPass',
  );
  late final GeneratedColumn<int> currentPass = GeneratedColumn<int>(
    'current_pass',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (current_pass > 0)',
  );
  static const VerificationMeta _remainingCountMeta = const VerificationMeta(
    'remainingCount',
  );
  late final GeneratedColumn<int> remainingCount = GeneratedColumn<int>(
    'remaining_count',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'CHECK (remaining_count >= 0)',
  );
  static const VerificationMeta _sourcePositionMsMeta = const VerificationMeta(
    'sourcePositionMs',
  );
  late final GeneratedColumn<int> sourcePositionMs = GeneratedColumn<int>(
    'source_position_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (source_position_ms >= 0)',
  );
  static const VerificationMeta _settingsSnapshotMeta = const VerificationMeta(
    'settingsSnapshot',
  );
  late final GeneratedColumn<String> settingsSnapshot = GeneratedColumn<String>(
    'settings_snapshot',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (json_valid(settings_snapshot))',
  );
  static const VerificationMeta _updatedUtcMsMeta = const VerificationMeta(
    'updatedUtcMs',
  );
  late final GeneratedColumn<int> updatedUtcMs = GeneratedColumn<int>(
    'updated_utc_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [
    sessionId,
    scope,
    assetId,
    passageId,
    currentPass,
    remainingCount,
    sourcePositionMs,
    settingsSnapshot,
    updatedUtcMs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'playback_checkpoints';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlaybackCheckpoint> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('scope')) {
      context.handle(
        _scopeMeta,
        scope.isAcceptableOrUnknown(data['scope']!, _scopeMeta),
      );
    } else if (isInserting) {
      context.missing(_scopeMeta);
    }
    if (data.containsKey('asset_id')) {
      context.handle(
        _assetIdMeta,
        assetId.isAcceptableOrUnknown(data['asset_id']!, _assetIdMeta),
      );
    } else if (isInserting) {
      context.missing(_assetIdMeta);
    }
    if (data.containsKey('passage_id')) {
      context.handle(
        _passageIdMeta,
        passageId.isAcceptableOrUnknown(data['passage_id']!, _passageIdMeta),
      );
    }
    if (data.containsKey('current_pass')) {
      context.handle(
        _currentPassMeta,
        currentPass.isAcceptableOrUnknown(
          data['current_pass']!,
          _currentPassMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_currentPassMeta);
    }
    if (data.containsKey('remaining_count')) {
      context.handle(
        _remainingCountMeta,
        remainingCount.isAcceptableOrUnknown(
          data['remaining_count']!,
          _remainingCountMeta,
        ),
      );
    }
    if (data.containsKey('source_position_ms')) {
      context.handle(
        _sourcePositionMsMeta,
        sourcePositionMs.isAcceptableOrUnknown(
          data['source_position_ms']!,
          _sourcePositionMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sourcePositionMsMeta);
    }
    if (data.containsKey('settings_snapshot')) {
      context.handle(
        _settingsSnapshotMeta,
        settingsSnapshot.isAcceptableOrUnknown(
          data['settings_snapshot']!,
          _settingsSnapshotMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_settingsSnapshotMeta);
    }
    if (data.containsKey('updated_utc_ms')) {
      context.handle(
        _updatedUtcMsMeta,
        updatedUtcMs.isAcceptableOrUnknown(
          data['updated_utc_ms']!,
          _updatedUtcMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_updatedUtcMsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {sessionId};
  @override
  PlaybackCheckpoint map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlaybackCheckpoint(
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      )!,
      scope: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scope'],
      )!,
      assetId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}asset_id'],
      )!,
      passageId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}passage_id'],
      ),
      currentPass: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}current_pass'],
      )!,
      remainingCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}remaining_count'],
      ),
      sourcePositionMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}source_position_ms'],
      )!,
      settingsSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}settings_snapshot'],
      )!,
      updatedUtcMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_utc_ms'],
      )!,
    );
  }

  @override
  PlaybackCheckpoints createAlias(String alias) {
    return PlaybackCheckpoints(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class PlaybackCheckpoint extends DataClass
    implements Insertable<PlaybackCheckpoint> {
  final String sessionId;
  final String scope;
  final String assetId;
  final String? passageId;
  final int currentPass;
  final int? remainingCount;
  final int sourcePositionMs;
  final String settingsSnapshot;
  final int updatedUtcMs;
  const PlaybackCheckpoint({
    required this.sessionId,
    required this.scope,
    required this.assetId,
    this.passageId,
    required this.currentPass,
    this.remainingCount,
    required this.sourcePositionMs,
    required this.settingsSnapshot,
    required this.updatedUtcMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['session_id'] = Variable<String>(sessionId);
    map['scope'] = Variable<String>(scope);
    map['asset_id'] = Variable<String>(assetId);
    if (!nullToAbsent || passageId != null) {
      map['passage_id'] = Variable<String>(passageId);
    }
    map['current_pass'] = Variable<int>(currentPass);
    if (!nullToAbsent || remainingCount != null) {
      map['remaining_count'] = Variable<int>(remainingCount);
    }
    map['source_position_ms'] = Variable<int>(sourcePositionMs);
    map['settings_snapshot'] = Variable<String>(settingsSnapshot);
    map['updated_utc_ms'] = Variable<int>(updatedUtcMs);
    return map;
  }

  PlaybackCheckpointsCompanion toCompanion(bool nullToAbsent) {
    return PlaybackCheckpointsCompanion(
      sessionId: Value(sessionId),
      scope: Value(scope),
      assetId: Value(assetId),
      passageId: passageId == null && nullToAbsent
          ? const Value.absent()
          : Value(passageId),
      currentPass: Value(currentPass),
      remainingCount: remainingCount == null && nullToAbsent
          ? const Value.absent()
          : Value(remainingCount),
      sourcePositionMs: Value(sourcePositionMs),
      settingsSnapshot: Value(settingsSnapshot),
      updatedUtcMs: Value(updatedUtcMs),
    );
  }

  factory PlaybackCheckpoint.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlaybackCheckpoint(
      sessionId: serializer.fromJson<String>(json['session_id']),
      scope: serializer.fromJson<String>(json['scope']),
      assetId: serializer.fromJson<String>(json['asset_id']),
      passageId: serializer.fromJson<String?>(json['passage_id']),
      currentPass: serializer.fromJson<int>(json['current_pass']),
      remainingCount: serializer.fromJson<int?>(json['remaining_count']),
      sourcePositionMs: serializer.fromJson<int>(json['source_position_ms']),
      settingsSnapshot: serializer.fromJson<String>(json['settings_snapshot']),
      updatedUtcMs: serializer.fromJson<int>(json['updated_utc_ms']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'session_id': serializer.toJson<String>(sessionId),
      'scope': serializer.toJson<String>(scope),
      'asset_id': serializer.toJson<String>(assetId),
      'passage_id': serializer.toJson<String?>(passageId),
      'current_pass': serializer.toJson<int>(currentPass),
      'remaining_count': serializer.toJson<int?>(remainingCount),
      'source_position_ms': serializer.toJson<int>(sourcePositionMs),
      'settings_snapshot': serializer.toJson<String>(settingsSnapshot),
      'updated_utc_ms': serializer.toJson<int>(updatedUtcMs),
    };
  }

  PlaybackCheckpoint copyWith({
    String? sessionId,
    String? scope,
    String? assetId,
    Value<String?> passageId = const Value.absent(),
    int? currentPass,
    Value<int?> remainingCount = const Value.absent(),
    int? sourcePositionMs,
    String? settingsSnapshot,
    int? updatedUtcMs,
  }) => PlaybackCheckpoint(
    sessionId: sessionId ?? this.sessionId,
    scope: scope ?? this.scope,
    assetId: assetId ?? this.assetId,
    passageId: passageId.present ? passageId.value : this.passageId,
    currentPass: currentPass ?? this.currentPass,
    remainingCount: remainingCount.present
        ? remainingCount.value
        : this.remainingCount,
    sourcePositionMs: sourcePositionMs ?? this.sourcePositionMs,
    settingsSnapshot: settingsSnapshot ?? this.settingsSnapshot,
    updatedUtcMs: updatedUtcMs ?? this.updatedUtcMs,
  );
  PlaybackCheckpoint copyWithCompanion(PlaybackCheckpointsCompanion data) {
    return PlaybackCheckpoint(
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      scope: data.scope.present ? data.scope.value : this.scope,
      assetId: data.assetId.present ? data.assetId.value : this.assetId,
      passageId: data.passageId.present ? data.passageId.value : this.passageId,
      currentPass: data.currentPass.present
          ? data.currentPass.value
          : this.currentPass,
      remainingCount: data.remainingCount.present
          ? data.remainingCount.value
          : this.remainingCount,
      sourcePositionMs: data.sourcePositionMs.present
          ? data.sourcePositionMs.value
          : this.sourcePositionMs,
      settingsSnapshot: data.settingsSnapshot.present
          ? data.settingsSnapshot.value
          : this.settingsSnapshot,
      updatedUtcMs: data.updatedUtcMs.present
          ? data.updatedUtcMs.value
          : this.updatedUtcMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlaybackCheckpoint(')
          ..write('sessionId: $sessionId, ')
          ..write('scope: $scope, ')
          ..write('assetId: $assetId, ')
          ..write('passageId: $passageId, ')
          ..write('currentPass: $currentPass, ')
          ..write('remainingCount: $remainingCount, ')
          ..write('sourcePositionMs: $sourcePositionMs, ')
          ..write('settingsSnapshot: $settingsSnapshot, ')
          ..write('updatedUtcMs: $updatedUtcMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    sessionId,
    scope,
    assetId,
    passageId,
    currentPass,
    remainingCount,
    sourcePositionMs,
    settingsSnapshot,
    updatedUtcMs,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlaybackCheckpoint &&
          other.sessionId == this.sessionId &&
          other.scope == this.scope &&
          other.assetId == this.assetId &&
          other.passageId == this.passageId &&
          other.currentPass == this.currentPass &&
          other.remainingCount == this.remainingCount &&
          other.sourcePositionMs == this.sourcePositionMs &&
          other.settingsSnapshot == this.settingsSnapshot &&
          other.updatedUtcMs == this.updatedUtcMs);
}

class PlaybackCheckpointsCompanion extends UpdateCompanion<PlaybackCheckpoint> {
  final Value<String> sessionId;
  final Value<String> scope;
  final Value<String> assetId;
  final Value<String?> passageId;
  final Value<int> currentPass;
  final Value<int?> remainingCount;
  final Value<int> sourcePositionMs;
  final Value<String> settingsSnapshot;
  final Value<int> updatedUtcMs;
  final Value<int> rowid;
  const PlaybackCheckpointsCompanion({
    this.sessionId = const Value.absent(),
    this.scope = const Value.absent(),
    this.assetId = const Value.absent(),
    this.passageId = const Value.absent(),
    this.currentPass = const Value.absent(),
    this.remainingCount = const Value.absent(),
    this.sourcePositionMs = const Value.absent(),
    this.settingsSnapshot = const Value.absent(),
    this.updatedUtcMs = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlaybackCheckpointsCompanion.insert({
    required String sessionId,
    required String scope,
    required String assetId,
    this.passageId = const Value.absent(),
    required int currentPass,
    this.remainingCount = const Value.absent(),
    required int sourcePositionMs,
    required String settingsSnapshot,
    required int updatedUtcMs,
    this.rowid = const Value.absent(),
  }) : sessionId = Value(sessionId),
       scope = Value(scope),
       assetId = Value(assetId),
       currentPass = Value(currentPass),
       sourcePositionMs = Value(sourcePositionMs),
       settingsSnapshot = Value(settingsSnapshot),
       updatedUtcMs = Value(updatedUtcMs);
  static Insertable<PlaybackCheckpoint> custom({
    Expression<String>? sessionId,
    Expression<String>? scope,
    Expression<String>? assetId,
    Expression<String>? passageId,
    Expression<int>? currentPass,
    Expression<int>? remainingCount,
    Expression<int>? sourcePositionMs,
    Expression<String>? settingsSnapshot,
    Expression<int>? updatedUtcMs,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (sessionId != null) 'session_id': sessionId,
      if (scope != null) 'scope': scope,
      if (assetId != null) 'asset_id': assetId,
      if (passageId != null) 'passage_id': passageId,
      if (currentPass != null) 'current_pass': currentPass,
      if (remainingCount != null) 'remaining_count': remainingCount,
      if (sourcePositionMs != null) 'source_position_ms': sourcePositionMs,
      if (settingsSnapshot != null) 'settings_snapshot': settingsSnapshot,
      if (updatedUtcMs != null) 'updated_utc_ms': updatedUtcMs,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlaybackCheckpointsCompanion copyWith({
    Value<String>? sessionId,
    Value<String>? scope,
    Value<String>? assetId,
    Value<String?>? passageId,
    Value<int>? currentPass,
    Value<int?>? remainingCount,
    Value<int>? sourcePositionMs,
    Value<String>? settingsSnapshot,
    Value<int>? updatedUtcMs,
    Value<int>? rowid,
  }) {
    return PlaybackCheckpointsCompanion(
      sessionId: sessionId ?? this.sessionId,
      scope: scope ?? this.scope,
      assetId: assetId ?? this.assetId,
      passageId: passageId ?? this.passageId,
      currentPass: currentPass ?? this.currentPass,
      remainingCount: remainingCount ?? this.remainingCount,
      sourcePositionMs: sourcePositionMs ?? this.sourcePositionMs,
      settingsSnapshot: settingsSnapshot ?? this.settingsSnapshot,
      updatedUtcMs: updatedUtcMs ?? this.updatedUtcMs,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (scope.present) {
      map['scope'] = Variable<String>(scope.value);
    }
    if (assetId.present) {
      map['asset_id'] = Variable<String>(assetId.value);
    }
    if (passageId.present) {
      map['passage_id'] = Variable<String>(passageId.value);
    }
    if (currentPass.present) {
      map['current_pass'] = Variable<int>(currentPass.value);
    }
    if (remainingCount.present) {
      map['remaining_count'] = Variable<int>(remainingCount.value);
    }
    if (sourcePositionMs.present) {
      map['source_position_ms'] = Variable<int>(sourcePositionMs.value);
    }
    if (settingsSnapshot.present) {
      map['settings_snapshot'] = Variable<String>(settingsSnapshot.value);
    }
    if (updatedUtcMs.present) {
      map['updated_utc_ms'] = Variable<int>(updatedUtcMs.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlaybackCheckpointsCompanion(')
          ..write('sessionId: $sessionId, ')
          ..write('scope: $scope, ')
          ..write('assetId: $assetId, ')
          ..write('passageId: $passageId, ')
          ..write('currentPass: $currentPass, ')
          ..write('remainingCount: $remainingCount, ')
          ..write('sourcePositionMs: $sourcePositionMs, ')
          ..write('settingsSnapshot: $settingsSnapshot, ')
          ..write('updatedUtcMs: $updatedUtcMs, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class ListeningSessions extends Table
    with TableInfo<ListeningSessions, ListeningSession> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  ListeningSessions(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _assetIdMeta = const VerificationMeta(
    'assetId',
  );
  late final GeneratedColumn<String> assetId = GeneratedColumn<String>(
    'asset_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES audio_assets(id)',
  );
  static const VerificationMeta _passageIdMeta = const VerificationMeta(
    'passageId',
  );
  late final GeneratedColumn<String> passageId = GeneratedColumn<String>(
    'passage_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'REFERENCES saved_passages(id)ON DELETE SET NULL',
  );
  static const VerificationMeta _startedUtcMsMeta = const VerificationMeta(
    'startedUtcMs',
  );
  late final GeneratedColumn<int> startedUtcMs = GeneratedColumn<int>(
    'started_utc_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _endedUtcMsMeta = const VerificationMeta(
    'endedUtcMs',
  );
  late final GeneratedColumn<int> endedUtcMs = GeneratedColumn<int>(
    'ended_utc_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'CHECK (ended_utc_ms >= started_utc_ms)',
  );
  static const VerificationMeta _playedWallMsMeta = const VerificationMeta(
    'playedWallMs',
  );
  late final GeneratedColumn<int> playedWallMs = GeneratedColumn<int>(
    'played_wall_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0 CHECK (played_wall_ms >= 0)',
    defaultValue: const CustomExpression('0'),
  );
  static const VerificationMeta _speedMeta = const VerificationMeta('speed');
  late final GeneratedColumn<double> speed = GeneratedColumn<double>(
    'speed',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (speed BETWEEN 0.5 AND 2.0)',
  );
  static const VerificationMeta _completionReasonMeta = const VerificationMeta(
    'completionReason',
  );
  late final GeneratedColumn<String> completionReason = GeneratedColumn<String>(
    'completion_reason',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    assetId,
    passageId,
    startedUtcMs,
    endedUtcMs,
    playedWallMs,
    speed,
    completionReason,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'listening_sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<ListeningSession> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('asset_id')) {
      context.handle(
        _assetIdMeta,
        assetId.isAcceptableOrUnknown(data['asset_id']!, _assetIdMeta),
      );
    } else if (isInserting) {
      context.missing(_assetIdMeta);
    }
    if (data.containsKey('passage_id')) {
      context.handle(
        _passageIdMeta,
        passageId.isAcceptableOrUnknown(data['passage_id']!, _passageIdMeta),
      );
    }
    if (data.containsKey('started_utc_ms')) {
      context.handle(
        _startedUtcMsMeta,
        startedUtcMs.isAcceptableOrUnknown(
          data['started_utc_ms']!,
          _startedUtcMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_startedUtcMsMeta);
    }
    if (data.containsKey('ended_utc_ms')) {
      context.handle(
        _endedUtcMsMeta,
        endedUtcMs.isAcceptableOrUnknown(
          data['ended_utc_ms']!,
          _endedUtcMsMeta,
        ),
      );
    }
    if (data.containsKey('played_wall_ms')) {
      context.handle(
        _playedWallMsMeta,
        playedWallMs.isAcceptableOrUnknown(
          data['played_wall_ms']!,
          _playedWallMsMeta,
        ),
      );
    }
    if (data.containsKey('speed')) {
      context.handle(
        _speedMeta,
        speed.isAcceptableOrUnknown(data['speed']!, _speedMeta),
      );
    } else if (isInserting) {
      context.missing(_speedMeta);
    }
    if (data.containsKey('completion_reason')) {
      context.handle(
        _completionReasonMeta,
        completionReason.isAcceptableOrUnknown(
          data['completion_reason']!,
          _completionReasonMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ListeningSession map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ListeningSession(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      assetId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}asset_id'],
      )!,
      passageId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}passage_id'],
      ),
      startedUtcMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}started_utc_ms'],
      )!,
      endedUtcMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ended_utc_ms'],
      ),
      playedWallMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}played_wall_ms'],
      )!,
      speed: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}speed'],
      )!,
      completionReason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}completion_reason'],
      ),
    );
  }

  @override
  ListeningSessions createAlias(String alias) {
    return ListeningSessions(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class ListeningSession extends DataClass
    implements Insertable<ListeningSession> {
  final String id;
  final String assetId;
  final String? passageId;
  final int startedUtcMs;
  final int? endedUtcMs;
  final int playedWallMs;
  final double speed;
  final String? completionReason;
  const ListeningSession({
    required this.id,
    required this.assetId,
    this.passageId,
    required this.startedUtcMs,
    this.endedUtcMs,
    required this.playedWallMs,
    required this.speed,
    this.completionReason,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['asset_id'] = Variable<String>(assetId);
    if (!nullToAbsent || passageId != null) {
      map['passage_id'] = Variable<String>(passageId);
    }
    map['started_utc_ms'] = Variable<int>(startedUtcMs);
    if (!nullToAbsent || endedUtcMs != null) {
      map['ended_utc_ms'] = Variable<int>(endedUtcMs);
    }
    map['played_wall_ms'] = Variable<int>(playedWallMs);
    map['speed'] = Variable<double>(speed);
    if (!nullToAbsent || completionReason != null) {
      map['completion_reason'] = Variable<String>(completionReason);
    }
    return map;
  }

  ListeningSessionsCompanion toCompanion(bool nullToAbsent) {
    return ListeningSessionsCompanion(
      id: Value(id),
      assetId: Value(assetId),
      passageId: passageId == null && nullToAbsent
          ? const Value.absent()
          : Value(passageId),
      startedUtcMs: Value(startedUtcMs),
      endedUtcMs: endedUtcMs == null && nullToAbsent
          ? const Value.absent()
          : Value(endedUtcMs),
      playedWallMs: Value(playedWallMs),
      speed: Value(speed),
      completionReason: completionReason == null && nullToAbsent
          ? const Value.absent()
          : Value(completionReason),
    );
  }

  factory ListeningSession.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ListeningSession(
      id: serializer.fromJson<String>(json['id']),
      assetId: serializer.fromJson<String>(json['asset_id']),
      passageId: serializer.fromJson<String?>(json['passage_id']),
      startedUtcMs: serializer.fromJson<int>(json['started_utc_ms']),
      endedUtcMs: serializer.fromJson<int?>(json['ended_utc_ms']),
      playedWallMs: serializer.fromJson<int>(json['played_wall_ms']),
      speed: serializer.fromJson<double>(json['speed']),
      completionReason: serializer.fromJson<String?>(json['completion_reason']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'asset_id': serializer.toJson<String>(assetId),
      'passage_id': serializer.toJson<String?>(passageId),
      'started_utc_ms': serializer.toJson<int>(startedUtcMs),
      'ended_utc_ms': serializer.toJson<int?>(endedUtcMs),
      'played_wall_ms': serializer.toJson<int>(playedWallMs),
      'speed': serializer.toJson<double>(speed),
      'completion_reason': serializer.toJson<String?>(completionReason),
    };
  }

  ListeningSession copyWith({
    String? id,
    String? assetId,
    Value<String?> passageId = const Value.absent(),
    int? startedUtcMs,
    Value<int?> endedUtcMs = const Value.absent(),
    int? playedWallMs,
    double? speed,
    Value<String?> completionReason = const Value.absent(),
  }) => ListeningSession(
    id: id ?? this.id,
    assetId: assetId ?? this.assetId,
    passageId: passageId.present ? passageId.value : this.passageId,
    startedUtcMs: startedUtcMs ?? this.startedUtcMs,
    endedUtcMs: endedUtcMs.present ? endedUtcMs.value : this.endedUtcMs,
    playedWallMs: playedWallMs ?? this.playedWallMs,
    speed: speed ?? this.speed,
    completionReason: completionReason.present
        ? completionReason.value
        : this.completionReason,
  );
  ListeningSession copyWithCompanion(ListeningSessionsCompanion data) {
    return ListeningSession(
      id: data.id.present ? data.id.value : this.id,
      assetId: data.assetId.present ? data.assetId.value : this.assetId,
      passageId: data.passageId.present ? data.passageId.value : this.passageId,
      startedUtcMs: data.startedUtcMs.present
          ? data.startedUtcMs.value
          : this.startedUtcMs,
      endedUtcMs: data.endedUtcMs.present
          ? data.endedUtcMs.value
          : this.endedUtcMs,
      playedWallMs: data.playedWallMs.present
          ? data.playedWallMs.value
          : this.playedWallMs,
      speed: data.speed.present ? data.speed.value : this.speed,
      completionReason: data.completionReason.present
          ? data.completionReason.value
          : this.completionReason,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ListeningSession(')
          ..write('id: $id, ')
          ..write('assetId: $assetId, ')
          ..write('passageId: $passageId, ')
          ..write('startedUtcMs: $startedUtcMs, ')
          ..write('endedUtcMs: $endedUtcMs, ')
          ..write('playedWallMs: $playedWallMs, ')
          ..write('speed: $speed, ')
          ..write('completionReason: $completionReason')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    assetId,
    passageId,
    startedUtcMs,
    endedUtcMs,
    playedWallMs,
    speed,
    completionReason,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ListeningSession &&
          other.id == this.id &&
          other.assetId == this.assetId &&
          other.passageId == this.passageId &&
          other.startedUtcMs == this.startedUtcMs &&
          other.endedUtcMs == this.endedUtcMs &&
          other.playedWallMs == this.playedWallMs &&
          other.speed == this.speed &&
          other.completionReason == this.completionReason);
}

class ListeningSessionsCompanion extends UpdateCompanion<ListeningSession> {
  final Value<String> id;
  final Value<String> assetId;
  final Value<String?> passageId;
  final Value<int> startedUtcMs;
  final Value<int?> endedUtcMs;
  final Value<int> playedWallMs;
  final Value<double> speed;
  final Value<String?> completionReason;
  final Value<int> rowid;
  const ListeningSessionsCompanion({
    this.id = const Value.absent(),
    this.assetId = const Value.absent(),
    this.passageId = const Value.absent(),
    this.startedUtcMs = const Value.absent(),
    this.endedUtcMs = const Value.absent(),
    this.playedWallMs = const Value.absent(),
    this.speed = const Value.absent(),
    this.completionReason = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ListeningSessionsCompanion.insert({
    required String id,
    required String assetId,
    this.passageId = const Value.absent(),
    required int startedUtcMs,
    this.endedUtcMs = const Value.absent(),
    this.playedWallMs = const Value.absent(),
    required double speed,
    this.completionReason = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       assetId = Value(assetId),
       startedUtcMs = Value(startedUtcMs),
       speed = Value(speed);
  static Insertable<ListeningSession> custom({
    Expression<String>? id,
    Expression<String>? assetId,
    Expression<String>? passageId,
    Expression<int>? startedUtcMs,
    Expression<int>? endedUtcMs,
    Expression<int>? playedWallMs,
    Expression<double>? speed,
    Expression<String>? completionReason,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (assetId != null) 'asset_id': assetId,
      if (passageId != null) 'passage_id': passageId,
      if (startedUtcMs != null) 'started_utc_ms': startedUtcMs,
      if (endedUtcMs != null) 'ended_utc_ms': endedUtcMs,
      if (playedWallMs != null) 'played_wall_ms': playedWallMs,
      if (speed != null) 'speed': speed,
      if (completionReason != null) 'completion_reason': completionReason,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ListeningSessionsCompanion copyWith({
    Value<String>? id,
    Value<String>? assetId,
    Value<String?>? passageId,
    Value<int>? startedUtcMs,
    Value<int?>? endedUtcMs,
    Value<int>? playedWallMs,
    Value<double>? speed,
    Value<String?>? completionReason,
    Value<int>? rowid,
  }) {
    return ListeningSessionsCompanion(
      id: id ?? this.id,
      assetId: assetId ?? this.assetId,
      passageId: passageId ?? this.passageId,
      startedUtcMs: startedUtcMs ?? this.startedUtcMs,
      endedUtcMs: endedUtcMs ?? this.endedUtcMs,
      playedWallMs: playedWallMs ?? this.playedWallMs,
      speed: speed ?? this.speed,
      completionReason: completionReason ?? this.completionReason,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (assetId.present) {
      map['asset_id'] = Variable<String>(assetId.value);
    }
    if (passageId.present) {
      map['passage_id'] = Variable<String>(passageId.value);
    }
    if (startedUtcMs.present) {
      map['started_utc_ms'] = Variable<int>(startedUtcMs.value);
    }
    if (endedUtcMs.present) {
      map['ended_utc_ms'] = Variable<int>(endedUtcMs.value);
    }
    if (playedWallMs.present) {
      map['played_wall_ms'] = Variable<int>(playedWallMs.value);
    }
    if (speed.present) {
      map['speed'] = Variable<double>(speed.value);
    }
    if (completionReason.present) {
      map['completion_reason'] = Variable<String>(completionReason.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ListeningSessionsCompanion(')
          ..write('id: $id, ')
          ..write('assetId: $assetId, ')
          ..write('passageId: $passageId, ')
          ..write('startedUtcMs: $startedUtcMs, ')
          ..write('endedUtcMs: $endedUtcMs, ')
          ..write('playedWallMs: $playedWallMs, ')
          ..write('speed: $speed, ')
          ..write('completionReason: $completionReason, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class DailyActivity extends Table
    with TableInfo<DailyActivity, DailyActivityData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  DailyActivity(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _localDateMeta = const VerificationMeta(
    'localDate',
  );
  late final GeneratedColumn<String> localDate = GeneratedColumn<String>(
    'local_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY CHECK (length(local_date) = 10)',
  );
  static const VerificationMeta _timezonePolicyMeta = const VerificationMeta(
    'timezonePolicy',
  );
  late final GeneratedColumn<String> timezonePolicy = GeneratedColumn<String>(
    'timezone_policy',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _playedWallMsMeta = const VerificationMeta(
    'playedWallMs',
  );
  late final GeneratedColumn<int> playedWallMs = GeneratedColumn<int>(
    'played_wall_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0 CHECK (played_wall_ms >= 0)',
    defaultValue: const CustomExpression('0'),
  );
  static const VerificationMeta _goalMsMeta = const VerificationMeta('goalMs');
  late final GeneratedColumn<int> goalMs = GeneratedColumn<int>(
    'goal_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (goal_ms >= 0)',
  );
  static const VerificationMeta _qualifiedMeta = const VerificationMeta(
    'qualified',
  );
  late final GeneratedColumn<int> qualified = GeneratedColumn<int>(
    'qualified',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (qualified IN (0, 1))',
  );
  @override
  List<GeneratedColumn> get $columns => [
    localDate,
    timezonePolicy,
    playedWallMs,
    goalMs,
    qualified,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'daily_activity';
  @override
  VerificationContext validateIntegrity(
    Insertable<DailyActivityData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('local_date')) {
      context.handle(
        _localDateMeta,
        localDate.isAcceptableOrUnknown(data['local_date']!, _localDateMeta),
      );
    } else if (isInserting) {
      context.missing(_localDateMeta);
    }
    if (data.containsKey('timezone_policy')) {
      context.handle(
        _timezonePolicyMeta,
        timezonePolicy.isAcceptableOrUnknown(
          data['timezone_policy']!,
          _timezonePolicyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_timezonePolicyMeta);
    }
    if (data.containsKey('played_wall_ms')) {
      context.handle(
        _playedWallMsMeta,
        playedWallMs.isAcceptableOrUnknown(
          data['played_wall_ms']!,
          _playedWallMsMeta,
        ),
      );
    }
    if (data.containsKey('goal_ms')) {
      context.handle(
        _goalMsMeta,
        goalMs.isAcceptableOrUnknown(data['goal_ms']!, _goalMsMeta),
      );
    } else if (isInserting) {
      context.missing(_goalMsMeta);
    }
    if (data.containsKey('qualified')) {
      context.handle(
        _qualifiedMeta,
        qualified.isAcceptableOrUnknown(data['qualified']!, _qualifiedMeta),
      );
    } else if (isInserting) {
      context.missing(_qualifiedMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {localDate};
  @override
  DailyActivityData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DailyActivityData(
      localDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_date'],
      )!,
      timezonePolicy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}timezone_policy'],
      )!,
      playedWallMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}played_wall_ms'],
      )!,
      goalMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}goal_ms'],
      )!,
      qualified: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}qualified'],
      )!,
    );
  }

  @override
  DailyActivity createAlias(String alias) {
    return DailyActivity(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class DailyActivityData extends DataClass
    implements Insertable<DailyActivityData> {
  final String localDate;
  final String timezonePolicy;
  final int playedWallMs;
  final int goalMs;
  final int qualified;
  const DailyActivityData({
    required this.localDate,
    required this.timezonePolicy,
    required this.playedWallMs,
    required this.goalMs,
    required this.qualified,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['local_date'] = Variable<String>(localDate);
    map['timezone_policy'] = Variable<String>(timezonePolicy);
    map['played_wall_ms'] = Variable<int>(playedWallMs);
    map['goal_ms'] = Variable<int>(goalMs);
    map['qualified'] = Variable<int>(qualified);
    return map;
  }

  DailyActivityCompanion toCompanion(bool nullToAbsent) {
    return DailyActivityCompanion(
      localDate: Value(localDate),
      timezonePolicy: Value(timezonePolicy),
      playedWallMs: Value(playedWallMs),
      goalMs: Value(goalMs),
      qualified: Value(qualified),
    );
  }

  factory DailyActivityData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DailyActivityData(
      localDate: serializer.fromJson<String>(json['local_date']),
      timezonePolicy: serializer.fromJson<String>(json['timezone_policy']),
      playedWallMs: serializer.fromJson<int>(json['played_wall_ms']),
      goalMs: serializer.fromJson<int>(json['goal_ms']),
      qualified: serializer.fromJson<int>(json['qualified']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'local_date': serializer.toJson<String>(localDate),
      'timezone_policy': serializer.toJson<String>(timezonePolicy),
      'played_wall_ms': serializer.toJson<int>(playedWallMs),
      'goal_ms': serializer.toJson<int>(goalMs),
      'qualified': serializer.toJson<int>(qualified),
    };
  }

  DailyActivityData copyWith({
    String? localDate,
    String? timezonePolicy,
    int? playedWallMs,
    int? goalMs,
    int? qualified,
  }) => DailyActivityData(
    localDate: localDate ?? this.localDate,
    timezonePolicy: timezonePolicy ?? this.timezonePolicy,
    playedWallMs: playedWallMs ?? this.playedWallMs,
    goalMs: goalMs ?? this.goalMs,
    qualified: qualified ?? this.qualified,
  );
  DailyActivityData copyWithCompanion(DailyActivityCompanion data) {
    return DailyActivityData(
      localDate: data.localDate.present ? data.localDate.value : this.localDate,
      timezonePolicy: data.timezonePolicy.present
          ? data.timezonePolicy.value
          : this.timezonePolicy,
      playedWallMs: data.playedWallMs.present
          ? data.playedWallMs.value
          : this.playedWallMs,
      goalMs: data.goalMs.present ? data.goalMs.value : this.goalMs,
      qualified: data.qualified.present ? data.qualified.value : this.qualified,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DailyActivityData(')
          ..write('localDate: $localDate, ')
          ..write('timezonePolicy: $timezonePolicy, ')
          ..write('playedWallMs: $playedWallMs, ')
          ..write('goalMs: $goalMs, ')
          ..write('qualified: $qualified')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(localDate, timezonePolicy, playedWallMs, goalMs, qualified);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DailyActivityData &&
          other.localDate == this.localDate &&
          other.timezonePolicy == this.timezonePolicy &&
          other.playedWallMs == this.playedWallMs &&
          other.goalMs == this.goalMs &&
          other.qualified == this.qualified);
}

class DailyActivityCompanion extends UpdateCompanion<DailyActivityData> {
  final Value<String> localDate;
  final Value<String> timezonePolicy;
  final Value<int> playedWallMs;
  final Value<int> goalMs;
  final Value<int> qualified;
  final Value<int> rowid;
  const DailyActivityCompanion({
    this.localDate = const Value.absent(),
    this.timezonePolicy = const Value.absent(),
    this.playedWallMs = const Value.absent(),
    this.goalMs = const Value.absent(),
    this.qualified = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DailyActivityCompanion.insert({
    required String localDate,
    required String timezonePolicy,
    this.playedWallMs = const Value.absent(),
    required int goalMs,
    required int qualified,
    this.rowid = const Value.absent(),
  }) : localDate = Value(localDate),
       timezonePolicy = Value(timezonePolicy),
       goalMs = Value(goalMs),
       qualified = Value(qualified);
  static Insertable<DailyActivityData> custom({
    Expression<String>? localDate,
    Expression<String>? timezonePolicy,
    Expression<int>? playedWallMs,
    Expression<int>? goalMs,
    Expression<int>? qualified,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (localDate != null) 'local_date': localDate,
      if (timezonePolicy != null) 'timezone_policy': timezonePolicy,
      if (playedWallMs != null) 'played_wall_ms': playedWallMs,
      if (goalMs != null) 'goal_ms': goalMs,
      if (qualified != null) 'qualified': qualified,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DailyActivityCompanion copyWith({
    Value<String>? localDate,
    Value<String>? timezonePolicy,
    Value<int>? playedWallMs,
    Value<int>? goalMs,
    Value<int>? qualified,
    Value<int>? rowid,
  }) {
    return DailyActivityCompanion(
      localDate: localDate ?? this.localDate,
      timezonePolicy: timezonePolicy ?? this.timezonePolicy,
      playedWallMs: playedWallMs ?? this.playedWallMs,
      goalMs: goalMs ?? this.goalMs,
      qualified: qualified ?? this.qualified,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (localDate.present) {
      map['local_date'] = Variable<String>(localDate.value);
    }
    if (timezonePolicy.present) {
      map['timezone_policy'] = Variable<String>(timezonePolicy.value);
    }
    if (playedWallMs.present) {
      map['played_wall_ms'] = Variable<int>(playedWallMs.value);
    }
    if (goalMs.present) {
      map['goal_ms'] = Variable<int>(goalMs.value);
    }
    if (qualified.present) {
      map['qualified'] = Variable<int>(qualified.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DailyActivityCompanion(')
          ..write('localDate: $localDate, ')
          ..write('timezonePolicy: $timezonePolicy, ')
          ..write('playedWallMs: $playedWallMs, ')
          ..write('goalMs: $goalMs, ')
          ..write('qualified: $qualified, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class ActivityEvents extends Table
    with TableInfo<ActivityEvents, ActivityEvent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  ActivityEvents(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES listening_sessions(id)',
  );
  static const VerificationMeta _localDateMeta = const VerificationMeta(
    'localDate',
  );
  late final GeneratedColumn<String> localDate = GeneratedColumn<String>(
    'local_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES daily_activity(local_date)',
  );
  static const VerificationMeta _playedWallMsMeta = const VerificationMeta(
    'playedWallMs',
  );
  late final GeneratedColumn<int> playedWallMs = GeneratedColumn<int>(
    'played_wall_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (played_wall_ms > 0)',
  );
  static const VerificationMeta _utcMsMeta = const VerificationMeta('utcMs');
  late final GeneratedColumn<int> utcMs = GeneratedColumn<int>(
    'utc_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sessionId,
    localDate,
    playedWallMs,
    utcMs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'activity_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<ActivityEvent> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('local_date')) {
      context.handle(
        _localDateMeta,
        localDate.isAcceptableOrUnknown(data['local_date']!, _localDateMeta),
      );
    } else if (isInserting) {
      context.missing(_localDateMeta);
    }
    if (data.containsKey('played_wall_ms')) {
      context.handle(
        _playedWallMsMeta,
        playedWallMs.isAcceptableOrUnknown(
          data['played_wall_ms']!,
          _playedWallMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_playedWallMsMeta);
    }
    if (data.containsKey('utc_ms')) {
      context.handle(
        _utcMsMeta,
        utcMs.isAcceptableOrUnknown(data['utc_ms']!, _utcMsMeta),
      );
    } else if (isInserting) {
      context.missing(_utcMsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ActivityEvent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ActivityEvent(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      )!,
      localDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_date'],
      )!,
      playedWallMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}played_wall_ms'],
      )!,
      utcMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}utc_ms'],
      )!,
    );
  }

  @override
  ActivityEvents createAlias(String alias) {
    return ActivityEvents(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class ActivityEvent extends DataClass implements Insertable<ActivityEvent> {
  final String id;
  final String sessionId;
  final String localDate;
  final int playedWallMs;
  final int utcMs;
  const ActivityEvent({
    required this.id,
    required this.sessionId,
    required this.localDate,
    required this.playedWallMs,
    required this.utcMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['session_id'] = Variable<String>(sessionId);
    map['local_date'] = Variable<String>(localDate);
    map['played_wall_ms'] = Variable<int>(playedWallMs);
    map['utc_ms'] = Variable<int>(utcMs);
    return map;
  }

  ActivityEventsCompanion toCompanion(bool nullToAbsent) {
    return ActivityEventsCompanion(
      id: Value(id),
      sessionId: Value(sessionId),
      localDate: Value(localDate),
      playedWallMs: Value(playedWallMs),
      utcMs: Value(utcMs),
    );
  }

  factory ActivityEvent.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ActivityEvent(
      id: serializer.fromJson<String>(json['id']),
      sessionId: serializer.fromJson<String>(json['session_id']),
      localDate: serializer.fromJson<String>(json['local_date']),
      playedWallMs: serializer.fromJson<int>(json['played_wall_ms']),
      utcMs: serializer.fromJson<int>(json['utc_ms']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'session_id': serializer.toJson<String>(sessionId),
      'local_date': serializer.toJson<String>(localDate),
      'played_wall_ms': serializer.toJson<int>(playedWallMs),
      'utc_ms': serializer.toJson<int>(utcMs),
    };
  }

  ActivityEvent copyWith({
    String? id,
    String? sessionId,
    String? localDate,
    int? playedWallMs,
    int? utcMs,
  }) => ActivityEvent(
    id: id ?? this.id,
    sessionId: sessionId ?? this.sessionId,
    localDate: localDate ?? this.localDate,
    playedWallMs: playedWallMs ?? this.playedWallMs,
    utcMs: utcMs ?? this.utcMs,
  );
  ActivityEvent copyWithCompanion(ActivityEventsCompanion data) {
    return ActivityEvent(
      id: data.id.present ? data.id.value : this.id,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      localDate: data.localDate.present ? data.localDate.value : this.localDate,
      playedWallMs: data.playedWallMs.present
          ? data.playedWallMs.value
          : this.playedWallMs,
      utcMs: data.utcMs.present ? data.utcMs.value : this.utcMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ActivityEvent(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('localDate: $localDate, ')
          ..write('playedWallMs: $playedWallMs, ')
          ..write('utcMs: $utcMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, sessionId, localDate, playedWallMs, utcMs);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ActivityEvent &&
          other.id == this.id &&
          other.sessionId == this.sessionId &&
          other.localDate == this.localDate &&
          other.playedWallMs == this.playedWallMs &&
          other.utcMs == this.utcMs);
}

class ActivityEventsCompanion extends UpdateCompanion<ActivityEvent> {
  final Value<String> id;
  final Value<String> sessionId;
  final Value<String> localDate;
  final Value<int> playedWallMs;
  final Value<int> utcMs;
  final Value<int> rowid;
  const ActivityEventsCompanion({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.localDate = const Value.absent(),
    this.playedWallMs = const Value.absent(),
    this.utcMs = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ActivityEventsCompanion.insert({
    required String id,
    required String sessionId,
    required String localDate,
    required int playedWallMs,
    required int utcMs,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       sessionId = Value(sessionId),
       localDate = Value(localDate),
       playedWallMs = Value(playedWallMs),
       utcMs = Value(utcMs);
  static Insertable<ActivityEvent> custom({
    Expression<String>? id,
    Expression<String>? sessionId,
    Expression<String>? localDate,
    Expression<int>? playedWallMs,
    Expression<int>? utcMs,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionId != null) 'session_id': sessionId,
      if (localDate != null) 'local_date': localDate,
      if (playedWallMs != null) 'played_wall_ms': playedWallMs,
      if (utcMs != null) 'utc_ms': utcMs,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ActivityEventsCompanion copyWith({
    Value<String>? id,
    Value<String>? sessionId,
    Value<String>? localDate,
    Value<int>? playedWallMs,
    Value<int>? utcMs,
    Value<int>? rowid,
  }) {
    return ActivityEventsCompanion(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      localDate: localDate ?? this.localDate,
      playedWallMs: playedWallMs ?? this.playedWallMs,
      utcMs: utcMs ?? this.utcMs,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (localDate.present) {
      map['local_date'] = Variable<String>(localDate.value);
    }
    if (playedWallMs.present) {
      map['played_wall_ms'] = Variable<int>(playedWallMs.value);
    }
    if (utcMs.present) {
      map['utc_ms'] = Variable<int>(utcMs.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ActivityEventsCompanion(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('localDate: $localDate, ')
          ..write('playedWallMs: $playedWallMs, ')
          ..write('utcMs: $utcMs, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final Reciters reciters = Reciters(this);
  late final AppSettings appSettings = AppSettings(this);
  late final Surahs surahs = Surahs(this);
  late final RecordingEditions recordingEditions = RecordingEditions(this);
  late final AudioAssets audioAssets = AudioAssets(this);
  late final SavedPassages savedPassages = SavedPassages(this);
  late final Trigger passageInsertBounds = Trigger(
    'CREATE TRIGGER passage_insert_bounds BEFORE INSERT ON saved_passages BEGIN SELECT RAISE (ABORT, \'Passage requires verified duration and valid bounds\') WHERE NOT EXISTS (SELECT 1 FROM audio_assets WHERE id = NEW.asset_id AND duration_ms IS NOT NULL AND NEW.end_ms <= duration_ms);END',
    'passage_insert_bounds',
  );
  late final Trigger passageUpdateBounds = Trigger(
    'CREATE TRIGGER passage_update_bounds BEFORE UPDATE ON saved_passages BEGIN SELECT RAISE (ABORT, \'Passage requires verified duration and valid bounds\') WHERE NOT EXISTS (SELECT 1 FROM audio_assets WHERE id = NEW.asset_id AND duration_ms IS NOT NULL AND NEW.end_ms <= duration_ms);END',
    'passage_update_bounds',
  );
  late final Trigger assetIdentityImmutable = Trigger(
    'CREATE TRIGGER asset_identity_immutable BEFORE UPDATE ON audio_assets BEGIN SELECT RAISE (ABORT, \'Recording bytes and identity are immutable\') WHERE OLD.id <> NEW.id OR OLD.edition_id <> NEW.edition_id OR OLD.surah_number <> NEW.surah_number OR OLD.version <> NEW.version OR(OLD.sha256 IS NOT NULL AND(NEW.sha256 IS NOT OLD.sha256 OR NEW.byte_size IS NOT OLD.byte_size OR NEW.duration_ms IS NOT OLD.duration_ms OR NEW.url IS NOT OLD.url));END',
    'asset_identity_immutable',
  );
  late final Favorites favorites = Favorites(this);
  late final Trigger favoriteInsertTarget = Trigger(
    'CREATE TRIGGER favorite_insert_target BEFORE INSERT ON favorites BEGIN SELECT RAISE (ABORT, \'Unknown favorite target\') WHERE(NEW.type = \'surah\' AND NOT EXISTS (SELECT 1 FROM surahs WHERE CAST(number AS TEXT) = NEW.target_id))OR(NEW.type = \'passage\' AND NOT EXISTS (SELECT 1 FROM saved_passages WHERE id = NEW.target_id));END',
    'favorite_insert_target',
  );
  late final Trigger favoriteUpdateTarget = Trigger(
    'CREATE TRIGGER favorite_update_target BEFORE UPDATE ON favorites BEGIN SELECT RAISE (ABORT, \'Favorite target is immutable\') WHERE NEW.type <> OLD.type OR NEW.target_id <> OLD.target_id;END',
    'favorite_update_target',
  );
  late final Trigger passageDeleteFavorite = Trigger(
    'CREATE TRIGGER passage_delete_favorite AFTER DELETE ON saved_passages BEGIN DELETE FROM favorites WHERE type = \'passage\' AND target_id = OLD.id;END',
    'passage_delete_favorite',
  );
  late final Trigger surahDeleteFavorite = Trigger(
    'CREATE TRIGGER surah_delete_favorite AFTER DELETE ON surahs BEGIN DELETE FROM favorites WHERE type = \'surah\' AND target_id = CAST(OLD.number AS TEXT);END',
    'surah_delete_favorite',
  );
  late final Downloads downloads = Downloads(this);
  late final Trigger downloadInsertVerified = Trigger(
    'CREATE TRIGGER download_insert_verified BEFORE INSERT ON downloads BEGIN SELECT RAISE (ABORT, \'Download integrity mismatch\') WHERE NEW.state = \'verified\' AND NOT EXISTS (SELECT 1 FROM audio_assets WHERE id = NEW.asset_id AND byte_size = NEW.received_bytes AND sha256 = NEW.verified_sha256);END',
    'download_insert_verified',
  );
  late final Trigger downloadUpdateVerified = Trigger(
    'CREATE TRIGGER download_update_verified BEFORE UPDATE ON downloads BEGIN SELECT RAISE (ABORT, \'Download integrity mismatch\') WHERE NEW.state = \'verified\' AND NOT EXISTS (SELECT 1 FROM audio_assets WHERE id = NEW.asset_id AND byte_size = NEW.received_bytes AND sha256 = NEW.verified_sha256);END',
    'download_update_verified',
  );
  late final PlaybackCheckpoints playbackCheckpoints = PlaybackCheckpoints(
    this,
  );
  late final Trigger checkpointInsertBounds = Trigger(
    'CREATE TRIGGER checkpoint_insert_bounds BEFORE INSERT ON playback_checkpoints BEGIN SELECT RAISE (ABORT, \'Invalid checkpoint asset/position\') WHERE NOT EXISTS (SELECT 1 FROM audio_assets WHERE id = NEW.asset_id AND duration_ms IS NOT NULL AND NEW.source_position_ms <= duration_ms);SELECT RAISE (ABORT, \'Checkpoint passage asset mismatch\') WHERE NEW.passage_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM saved_passages WHERE id = NEW.passage_id AND asset_id = NEW.asset_id);END',
    'checkpoint_insert_bounds',
  );
  late final Trigger checkpointUpdateBounds = Trigger(
    'CREATE TRIGGER checkpoint_update_bounds BEFORE UPDATE ON playback_checkpoints BEGIN SELECT RAISE (ABORT, \'Invalid checkpoint asset/position\') WHERE NOT EXISTS (SELECT 1 FROM audio_assets WHERE id = NEW.asset_id AND duration_ms IS NOT NULL AND NEW.source_position_ms <= duration_ms);SELECT RAISE (ABORT, \'Checkpoint passage asset mismatch\') WHERE NEW.passage_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM saved_passages WHERE id = NEW.passage_id AND asset_id = NEW.asset_id);END',
    'checkpoint_update_bounds',
  );
  late final ListeningSessions listeningSessions = ListeningSessions(this);
  late final DailyActivity dailyActivity = DailyActivity(this);
  late final ActivityEvents activityEvents = ActivityEvents(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    reciters,
    appSettings,
    surahs,
    recordingEditions,
    audioAssets,
    savedPassages,
    passageInsertBounds,
    passageUpdateBounds,
    assetIdentityImmutable,
    favorites,
    favoriteInsertTarget,
    favoriteUpdateTarget,
    passageDeleteFavorite,
    surahDeleteFavorite,
    downloads,
    downloadInsertVerified,
    downloadUpdateVerified,
    playbackCheckpoints,
    checkpointInsertBounds,
    checkpointUpdateBounds,
    listeningSessions,
    dailyActivity,
    activityEvents,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'saved_passages',
        limitUpdateKind: UpdateKind.insert,
      ),
      result: [],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'saved_passages',
        limitUpdateKind: UpdateKind.update,
      ),
      result: [],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'audio_assets',
        limitUpdateKind: UpdateKind.update,
      ),
      result: [],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'favorites',
        limitUpdateKind: UpdateKind.insert,
      ),
      result: [],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'favorites',
        limitUpdateKind: UpdateKind.update,
      ),
      result: [],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'saved_passages',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('favorites', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'surahs',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('favorites', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'downloads',
        limitUpdateKind: UpdateKind.insert,
      ),
      result: [],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'downloads',
        limitUpdateKind: UpdateKind.update,
      ),
      result: [],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'saved_passages',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('playback_checkpoints', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'playback_checkpoints',
        limitUpdateKind: UpdateKind.insert,
      ),
      result: [],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'playback_checkpoints',
        limitUpdateKind: UpdateKind.update,
      ),
      result: [],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'saved_passages',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('listening_sessions', kind: UpdateKind.update)],
    ),
  ]);
}

typedef $RecitersCreateCompanionBuilder = RecitersCompanion Function({
  required String id,
  required String displayName,
  Value<String?> arabicName,
  required String attribution,
  required String sourceInfo,
  Value<int> rowid,
});
typedef $RecitersUpdateCompanionBuilder = RecitersCompanion Function({
  Value<String> id,
  Value<String> displayName,
  Value<String?> arabicName,
  Value<String> attribution,
  Value<String> sourceInfo,
  Value<int> rowid,
});

final class $RecitersReferences
    extends BaseReferences<_$AppDatabase, Reciters, Reciter> {
  $RecitersReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<AppSettings, List<AppSetting>>
  _appSettingsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.appSettings,
    aliasName: 'reciters__id__app_settings__default_reciter_id',
  );

  $AppSettingsProcessedTableManager get appSettingsRefs {
    final manager = $AppSettingsTableManager($_db, $_db.appSettings).filter(
      (f) => f.defaultReciterId.id.sqlEquals($_itemColumn<String>('id')!),
    );

    final cache = $_typedResult.readTableOrNull(_appSettingsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<RecordingEditions, List<RecordingEdition>>
  _recordingEditionsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.recordingEditions,
        aliasName: 'reciters__id__recording_editions__reciter_id',
      );

  $RecordingEditionsProcessedTableManager get recordingEditionsRefs {
    final manager = $RecordingEditionsTableManager(
      $_db,
      $_db.recordingEditions,
    ).filter((f) => f.reciterId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _recordingEditionsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $RecitersFilterComposer extends Composer<_$AppDatabase, Reciters> {
  $RecitersFilterComposer({
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

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get arabicName => $composableBuilder(
    column: $table.arabicName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get attribution => $composableBuilder(
    column: $table.attribution,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceInfo => $composableBuilder(
    column: $table.sourceInfo,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> appSettingsRefs(
    Expression<bool> Function($AppSettingsFilterComposer f) f,
  ) {
    final $AppSettingsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.appSettings,
      getReferencedColumn: (t) => t.defaultReciterId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $AppSettingsFilterComposer(
            $db: $db,
            $table: $db.appSettings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> recordingEditionsRefs(
    Expression<bool> Function($RecordingEditionsFilterComposer f) f,
  ) {
    final $RecordingEditionsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.recordingEditions,
      getReferencedColumn: (t) => t.reciterId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $RecordingEditionsFilterComposer(
            $db: $db,
            $table: $db.recordingEditions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $RecitersOrderingComposer extends Composer<_$AppDatabase, Reciters> {
  $RecitersOrderingComposer({
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

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get arabicName => $composableBuilder(
    column: $table.arabicName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get attribution => $composableBuilder(
    column: $table.attribution,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceInfo => $composableBuilder(
    column: $table.sourceInfo,
    builder: (column) => ColumnOrderings(column),
  );
}

class $RecitersAnnotationComposer extends Composer<_$AppDatabase, Reciters> {
  $RecitersAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get arabicName => $composableBuilder(
    column: $table.arabicName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get attribution => $composableBuilder(
    column: $table.attribution,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourceInfo => $composableBuilder(
    column: $table.sourceInfo,
    builder: (column) => column,
  );

  Expression<T> appSettingsRefs<T extends Object>(
    Expression<T> Function($AppSettingsAnnotationComposer a) f,
  ) {
    final $AppSettingsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.appSettings,
      getReferencedColumn: (t) => t.defaultReciterId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $AppSettingsAnnotationComposer(
            $db: $db,
            $table: $db.appSettings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> recordingEditionsRefs<T extends Object>(
    Expression<T> Function($RecordingEditionsAnnotationComposer a) f,
  ) {
    final $RecordingEditionsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.recordingEditions,
      getReferencedColumn: (t) => t.reciterId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $RecordingEditionsAnnotationComposer(
            $db: $db,
            $table: $db.recordingEditions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $RecitersTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          Reciters,
          Reciter,
          $RecitersFilterComposer,
          $RecitersOrderingComposer,
          $RecitersAnnotationComposer,
          $RecitersCreateCompanionBuilder,
          $RecitersUpdateCompanionBuilder,
          (Reciter, $RecitersReferences),
          Reciter,
          PrefetchHooks Function({
            bool appSettingsRefs,
            bool recordingEditionsRefs,
          })
        > {
  $RecitersTableManager(_$AppDatabase db, Reciters table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $RecitersFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $RecitersOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $RecitersAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<String?> arabicName = const Value.absent(),
                Value<String> attribution = const Value.absent(),
                Value<String> sourceInfo = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RecitersCompanion(
                id: id,
                displayName: displayName,
                arabicName: arabicName,
                attribution: attribution,
                sourceInfo: sourceInfo,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String displayName,
                Value<String?> arabicName = const Value.absent(),
                required String attribution,
                required String sourceInfo,
                Value<int> rowid = const Value.absent(),
              }) => RecitersCompanion.insert(
                id: id,
                displayName: displayName,
                arabicName: arabicName,
                attribution: attribution,
                sourceInfo: sourceInfo,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<Reciters, Reciter>(table),
                  $RecitersReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({appSettingsRefs = false, recordingEditionsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (appSettingsRefs) db.appSettings,
                    if (recordingEditionsRefs) db.recordingEditions,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (appSettingsRefs)
                        await $_getPrefetchedData<
                          Reciter,
                          Reciters,
                          AppSetting
                        >(
                          currentTable: table,
                          referencedTable: $RecitersReferences
                              ._appSettingsRefsTable(db),
                          managerFromTypedResult: (p0) => $RecitersReferences(
                            db,
                            table,
                            p0,
                          ).appSettingsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.defaultReciterId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (recordingEditionsRefs)
                        await $_getPrefetchedData<
                          Reciter,
                          Reciters,
                          RecordingEdition
                        >(
                          currentTable: table,
                          referencedTable: $RecitersReferences
                              ._recordingEditionsRefsTable(db),
                          managerFromTypedResult: (p0) => $RecitersReferences(
                            db,
                            table,
                            p0,
                          ).recordingEditionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.reciterId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $RecitersProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      Reciters,
      Reciter,
      $RecitersFilterComposer,
      $RecitersOrderingComposer,
      $RecitersAnnotationComposer,
      $RecitersCreateCompanionBuilder,
      $RecitersUpdateCompanionBuilder,
      (Reciter, $RecitersReferences),
      Reciter,
      PrefetchHooks Function({bool appSettingsRefs, bool recordingEditionsRefs})
    >;
typedef $AppSettingsCreateCompanionBuilder = AppSettingsCompanion Function({
  Value<int> id,
  Value<String> theme,
  Value<int> reducedMotion,
  Value<String> networkPolicy,
  Value<String?> defaultReciterId,
  Value<int> dailyGoalMs,
  Value<int> preferencesVersion,
  Value<int> updatedUtcMs,
});
typedef $AppSettingsUpdateCompanionBuilder = AppSettingsCompanion Function({
  Value<int> id,
  Value<String> theme,
  Value<int> reducedMotion,
  Value<String> networkPolicy,
  Value<String?> defaultReciterId,
  Value<int> dailyGoalMs,
  Value<int> preferencesVersion,
  Value<int> updatedUtcMs,
});

final class $AppSettingsReferences
    extends BaseReferences<_$AppDatabase, AppSettings, AppSetting> {
  $AppSettingsReferences(super.$_db, super.$_table, super.$_typedResult);

  static Reciters _defaultReciterIdTable(_$AppDatabase db) =>
      db.reciters.createAlias('app_settings__default_reciter_id__reciters__id');

  $RecitersProcessedTableManager? get defaultReciterId {
    final $_column = $_itemColumn<String>('default_reciter_id');
    if ($_column == null) return null;
    final manager = $RecitersTableManager(
      $_db,
      $_db.reciters,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_defaultReciterIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $AppSettingsFilterComposer extends Composer<_$AppDatabase, AppSettings> {
  $AppSettingsFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get theme => $composableBuilder(
    column: $table.theme,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reducedMotion => $composableBuilder(
    column: $table.reducedMotion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get networkPolicy => $composableBuilder(
    column: $table.networkPolicy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dailyGoalMs => $composableBuilder(
    column: $table.dailyGoalMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get preferencesVersion => $composableBuilder(
    column: $table.preferencesVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedUtcMs => $composableBuilder(
    column: $table.updatedUtcMs,
    builder: (column) => ColumnFilters(column),
  );

  $RecitersFilterComposer get defaultReciterId {
    final $RecitersFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.defaultReciterId,
      referencedTable: $db.reciters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $RecitersFilterComposer(
            $db: $db,
            $table: $db.reciters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $AppSettingsOrderingComposer
    extends Composer<_$AppDatabase, AppSettings> {
  $AppSettingsOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get theme => $composableBuilder(
    column: $table.theme,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reducedMotion => $composableBuilder(
    column: $table.reducedMotion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get networkPolicy => $composableBuilder(
    column: $table.networkPolicy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dailyGoalMs => $composableBuilder(
    column: $table.dailyGoalMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get preferencesVersion => $composableBuilder(
    column: $table.preferencesVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedUtcMs => $composableBuilder(
    column: $table.updatedUtcMs,
    builder: (column) => ColumnOrderings(column),
  );

  $RecitersOrderingComposer get defaultReciterId {
    final $RecitersOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.defaultReciterId,
      referencedTable: $db.reciters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $RecitersOrderingComposer(
            $db: $db,
            $table: $db.reciters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $AppSettingsAnnotationComposer
    extends Composer<_$AppDatabase, AppSettings> {
  $AppSettingsAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get theme =>
      $composableBuilder(column: $table.theme, builder: (column) => column);

  GeneratedColumn<int> get reducedMotion => $composableBuilder(
    column: $table.reducedMotion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get networkPolicy => $composableBuilder(
    column: $table.networkPolicy,
    builder: (column) => column,
  );

  GeneratedColumn<int> get dailyGoalMs => $composableBuilder(
    column: $table.dailyGoalMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get preferencesVersion => $composableBuilder(
    column: $table.preferencesVersion,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updatedUtcMs => $composableBuilder(
    column: $table.updatedUtcMs,
    builder: (column) => column,
  );

  $RecitersAnnotationComposer get defaultReciterId {
    final $RecitersAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.defaultReciterId,
      referencedTable: $db.reciters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $RecitersAnnotationComposer(
            $db: $db,
            $table: $db.reciters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $AppSettingsTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          AppSettings,
          AppSetting,
          $AppSettingsFilterComposer,
          $AppSettingsOrderingComposer,
          $AppSettingsAnnotationComposer,
          $AppSettingsCreateCompanionBuilder,
          $AppSettingsUpdateCompanionBuilder,
          (AppSetting, $AppSettingsReferences),
          AppSetting,
          PrefetchHooks Function({bool defaultReciterId})
        > {
  $AppSettingsTableManager(_$AppDatabase db, AppSettings table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $AppSettingsFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $AppSettingsOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $AppSettingsAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> theme = const Value.absent(),
                Value<int> reducedMotion = const Value.absent(),
                Value<String> networkPolicy = const Value.absent(),
                Value<String?> defaultReciterId = const Value.absent(),
                Value<int> dailyGoalMs = const Value.absent(),
                Value<int> preferencesVersion = const Value.absent(),
                Value<int> updatedUtcMs = const Value.absent(),
              }) => AppSettingsCompanion(
                id: id,
                theme: theme,
                reducedMotion: reducedMotion,
                networkPolicy: networkPolicy,
                defaultReciterId: defaultReciterId,
                dailyGoalMs: dailyGoalMs,
                preferencesVersion: preferencesVersion,
                updatedUtcMs: updatedUtcMs,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> theme = const Value.absent(),
                Value<int> reducedMotion = const Value.absent(),
                Value<String> networkPolicy = const Value.absent(),
                Value<String?> defaultReciterId = const Value.absent(),
                Value<int> dailyGoalMs = const Value.absent(),
                Value<int> preferencesVersion = const Value.absent(),
                Value<int> updatedUtcMs = const Value.absent(),
              }) => AppSettingsCompanion.insert(
                id: id,
                theme: theme,
                reducedMotion: reducedMotion,
                networkPolicy: networkPolicy,
                defaultReciterId: defaultReciterId,
                dailyGoalMs: dailyGoalMs,
                preferencesVersion: preferencesVersion,
                updatedUtcMs: updatedUtcMs,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<AppSettings, AppSetting>(table),
                  $AppSettingsReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({defaultReciterId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (defaultReciterId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.defaultReciterId,
                        referencedTable: $AppSettingsReferences
                            ._defaultReciterIdTable(db),
                        referencedColumn: $AppSettingsReferences
                            ._defaultReciterIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $AppSettingsProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      AppSettings,
      AppSetting,
      $AppSettingsFilterComposer,
      $AppSettingsOrderingComposer,
      $AppSettingsAnnotationComposer,
      $AppSettingsCreateCompanionBuilder,
      $AppSettingsUpdateCompanionBuilder,
      (AppSetting, $AppSettingsReferences),
      AppSetting,
      PrefetchHooks Function({bool defaultReciterId})
    >;
typedef $SurahsCreateCompanionBuilder = SurahsCompanion Function({
  Value<int> number,
  required String arabicName,
  required String transliteration,
  required String searchAliases,
});
typedef $SurahsUpdateCompanionBuilder = SurahsCompanion Function({
  Value<int> number,
  Value<String> arabicName,
  Value<String> transliteration,
  Value<String> searchAliases,
});

final class $SurahsReferences
    extends BaseReferences<_$AppDatabase, Surahs, Surah> {
  $SurahsReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<AudioAssets, List<AudioAsset>>
  _audioAssetsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.audioAssets,
    aliasName: 'surahs__number__audio_assets__surah_number',
  );

  $AudioAssetsProcessedTableManager get audioAssetsRefs {
    final manager = $AudioAssetsTableManager($_db, $_db.audioAssets).filter(
      (f) => f.surahNumber.number.sqlEquals($_itemColumn<int>('number')!),
    );

    final cache = $_typedResult.readTableOrNull(_audioAssetsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $SurahsFilterComposer extends Composer<_$AppDatabase, Surahs> {
  $SurahsFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get number => $composableBuilder(
    column: $table.number,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get arabicName => $composableBuilder(
    column: $table.arabicName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get transliteration => $composableBuilder(
    column: $table.transliteration,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get searchAliases => $composableBuilder(
    column: $table.searchAliases,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> audioAssetsRefs(
    Expression<bool> Function($AudioAssetsFilterComposer f) f,
  ) {
    final $AudioAssetsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.number,
      referencedTable: $db.audioAssets,
      getReferencedColumn: (t) => t.surahNumber,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $AudioAssetsFilterComposer(
            $db: $db,
            $table: $db.audioAssets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $SurahsOrderingComposer extends Composer<_$AppDatabase, Surahs> {
  $SurahsOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get number => $composableBuilder(
    column: $table.number,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get arabicName => $composableBuilder(
    column: $table.arabicName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get transliteration => $composableBuilder(
    column: $table.transliteration,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get searchAliases => $composableBuilder(
    column: $table.searchAliases,
    builder: (column) => ColumnOrderings(column),
  );
}

class $SurahsAnnotationComposer extends Composer<_$AppDatabase, Surahs> {
  $SurahsAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get number =>
      $composableBuilder(column: $table.number, builder: (column) => column);

  GeneratedColumn<String> get arabicName => $composableBuilder(
    column: $table.arabicName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get transliteration => $composableBuilder(
    column: $table.transliteration,
    builder: (column) => column,
  );

  GeneratedColumn<String> get searchAliases => $composableBuilder(
    column: $table.searchAliases,
    builder: (column) => column,
  );

  Expression<T> audioAssetsRefs<T extends Object>(
    Expression<T> Function($AudioAssetsAnnotationComposer a) f,
  ) {
    final $AudioAssetsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.number,
      referencedTable: $db.audioAssets,
      getReferencedColumn: (t) => t.surahNumber,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $AudioAssetsAnnotationComposer(
            $db: $db,
            $table: $db.audioAssets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $SurahsTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          Surahs,
          Surah,
          $SurahsFilterComposer,
          $SurahsOrderingComposer,
          $SurahsAnnotationComposer,
          $SurahsCreateCompanionBuilder,
          $SurahsUpdateCompanionBuilder,
          (Surah, $SurahsReferences),
          Surah,
          PrefetchHooks Function({bool audioAssetsRefs})
        > {
  $SurahsTableManager(_$AppDatabase db, Surahs table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $SurahsFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $SurahsOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $SurahsAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> number = const Value.absent(),
                Value<String> arabicName = const Value.absent(),
                Value<String> transliteration = const Value.absent(),
                Value<String> searchAliases = const Value.absent(),
              }) => SurahsCompanion(
                number: number,
                arabicName: arabicName,
                transliteration: transliteration,
                searchAliases: searchAliases,
              ),
          createCompanionCallback:
              ({
                Value<int> number = const Value.absent(),
                required String arabicName,
                required String transliteration,
                required String searchAliases,
              }) => SurahsCompanion.insert(
                number: number,
                arabicName: arabicName,
                transliteration: transliteration,
                searchAliases: searchAliases,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<Surahs, Surah>(table),
                  $SurahsReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({audioAssetsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (audioAssetsRefs) db.audioAssets],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (audioAssetsRefs)
                    await $_getPrefetchedData<Surah, Surahs, AudioAsset>(
                      currentTable: table,
                      referencedTable: $SurahsReferences._audioAssetsRefsTable(
                        db,
                      ),
                      managerFromTypedResult: (p0) =>
                          $SurahsReferences(db, table, p0).audioAssetsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.surahNumber == item.number,
                          ),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $SurahsProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      Surahs,
      Surah,
      $SurahsFilterComposer,
      $SurahsOrderingComposer,
      $SurahsAnnotationComposer,
      $SurahsCreateCompanionBuilder,
      $SurahsUpdateCompanionBuilder,
      (Surah, $SurahsReferences),
      Surah,
      PrefetchHooks Function({bool audioAssetsRefs})
    >;
typedef $RecordingEditionsCreateCompanionBuilder =
    RecordingEditionsCompanion Function({
      required String id,
      required String reciterId,
      Value<String?> riwayah,
      required String sourceNotes,
      Value<int> rowid,
    });
typedef $RecordingEditionsUpdateCompanionBuilder =
    RecordingEditionsCompanion Function({
      Value<String> id,
      Value<String> reciterId,
      Value<String?> riwayah,
      Value<String> sourceNotes,
      Value<int> rowid,
    });

final class $RecordingEditionsReferences
    extends BaseReferences<_$AppDatabase, RecordingEditions, RecordingEdition> {
  $RecordingEditionsReferences(super.$_db, super.$_table, super.$_typedResult);

  static Reciters _reciterIdTable(_$AppDatabase db) =>
      db.reciters.createAlias('recording_editions__reciter_id__reciters__id');

  $RecitersProcessedTableManager get reciterId {
    final $_column = $_itemColumn<String>('reciter_id')!;

    final manager = $RecitersTableManager(
      $_db,
      $_db.reciters,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_reciterIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<AudioAssets, List<AudioAsset>>
  _audioAssetsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.audioAssets,
    aliasName: 'recording_editions__id__audio_assets__edition_id',
  );

  $AudioAssetsProcessedTableManager get audioAssetsRefs {
    final manager = $AudioAssetsTableManager(
      $_db,
      $_db.audioAssets,
    ).filter((f) => f.editionId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_audioAssetsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $RecordingEditionsFilterComposer
    extends Composer<_$AppDatabase, RecordingEditions> {
  $RecordingEditionsFilterComposer({
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

  ColumnFilters<String> get riwayah => $composableBuilder(
    column: $table.riwayah,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceNotes => $composableBuilder(
    column: $table.sourceNotes,
    builder: (column) => ColumnFilters(column),
  );

  $RecitersFilterComposer get reciterId {
    final $RecitersFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.reciterId,
      referencedTable: $db.reciters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $RecitersFilterComposer(
            $db: $db,
            $table: $db.reciters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> audioAssetsRefs(
    Expression<bool> Function($AudioAssetsFilterComposer f) f,
  ) {
    final $AudioAssetsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.audioAssets,
      getReferencedColumn: (t) => t.editionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $AudioAssetsFilterComposer(
            $db: $db,
            $table: $db.audioAssets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $RecordingEditionsOrderingComposer
    extends Composer<_$AppDatabase, RecordingEditions> {
  $RecordingEditionsOrderingComposer({
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

  ColumnOrderings<String> get riwayah => $composableBuilder(
    column: $table.riwayah,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceNotes => $composableBuilder(
    column: $table.sourceNotes,
    builder: (column) => ColumnOrderings(column),
  );

  $RecitersOrderingComposer get reciterId {
    final $RecitersOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.reciterId,
      referencedTable: $db.reciters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $RecitersOrderingComposer(
            $db: $db,
            $table: $db.reciters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $RecordingEditionsAnnotationComposer
    extends Composer<_$AppDatabase, RecordingEditions> {
  $RecordingEditionsAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get riwayah =>
      $composableBuilder(column: $table.riwayah, builder: (column) => column);

  GeneratedColumn<String> get sourceNotes => $composableBuilder(
    column: $table.sourceNotes,
    builder: (column) => column,
  );

  $RecitersAnnotationComposer get reciterId {
    final $RecitersAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.reciterId,
      referencedTable: $db.reciters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $RecitersAnnotationComposer(
            $db: $db,
            $table: $db.reciters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> audioAssetsRefs<T extends Object>(
    Expression<T> Function($AudioAssetsAnnotationComposer a) f,
  ) {
    final $AudioAssetsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.audioAssets,
      getReferencedColumn: (t) => t.editionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $AudioAssetsAnnotationComposer(
            $db: $db,
            $table: $db.audioAssets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $RecordingEditionsTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          RecordingEditions,
          RecordingEdition,
          $RecordingEditionsFilterComposer,
          $RecordingEditionsOrderingComposer,
          $RecordingEditionsAnnotationComposer,
          $RecordingEditionsCreateCompanionBuilder,
          $RecordingEditionsUpdateCompanionBuilder,
          (RecordingEdition, $RecordingEditionsReferences),
          RecordingEdition,
          PrefetchHooks Function({bool reciterId, bool audioAssetsRefs})
        > {
  $RecordingEditionsTableManager(_$AppDatabase db, RecordingEditions table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $RecordingEditionsFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $RecordingEditionsOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $RecordingEditionsAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> reciterId = const Value.absent(),
                Value<String?> riwayah = const Value.absent(),
                Value<String> sourceNotes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RecordingEditionsCompanion(
                id: id,
                reciterId: reciterId,
                riwayah: riwayah,
                sourceNotes: sourceNotes,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String reciterId,
                Value<String?> riwayah = const Value.absent(),
                required String sourceNotes,
                Value<int> rowid = const Value.absent(),
              }) => RecordingEditionsCompanion.insert(
                id: id,
                reciterId: reciterId,
                riwayah: riwayah,
                sourceNotes: sourceNotes,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<RecordingEditions, RecordingEdition>(table),
                  $RecordingEditionsReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({reciterId = false, audioAssetsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (audioAssetsRefs) db.audioAssets,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (reciterId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.reciterId,
                            referencedTable: $RecordingEditionsReferences
                                ._reciterIdTable(db),
                            referencedColumn: $RecordingEditionsReferences
                                ._reciterIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (audioAssetsRefs)
                        await $_getPrefetchedData<
                          RecordingEdition,
                          RecordingEditions,
                          AudioAsset
                        >(
                          currentTable: table,
                          referencedTable: $RecordingEditionsReferences
                              ._audioAssetsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $RecordingEditionsReferences(
                                db,
                                table,
                                p0,
                              ).audioAssetsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.editionId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $RecordingEditionsProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      RecordingEditions,
      RecordingEdition,
      $RecordingEditionsFilterComposer,
      $RecordingEditionsOrderingComposer,
      $RecordingEditionsAnnotationComposer,
      $RecordingEditionsCreateCompanionBuilder,
      $RecordingEditionsUpdateCompanionBuilder,
      (RecordingEdition, $RecordingEditionsReferences),
      RecordingEdition,
      PrefetchHooks Function({bool reciterId, bool audioAssetsRefs})
    >;
typedef $AudioAssetsCreateCompanionBuilder = AudioAssetsCompanion Function({
  required String id,
  required String editionId,
  required int surahNumber,
  required int version,
  required String url,
  required String mimeType,
  Value<int?> durationMs,
  Value<int?> byteSize,
  Value<String?> sha256,
  required String availability,
  Value<int> rowid,
});
typedef $AudioAssetsUpdateCompanionBuilder = AudioAssetsCompanion Function({
  Value<String> id,
  Value<String> editionId,
  Value<int> surahNumber,
  Value<int> version,
  Value<String> url,
  Value<String> mimeType,
  Value<int?> durationMs,
  Value<int?> byteSize,
  Value<String?> sha256,
  Value<String> availability,
  Value<int> rowid,
});

final class $AudioAssetsReferences
    extends BaseReferences<_$AppDatabase, AudioAssets, AudioAsset> {
  $AudioAssetsReferences(super.$_db, super.$_table, super.$_typedResult);

  static RecordingEditions _editionIdTable(_$AppDatabase db) => db
      .recordingEditions
      .createAlias('audio_assets__edition_id__recording_editions__id');

  $RecordingEditionsProcessedTableManager get editionId {
    final $_column = $_itemColumn<String>('edition_id')!;

    final manager = $RecordingEditionsTableManager(
      $_db,
      $_db.recordingEditions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_editionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static Surahs _surahNumberTable(_$AppDatabase db) =>
      db.surahs.createAlias('audio_assets__surah_number__surahs__number');

  $SurahsProcessedTableManager get surahNumber {
    final $_column = $_itemColumn<int>('surah_number')!;

    final manager = $SurahsTableManager(
      $_db,
      $_db.surahs,
    ).filter((f) => f.number.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_surahNumberTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<SavedPassages, List<SavedPassage>>
  _savedPassagesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.savedPassages,
    aliasName: 'audio_assets__id__saved_passages__asset_id',
  );

  $SavedPassagesProcessedTableManager get savedPassagesRefs {
    final manager = $SavedPassagesTableManager(
      $_db,
      $_db.savedPassages,
    ).filter((f) => f.assetId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_savedPassagesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<Downloads, List<Download>> _downloadsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.downloads,
    aliasName: 'audio_assets__id__downloads__asset_id',
  );

  $DownloadsProcessedTableManager get downloadsRefs {
    final manager = $DownloadsTableManager(
      $_db,
      $_db.downloads,
    ).filter((f) => f.assetId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_downloadsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<PlaybackCheckpoints, List<PlaybackCheckpoint>>
  _playbackCheckpointsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.playbackCheckpoints,
        aliasName: 'audio_assets__id__playback_checkpoints__asset_id',
      );

  $PlaybackCheckpointsProcessedTableManager get playbackCheckpointsRefs {
    final manager = $PlaybackCheckpointsTableManager(
      $_db,
      $_db.playbackCheckpoints,
    ).filter((f) => f.assetId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _playbackCheckpointsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<ListeningSessions, List<ListeningSession>>
  _listeningSessionsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.listeningSessions,
        aliasName: 'audio_assets__id__listening_sessions__asset_id',
      );

  $ListeningSessionsProcessedTableManager get listeningSessionsRefs {
    final manager = $ListeningSessionsTableManager(
      $_db,
      $_db.listeningSessions,
    ).filter((f) => f.assetId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _listeningSessionsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $AudioAssetsFilterComposer extends Composer<_$AppDatabase, AudioAssets> {
  $AudioAssetsFilterComposer({
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

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mimeType => $composableBuilder(
    column: $table.mimeType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get byteSize => $composableBuilder(
    column: $table.byteSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sha256 => $composableBuilder(
    column: $table.sha256,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get availability => $composableBuilder(
    column: $table.availability,
    builder: (column) => ColumnFilters(column),
  );

  $RecordingEditionsFilterComposer get editionId {
    final $RecordingEditionsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.editionId,
      referencedTable: $db.recordingEditions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $RecordingEditionsFilterComposer(
            $db: $db,
            $table: $db.recordingEditions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $SurahsFilterComposer get surahNumber {
    final $SurahsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.surahNumber,
      referencedTable: $db.surahs,
      getReferencedColumn: (t) => t.number,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $SurahsFilterComposer(
            $db: $db,
            $table: $db.surahs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> savedPassagesRefs(
    Expression<bool> Function($SavedPassagesFilterComposer f) f,
  ) {
    final $SavedPassagesFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.savedPassages,
      getReferencedColumn: (t) => t.assetId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $SavedPassagesFilterComposer(
            $db: $db,
            $table: $db.savedPassages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> downloadsRefs(
    Expression<bool> Function($DownloadsFilterComposer f) f,
  ) {
    final $DownloadsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.downloads,
      getReferencedColumn: (t) => t.assetId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $DownloadsFilterComposer(
            $db: $db,
            $table: $db.downloads,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> playbackCheckpointsRefs(
    Expression<bool> Function($PlaybackCheckpointsFilterComposer f) f,
  ) {
    final $PlaybackCheckpointsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.playbackCheckpoints,
      getReferencedColumn: (t) => t.assetId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $PlaybackCheckpointsFilterComposer(
            $db: $db,
            $table: $db.playbackCheckpoints,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> listeningSessionsRefs(
    Expression<bool> Function($ListeningSessionsFilterComposer f) f,
  ) {
    final $ListeningSessionsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.listeningSessions,
      getReferencedColumn: (t) => t.assetId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ListeningSessionsFilterComposer(
            $db: $db,
            $table: $db.listeningSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $AudioAssetsOrderingComposer
    extends Composer<_$AppDatabase, AudioAssets> {
  $AudioAssetsOrderingComposer({
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

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mimeType => $composableBuilder(
    column: $table.mimeType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get byteSize => $composableBuilder(
    column: $table.byteSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sha256 => $composableBuilder(
    column: $table.sha256,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get availability => $composableBuilder(
    column: $table.availability,
    builder: (column) => ColumnOrderings(column),
  );

  $RecordingEditionsOrderingComposer get editionId {
    final $RecordingEditionsOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.editionId,
      referencedTable: $db.recordingEditions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $RecordingEditionsOrderingComposer(
            $db: $db,
            $table: $db.recordingEditions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $SurahsOrderingComposer get surahNumber {
    final $SurahsOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.surahNumber,
      referencedTable: $db.surahs,
      getReferencedColumn: (t) => t.number,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $SurahsOrderingComposer(
            $db: $db,
            $table: $db.surahs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $AudioAssetsAnnotationComposer
    extends Composer<_$AppDatabase, AudioAssets> {
  $AudioAssetsAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<String> get url =>
      $composableBuilder(column: $table.url, builder: (column) => column);

  GeneratedColumn<String> get mimeType =>
      $composableBuilder(column: $table.mimeType, builder: (column) => column);

  GeneratedColumn<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get byteSize =>
      $composableBuilder(column: $table.byteSize, builder: (column) => column);

  GeneratedColumn<String> get sha256 =>
      $composableBuilder(column: $table.sha256, builder: (column) => column);

  GeneratedColumn<String> get availability => $composableBuilder(
    column: $table.availability,
    builder: (column) => column,
  );

  $RecordingEditionsAnnotationComposer get editionId {
    final $RecordingEditionsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.editionId,
      referencedTable: $db.recordingEditions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $RecordingEditionsAnnotationComposer(
            $db: $db,
            $table: $db.recordingEditions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $SurahsAnnotationComposer get surahNumber {
    final $SurahsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.surahNumber,
      referencedTable: $db.surahs,
      getReferencedColumn: (t) => t.number,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $SurahsAnnotationComposer(
            $db: $db,
            $table: $db.surahs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> savedPassagesRefs<T extends Object>(
    Expression<T> Function($SavedPassagesAnnotationComposer a) f,
  ) {
    final $SavedPassagesAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.savedPassages,
      getReferencedColumn: (t) => t.assetId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $SavedPassagesAnnotationComposer(
            $db: $db,
            $table: $db.savedPassages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> downloadsRefs<T extends Object>(
    Expression<T> Function($DownloadsAnnotationComposer a) f,
  ) {
    final $DownloadsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.downloads,
      getReferencedColumn: (t) => t.assetId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $DownloadsAnnotationComposer(
            $db: $db,
            $table: $db.downloads,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> playbackCheckpointsRefs<T extends Object>(
    Expression<T> Function($PlaybackCheckpointsAnnotationComposer a) f,
  ) {
    final $PlaybackCheckpointsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.playbackCheckpoints,
      getReferencedColumn: (t) => t.assetId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $PlaybackCheckpointsAnnotationComposer(
            $db: $db,
            $table: $db.playbackCheckpoints,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> listeningSessionsRefs<T extends Object>(
    Expression<T> Function($ListeningSessionsAnnotationComposer a) f,
  ) {
    final $ListeningSessionsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.listeningSessions,
      getReferencedColumn: (t) => t.assetId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ListeningSessionsAnnotationComposer(
            $db: $db,
            $table: $db.listeningSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $AudioAssetsTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          AudioAssets,
          AudioAsset,
          $AudioAssetsFilterComposer,
          $AudioAssetsOrderingComposer,
          $AudioAssetsAnnotationComposer,
          $AudioAssetsCreateCompanionBuilder,
          $AudioAssetsUpdateCompanionBuilder,
          (AudioAsset, $AudioAssetsReferences),
          AudioAsset,
          PrefetchHooks Function({
            bool editionId,
            bool surahNumber,
            bool savedPassagesRefs,
            bool downloadsRefs,
            bool playbackCheckpointsRefs,
            bool listeningSessionsRefs,
          })
        > {
  $AudioAssetsTableManager(_$AppDatabase db, AudioAssets table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $AudioAssetsFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $AudioAssetsOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $AudioAssetsAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> editionId = const Value.absent(),
                Value<int> surahNumber = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<String> url = const Value.absent(),
                Value<String> mimeType = const Value.absent(),
                Value<int?> durationMs = const Value.absent(),
                Value<int?> byteSize = const Value.absent(),
                Value<String?> sha256 = const Value.absent(),
                Value<String> availability = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AudioAssetsCompanion(
                id: id,
                editionId: editionId,
                surahNumber: surahNumber,
                version: version,
                url: url,
                mimeType: mimeType,
                durationMs: durationMs,
                byteSize: byteSize,
                sha256: sha256,
                availability: availability,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String editionId,
                required int surahNumber,
                required int version,
                required String url,
                required String mimeType,
                Value<int?> durationMs = const Value.absent(),
                Value<int?> byteSize = const Value.absent(),
                Value<String?> sha256 = const Value.absent(),
                required String availability,
                Value<int> rowid = const Value.absent(),
              }) => AudioAssetsCompanion.insert(
                id: id,
                editionId: editionId,
                surahNumber: surahNumber,
                version: version,
                url: url,
                mimeType: mimeType,
                durationMs: durationMs,
                byteSize: byteSize,
                sha256: sha256,
                availability: availability,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<AudioAssets, AudioAsset>(table),
                  $AudioAssetsReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                editionId = false,
                surahNumber = false,
                savedPassagesRefs = false,
                downloadsRefs = false,
                playbackCheckpointsRefs = false,
                listeningSessionsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (savedPassagesRefs) db.savedPassages,
                    if (downloadsRefs) db.downloads,
                    if (playbackCheckpointsRefs) db.playbackCheckpoints,
                    if (listeningSessionsRefs) db.listeningSessions,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (editionId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.editionId,
                            referencedTable: $AudioAssetsReferences
                                ._editionIdTable(db),
                            referencedColumn: $AudioAssetsReferences
                                ._editionIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (surahNumber) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.surahNumber,
                            referencedTable: $AudioAssetsReferences
                                ._surahNumberTable(db),
                            referencedColumn: $AudioAssetsReferences
                                ._surahNumberTable(db)
                                .number,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (savedPassagesRefs)
                        await $_getPrefetchedData<
                          AudioAsset,
                          AudioAssets,
                          SavedPassage
                        >(
                          currentTable: table,
                          referencedTable: $AudioAssetsReferences
                              ._savedPassagesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $AudioAssetsReferences(
                                db,
                                table,
                                p0,
                              ).savedPassagesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.assetId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (downloadsRefs)
                        await $_getPrefetchedData<
                          AudioAsset,
                          AudioAssets,
                          Download
                        >(
                          currentTable: table,
                          referencedTable: $AudioAssetsReferences
                              ._downloadsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $AudioAssetsReferences(
                                db,
                                table,
                                p0,
                              ).downloadsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.assetId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (playbackCheckpointsRefs)
                        await $_getPrefetchedData<
                          AudioAsset,
                          AudioAssets,
                          PlaybackCheckpoint
                        >(
                          currentTable: table,
                          referencedTable: $AudioAssetsReferences
                              ._playbackCheckpointsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $AudioAssetsReferences(
                                db,
                                table,
                                p0,
                              ).playbackCheckpointsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.assetId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (listeningSessionsRefs)
                        await $_getPrefetchedData<
                          AudioAsset,
                          AudioAssets,
                          ListeningSession
                        >(
                          currentTable: table,
                          referencedTable: $AudioAssetsReferences
                              ._listeningSessionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $AudioAssetsReferences(
                                db,
                                table,
                                p0,
                              ).listeningSessionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.assetId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $AudioAssetsProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      AudioAssets,
      AudioAsset,
      $AudioAssetsFilterComposer,
      $AudioAssetsOrderingComposer,
      $AudioAssetsAnnotationComposer,
      $AudioAssetsCreateCompanionBuilder,
      $AudioAssetsUpdateCompanionBuilder,
      (AudioAsset, $AudioAssetsReferences),
      AudioAsset,
      PrefetchHooks Function({
        bool editionId,
        bool surahNumber,
        bool savedPassagesRefs,
        bool downloadsRefs,
        bool playbackCheckpointsRefs,
        bool listeningSessionsRefs,
      })
    >;
typedef $SavedPassagesCreateCompanionBuilder = SavedPassagesCompanion Function({
  required String id,
  required String assetId,
  required String title,
  required int startMs,
  required int endMs,
  required String repeatMode,
  Value<int?> playCount,
  Value<int> gapMs,
  Value<double> speed,
  Value<String?> note,
  required int createdUtcMs,
  required int updatedUtcMs,
  Value<int> rowid,
});
typedef $SavedPassagesUpdateCompanionBuilder = SavedPassagesCompanion Function({
  Value<String> id,
  Value<String> assetId,
  Value<String> title,
  Value<int> startMs,
  Value<int> endMs,
  Value<String> repeatMode,
  Value<int?> playCount,
  Value<int> gapMs,
  Value<double> speed,
  Value<String?> note,
  Value<int> createdUtcMs,
  Value<int> updatedUtcMs,
  Value<int> rowid,
});

final class $SavedPassagesReferences
    extends BaseReferences<_$AppDatabase, SavedPassages, SavedPassage> {
  $SavedPassagesReferences(super.$_db, super.$_table, super.$_typedResult);

  static AudioAssets _assetIdTable(_$AppDatabase db) =>
      db.audioAssets.createAlias('saved_passages__asset_id__audio_assets__id');

  $AudioAssetsProcessedTableManager get assetId {
    final $_column = $_itemColumn<String>('asset_id')!;

    final manager = $AudioAssetsTableManager(
      $_db,
      $_db.audioAssets,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_assetIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<PlaybackCheckpoints, List<PlaybackCheckpoint>>
  _playbackCheckpointsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.playbackCheckpoints,
        aliasName: 'saved_passages__id__playback_checkpoints__passage_id',
      );

  $PlaybackCheckpointsProcessedTableManager get playbackCheckpointsRefs {
    final manager = $PlaybackCheckpointsTableManager(
      $_db,
      $_db.playbackCheckpoints,
    ).filter((f) => f.passageId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _playbackCheckpointsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<ListeningSessions, List<ListeningSession>>
  _listeningSessionsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.listeningSessions,
        aliasName: 'saved_passages__id__listening_sessions__passage_id',
      );

  $ListeningSessionsProcessedTableManager get listeningSessionsRefs {
    final manager = $ListeningSessionsTableManager(
      $_db,
      $_db.listeningSessions,
    ).filter((f) => f.passageId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _listeningSessionsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $SavedPassagesFilterComposer
    extends Composer<_$AppDatabase, SavedPassages> {
  $SavedPassagesFilterComposer({
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

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startMs => $composableBuilder(
    column: $table.startMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endMs => $composableBuilder(
    column: $table.endMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get repeatMode => $composableBuilder(
    column: $table.repeatMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get playCount => $composableBuilder(
    column: $table.playCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get gapMs => $composableBuilder(
    column: $table.gapMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get speed => $composableBuilder(
    column: $table.speed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdUtcMs => $composableBuilder(
    column: $table.createdUtcMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedUtcMs => $composableBuilder(
    column: $table.updatedUtcMs,
    builder: (column) => ColumnFilters(column),
  );

  $AudioAssetsFilterComposer get assetId {
    final $AudioAssetsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.assetId,
      referencedTable: $db.audioAssets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $AudioAssetsFilterComposer(
            $db: $db,
            $table: $db.audioAssets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> playbackCheckpointsRefs(
    Expression<bool> Function($PlaybackCheckpointsFilterComposer f) f,
  ) {
    final $PlaybackCheckpointsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.playbackCheckpoints,
      getReferencedColumn: (t) => t.passageId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $PlaybackCheckpointsFilterComposer(
            $db: $db,
            $table: $db.playbackCheckpoints,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> listeningSessionsRefs(
    Expression<bool> Function($ListeningSessionsFilterComposer f) f,
  ) {
    final $ListeningSessionsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.listeningSessions,
      getReferencedColumn: (t) => t.passageId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ListeningSessionsFilterComposer(
            $db: $db,
            $table: $db.listeningSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $SavedPassagesOrderingComposer
    extends Composer<_$AppDatabase, SavedPassages> {
  $SavedPassagesOrderingComposer({
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

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startMs => $composableBuilder(
    column: $table.startMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endMs => $composableBuilder(
    column: $table.endMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get repeatMode => $composableBuilder(
    column: $table.repeatMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get playCount => $composableBuilder(
    column: $table.playCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get gapMs => $composableBuilder(
    column: $table.gapMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get speed => $composableBuilder(
    column: $table.speed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdUtcMs => $composableBuilder(
    column: $table.createdUtcMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedUtcMs => $composableBuilder(
    column: $table.updatedUtcMs,
    builder: (column) => ColumnOrderings(column),
  );

  $AudioAssetsOrderingComposer get assetId {
    final $AudioAssetsOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.assetId,
      referencedTable: $db.audioAssets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $AudioAssetsOrderingComposer(
            $db: $db,
            $table: $db.audioAssets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $SavedPassagesAnnotationComposer
    extends Composer<_$AppDatabase, SavedPassages> {
  $SavedPassagesAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<int> get startMs =>
      $composableBuilder(column: $table.startMs, builder: (column) => column);

  GeneratedColumn<int> get endMs =>
      $composableBuilder(column: $table.endMs, builder: (column) => column);

  GeneratedColumn<String> get repeatMode => $composableBuilder(
    column: $table.repeatMode,
    builder: (column) => column,
  );

  GeneratedColumn<int> get playCount =>
      $composableBuilder(column: $table.playCount, builder: (column) => column);

  GeneratedColumn<int> get gapMs =>
      $composableBuilder(column: $table.gapMs, builder: (column) => column);

  GeneratedColumn<double> get speed =>
      $composableBuilder(column: $table.speed, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<int> get createdUtcMs => $composableBuilder(
    column: $table.createdUtcMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updatedUtcMs => $composableBuilder(
    column: $table.updatedUtcMs,
    builder: (column) => column,
  );

  $AudioAssetsAnnotationComposer get assetId {
    final $AudioAssetsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.assetId,
      referencedTable: $db.audioAssets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $AudioAssetsAnnotationComposer(
            $db: $db,
            $table: $db.audioAssets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> playbackCheckpointsRefs<T extends Object>(
    Expression<T> Function($PlaybackCheckpointsAnnotationComposer a) f,
  ) {
    final $PlaybackCheckpointsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.playbackCheckpoints,
      getReferencedColumn: (t) => t.passageId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $PlaybackCheckpointsAnnotationComposer(
            $db: $db,
            $table: $db.playbackCheckpoints,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> listeningSessionsRefs<T extends Object>(
    Expression<T> Function($ListeningSessionsAnnotationComposer a) f,
  ) {
    final $ListeningSessionsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.listeningSessions,
      getReferencedColumn: (t) => t.passageId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ListeningSessionsAnnotationComposer(
            $db: $db,
            $table: $db.listeningSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $SavedPassagesTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          SavedPassages,
          SavedPassage,
          $SavedPassagesFilterComposer,
          $SavedPassagesOrderingComposer,
          $SavedPassagesAnnotationComposer,
          $SavedPassagesCreateCompanionBuilder,
          $SavedPassagesUpdateCompanionBuilder,
          (SavedPassage, $SavedPassagesReferences),
          SavedPassage,
          PrefetchHooks Function({
            bool assetId,
            bool playbackCheckpointsRefs,
            bool listeningSessionsRefs,
          })
        > {
  $SavedPassagesTableManager(_$AppDatabase db, SavedPassages table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $SavedPassagesFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $SavedPassagesOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $SavedPassagesAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> assetId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<int> startMs = const Value.absent(),
                Value<int> endMs = const Value.absent(),
                Value<String> repeatMode = const Value.absent(),
                Value<int?> playCount = const Value.absent(),
                Value<int> gapMs = const Value.absent(),
                Value<double> speed = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int> createdUtcMs = const Value.absent(),
                Value<int> updatedUtcMs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SavedPassagesCompanion(
                id: id,
                assetId: assetId,
                title: title,
                startMs: startMs,
                endMs: endMs,
                repeatMode: repeatMode,
                playCount: playCount,
                gapMs: gapMs,
                speed: speed,
                note: note,
                createdUtcMs: createdUtcMs,
                updatedUtcMs: updatedUtcMs,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String assetId,
                required String title,
                required int startMs,
                required int endMs,
                required String repeatMode,
                Value<int?> playCount = const Value.absent(),
                Value<int> gapMs = const Value.absent(),
                Value<double> speed = const Value.absent(),
                Value<String?> note = const Value.absent(),
                required int createdUtcMs,
                required int updatedUtcMs,
                Value<int> rowid = const Value.absent(),
              }) => SavedPassagesCompanion.insert(
                id: id,
                assetId: assetId,
                title: title,
                startMs: startMs,
                endMs: endMs,
                repeatMode: repeatMode,
                playCount: playCount,
                gapMs: gapMs,
                speed: speed,
                note: note,
                createdUtcMs: createdUtcMs,
                updatedUtcMs: updatedUtcMs,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<SavedPassages, SavedPassage>(table),
                  $SavedPassagesReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                assetId = false,
                playbackCheckpointsRefs = false,
                listeningSessionsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (playbackCheckpointsRefs) db.playbackCheckpoints,
                    if (listeningSessionsRefs) db.listeningSessions,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (assetId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.assetId,
                            referencedTable: $SavedPassagesReferences
                                ._assetIdTable(db),
                            referencedColumn: $SavedPassagesReferences
                                ._assetIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (playbackCheckpointsRefs)
                        await $_getPrefetchedData<
                          SavedPassage,
                          SavedPassages,
                          PlaybackCheckpoint
                        >(
                          currentTable: table,
                          referencedTable: $SavedPassagesReferences
                              ._playbackCheckpointsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $SavedPassagesReferences(
                                db,
                                table,
                                p0,
                              ).playbackCheckpointsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.passageId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (listeningSessionsRefs)
                        await $_getPrefetchedData<
                          SavedPassage,
                          SavedPassages,
                          ListeningSession
                        >(
                          currentTable: table,
                          referencedTable: $SavedPassagesReferences
                              ._listeningSessionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $SavedPassagesReferences(
                                db,
                                table,
                                p0,
                              ).listeningSessionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.passageId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $SavedPassagesProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      SavedPassages,
      SavedPassage,
      $SavedPassagesFilterComposer,
      $SavedPassagesOrderingComposer,
      $SavedPassagesAnnotationComposer,
      $SavedPassagesCreateCompanionBuilder,
      $SavedPassagesUpdateCompanionBuilder,
      (SavedPassage, $SavedPassagesReferences),
      SavedPassage,
      PrefetchHooks Function({
        bool assetId,
        bool playbackCheckpointsRefs,
        bool listeningSessionsRefs,
      })
    >;
typedef $FavoritesCreateCompanionBuilder = FavoritesCompanion Function({
  required String type,
  required String targetId,
  required int createdUtcMs,
  Value<int> rowid,
});
typedef $FavoritesUpdateCompanionBuilder = FavoritesCompanion Function({
  Value<String> type,
  Value<String> targetId,
  Value<int> createdUtcMs,
  Value<int> rowid,
});

class $FavoritesFilterComposer extends Composer<_$AppDatabase, Favorites> {
  $FavoritesFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get targetId => $composableBuilder(
    column: $table.targetId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdUtcMs => $composableBuilder(
    column: $table.createdUtcMs,
    builder: (column) => ColumnFilters(column),
  );
}

class $FavoritesOrderingComposer extends Composer<_$AppDatabase, Favorites> {
  $FavoritesOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get targetId => $composableBuilder(
    column: $table.targetId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdUtcMs => $composableBuilder(
    column: $table.createdUtcMs,
    builder: (column) => ColumnOrderings(column),
  );
}

class $FavoritesAnnotationComposer extends Composer<_$AppDatabase, Favorites> {
  $FavoritesAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get targetId =>
      $composableBuilder(column: $table.targetId, builder: (column) => column);

  GeneratedColumn<int> get createdUtcMs => $composableBuilder(
    column: $table.createdUtcMs,
    builder: (column) => column,
  );
}

class $FavoritesTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          Favorites,
          Favorite,
          $FavoritesFilterComposer,
          $FavoritesOrderingComposer,
          $FavoritesAnnotationComposer,
          $FavoritesCreateCompanionBuilder,
          $FavoritesUpdateCompanionBuilder,
          (Favorite, BaseReferences<_$AppDatabase, Favorites, Favorite>),
          Favorite,
          PrefetchHooks Function()
        > {
  $FavoritesTableManager(_$AppDatabase db, Favorites table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $FavoritesFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $FavoritesOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $FavoritesAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> type = const Value.absent(),
                Value<String> targetId = const Value.absent(),
                Value<int> createdUtcMs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FavoritesCompanion(
                type: type,
                targetId: targetId,
                createdUtcMs: createdUtcMs,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String type,
                required String targetId,
                required int createdUtcMs,
                Value<int> rowid = const Value.absent(),
              }) => FavoritesCompanion.insert(
                type: type,
                targetId: targetId,
                createdUtcMs: createdUtcMs,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<Favorites, Favorite>(table),
                  BaseReferences<_$AppDatabase, Favorites, Favorite>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $FavoritesProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      Favorites,
      Favorite,
      $FavoritesFilterComposer,
      $FavoritesOrderingComposer,
      $FavoritesAnnotationComposer,
      $FavoritesCreateCompanionBuilder,
      $FavoritesUpdateCompanionBuilder,
      (Favorite, BaseReferences<_$AppDatabase, Favorites, Favorite>),
      Favorite,
      PrefetchHooks Function()
    >;
typedef $DownloadsCreateCompanionBuilder = DownloadsCompanion Function({
  required String assetId,
  Value<String?> relativePath,
  Value<String?> nativeTaskId,
  required String state,
  required int receivedBytes,
  Value<String?> verifiedSha256,
  required int updatedUtcMs,
  Value<int> rowid,
});
typedef $DownloadsUpdateCompanionBuilder = DownloadsCompanion Function({
  Value<String> assetId,
  Value<String?> relativePath,
  Value<String?> nativeTaskId,
  Value<String> state,
  Value<int> receivedBytes,
  Value<String?> verifiedSha256,
  Value<int> updatedUtcMs,
  Value<int> rowid,
});

final class $DownloadsReferences
    extends BaseReferences<_$AppDatabase, Downloads, Download> {
  $DownloadsReferences(super.$_db, super.$_table, super.$_typedResult);

  static AudioAssets _assetIdTable(_$AppDatabase db) =>
      db.audioAssets.createAlias('downloads__asset_id__audio_assets__id');

  $AudioAssetsProcessedTableManager get assetId {
    final $_column = $_itemColumn<String>('asset_id')!;

    final manager = $AudioAssetsTableManager(
      $_db,
      $_db.audioAssets,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_assetIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $DownloadsFilterComposer extends Composer<_$AppDatabase, Downloads> {
  $DownloadsFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get relativePath => $composableBuilder(
    column: $table.relativePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nativeTaskId => $composableBuilder(
    column: $table.nativeTaskId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get receivedBytes => $composableBuilder(
    column: $table.receivedBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get verifiedSha256 => $composableBuilder(
    column: $table.verifiedSha256,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedUtcMs => $composableBuilder(
    column: $table.updatedUtcMs,
    builder: (column) => ColumnFilters(column),
  );

  $AudioAssetsFilterComposer get assetId {
    final $AudioAssetsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.assetId,
      referencedTable: $db.audioAssets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $AudioAssetsFilterComposer(
            $db: $db,
            $table: $db.audioAssets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $DownloadsOrderingComposer extends Composer<_$AppDatabase, Downloads> {
  $DownloadsOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get relativePath => $composableBuilder(
    column: $table.relativePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nativeTaskId => $composableBuilder(
    column: $table.nativeTaskId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get receivedBytes => $composableBuilder(
    column: $table.receivedBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get verifiedSha256 => $composableBuilder(
    column: $table.verifiedSha256,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedUtcMs => $composableBuilder(
    column: $table.updatedUtcMs,
    builder: (column) => ColumnOrderings(column),
  );

  $AudioAssetsOrderingComposer get assetId {
    final $AudioAssetsOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.assetId,
      referencedTable: $db.audioAssets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $AudioAssetsOrderingComposer(
            $db: $db,
            $table: $db.audioAssets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $DownloadsAnnotationComposer extends Composer<_$AppDatabase, Downloads> {
  $DownloadsAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get relativePath => $composableBuilder(
    column: $table.relativePath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get nativeTaskId => $composableBuilder(
    column: $table.nativeTaskId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<int> get receivedBytes => $composableBuilder(
    column: $table.receivedBytes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get verifiedSha256 => $composableBuilder(
    column: $table.verifiedSha256,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updatedUtcMs => $composableBuilder(
    column: $table.updatedUtcMs,
    builder: (column) => column,
  );

  $AudioAssetsAnnotationComposer get assetId {
    final $AudioAssetsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.assetId,
      referencedTable: $db.audioAssets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $AudioAssetsAnnotationComposer(
            $db: $db,
            $table: $db.audioAssets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $DownloadsTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          Downloads,
          Download,
          $DownloadsFilterComposer,
          $DownloadsOrderingComposer,
          $DownloadsAnnotationComposer,
          $DownloadsCreateCompanionBuilder,
          $DownloadsUpdateCompanionBuilder,
          (Download, $DownloadsReferences),
          Download,
          PrefetchHooks Function({bool assetId})
        > {
  $DownloadsTableManager(_$AppDatabase db, Downloads table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $DownloadsFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $DownloadsOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $DownloadsAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> assetId = const Value.absent(),
                Value<String?> relativePath = const Value.absent(),
                Value<String?> nativeTaskId = const Value.absent(),
                Value<String> state = const Value.absent(),
                Value<int> receivedBytes = const Value.absent(),
                Value<String?> verifiedSha256 = const Value.absent(),
                Value<int> updatedUtcMs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DownloadsCompanion(
                assetId: assetId,
                relativePath: relativePath,
                nativeTaskId: nativeTaskId,
                state: state,
                receivedBytes: receivedBytes,
                verifiedSha256: verifiedSha256,
                updatedUtcMs: updatedUtcMs,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String assetId,
                Value<String?> relativePath = const Value.absent(),
                Value<String?> nativeTaskId = const Value.absent(),
                required String state,
                required int receivedBytes,
                Value<String?> verifiedSha256 = const Value.absent(),
                required int updatedUtcMs,
                Value<int> rowid = const Value.absent(),
              }) => DownloadsCompanion.insert(
                assetId: assetId,
                relativePath: relativePath,
                nativeTaskId: nativeTaskId,
                state: state,
                receivedBytes: receivedBytes,
                verifiedSha256: verifiedSha256,
                updatedUtcMs: updatedUtcMs,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<Downloads, Download>(table),
                  $DownloadsReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({assetId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (assetId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.assetId,
                        referencedTable: $DownloadsReferences._assetIdTable(db),
                        referencedColumn: $DownloadsReferences
                            ._assetIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $DownloadsProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      Downloads,
      Download,
      $DownloadsFilterComposer,
      $DownloadsOrderingComposer,
      $DownloadsAnnotationComposer,
      $DownloadsCreateCompanionBuilder,
      $DownloadsUpdateCompanionBuilder,
      (Download, $DownloadsReferences),
      Download,
      PrefetchHooks Function({bool assetId})
    >;
typedef $PlaybackCheckpointsCreateCompanionBuilder =
    PlaybackCheckpointsCompanion Function({
      required String sessionId,
      required String scope,
      required String assetId,
      Value<String?> passageId,
      required int currentPass,
      Value<int?> remainingCount,
      required int sourcePositionMs,
      required String settingsSnapshot,
      required int updatedUtcMs,
      Value<int> rowid,
    });
typedef $PlaybackCheckpointsUpdateCompanionBuilder =
    PlaybackCheckpointsCompanion Function({
      Value<String> sessionId,
      Value<String> scope,
      Value<String> assetId,
      Value<String?> passageId,
      Value<int> currentPass,
      Value<int?> remainingCount,
      Value<int> sourcePositionMs,
      Value<String> settingsSnapshot,
      Value<int> updatedUtcMs,
      Value<int> rowid,
    });

final class $PlaybackCheckpointsReferences
    extends
        BaseReferences<_$AppDatabase, PlaybackCheckpoints, PlaybackCheckpoint> {
  $PlaybackCheckpointsReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static AudioAssets _assetIdTable(_$AppDatabase db) => db.audioAssets
      .createAlias('playback_checkpoints__asset_id__audio_assets__id');

  $AudioAssetsProcessedTableManager get assetId {
    final $_column = $_itemColumn<String>('asset_id')!;

    final manager = $AudioAssetsTableManager(
      $_db,
      $_db.audioAssets,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_assetIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static SavedPassages _passageIdTable(_$AppDatabase db) => db.savedPassages
      .createAlias('playback_checkpoints__passage_id__saved_passages__id');

  $SavedPassagesProcessedTableManager? get passageId {
    final $_column = $_itemColumn<String>('passage_id');
    if ($_column == null) return null;
    final manager = $SavedPassagesTableManager(
      $_db,
      $_db.savedPassages,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_passageIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $PlaybackCheckpointsFilterComposer
    extends Composer<_$AppDatabase, PlaybackCheckpoints> {
  $PlaybackCheckpointsFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get scope => $composableBuilder(
    column: $table.scope,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get currentPass => $composableBuilder(
    column: $table.currentPass,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get remainingCount => $composableBuilder(
    column: $table.remainingCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sourcePositionMs => $composableBuilder(
    column: $table.sourcePositionMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get settingsSnapshot => $composableBuilder(
    column: $table.settingsSnapshot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedUtcMs => $composableBuilder(
    column: $table.updatedUtcMs,
    builder: (column) => ColumnFilters(column),
  );

  $AudioAssetsFilterComposer get assetId {
    final $AudioAssetsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.assetId,
      referencedTable: $db.audioAssets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $AudioAssetsFilterComposer(
            $db: $db,
            $table: $db.audioAssets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $SavedPassagesFilterComposer get passageId {
    final $SavedPassagesFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.passageId,
      referencedTable: $db.savedPassages,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $SavedPassagesFilterComposer(
            $db: $db,
            $table: $db.savedPassages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $PlaybackCheckpointsOrderingComposer
    extends Composer<_$AppDatabase, PlaybackCheckpoints> {
  $PlaybackCheckpointsOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get scope => $composableBuilder(
    column: $table.scope,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get currentPass => $composableBuilder(
    column: $table.currentPass,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get remainingCount => $composableBuilder(
    column: $table.remainingCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sourcePositionMs => $composableBuilder(
    column: $table.sourcePositionMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get settingsSnapshot => $composableBuilder(
    column: $table.settingsSnapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedUtcMs => $composableBuilder(
    column: $table.updatedUtcMs,
    builder: (column) => ColumnOrderings(column),
  );

  $AudioAssetsOrderingComposer get assetId {
    final $AudioAssetsOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.assetId,
      referencedTable: $db.audioAssets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $AudioAssetsOrderingComposer(
            $db: $db,
            $table: $db.audioAssets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $SavedPassagesOrderingComposer get passageId {
    final $SavedPassagesOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.passageId,
      referencedTable: $db.savedPassages,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $SavedPassagesOrderingComposer(
            $db: $db,
            $table: $db.savedPassages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $PlaybackCheckpointsAnnotationComposer
    extends Composer<_$AppDatabase, PlaybackCheckpoints> {
  $PlaybackCheckpointsAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => column);

  GeneratedColumn<String> get scope =>
      $composableBuilder(column: $table.scope, builder: (column) => column);

  GeneratedColumn<int> get currentPass => $composableBuilder(
    column: $table.currentPass,
    builder: (column) => column,
  );

  GeneratedColumn<int> get remainingCount => $composableBuilder(
    column: $table.remainingCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sourcePositionMs => $composableBuilder(
    column: $table.sourcePositionMs,
    builder: (column) => column,
  );

  GeneratedColumn<String> get settingsSnapshot => $composableBuilder(
    column: $table.settingsSnapshot,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updatedUtcMs => $composableBuilder(
    column: $table.updatedUtcMs,
    builder: (column) => column,
  );

  $AudioAssetsAnnotationComposer get assetId {
    final $AudioAssetsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.assetId,
      referencedTable: $db.audioAssets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $AudioAssetsAnnotationComposer(
            $db: $db,
            $table: $db.audioAssets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $SavedPassagesAnnotationComposer get passageId {
    final $SavedPassagesAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.passageId,
      referencedTable: $db.savedPassages,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $SavedPassagesAnnotationComposer(
            $db: $db,
            $table: $db.savedPassages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $PlaybackCheckpointsTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          PlaybackCheckpoints,
          PlaybackCheckpoint,
          $PlaybackCheckpointsFilterComposer,
          $PlaybackCheckpointsOrderingComposer,
          $PlaybackCheckpointsAnnotationComposer,
          $PlaybackCheckpointsCreateCompanionBuilder,
          $PlaybackCheckpointsUpdateCompanionBuilder,
          (PlaybackCheckpoint, $PlaybackCheckpointsReferences),
          PlaybackCheckpoint,
          PrefetchHooks Function({bool assetId, bool passageId})
        > {
  $PlaybackCheckpointsTableManager(_$AppDatabase db, PlaybackCheckpoints table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $PlaybackCheckpointsFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $PlaybackCheckpointsOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $PlaybackCheckpointsAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> sessionId = const Value.absent(),
                Value<String> scope = const Value.absent(),
                Value<String> assetId = const Value.absent(),
                Value<String?> passageId = const Value.absent(),
                Value<int> currentPass = const Value.absent(),
                Value<int?> remainingCount = const Value.absent(),
                Value<int> sourcePositionMs = const Value.absent(),
                Value<String> settingsSnapshot = const Value.absent(),
                Value<int> updatedUtcMs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlaybackCheckpointsCompanion(
                sessionId: sessionId,
                scope: scope,
                assetId: assetId,
                passageId: passageId,
                currentPass: currentPass,
                remainingCount: remainingCount,
                sourcePositionMs: sourcePositionMs,
                settingsSnapshot: settingsSnapshot,
                updatedUtcMs: updatedUtcMs,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String sessionId,
                required String scope,
                required String assetId,
                Value<String?> passageId = const Value.absent(),
                required int currentPass,
                Value<int?> remainingCount = const Value.absent(),
                required int sourcePositionMs,
                required String settingsSnapshot,
                required int updatedUtcMs,
                Value<int> rowid = const Value.absent(),
              }) => PlaybackCheckpointsCompanion.insert(
                sessionId: sessionId,
                scope: scope,
                assetId: assetId,
                passageId: passageId,
                currentPass: currentPass,
                remainingCount: remainingCount,
                sourcePositionMs: sourcePositionMs,
                settingsSnapshot: settingsSnapshot,
                updatedUtcMs: updatedUtcMs,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<PlaybackCheckpoints, PlaybackCheckpoint>(table),
                  $PlaybackCheckpointsReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({assetId = false, passageId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (assetId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.assetId,
                        referencedTable: $PlaybackCheckpointsReferences
                            ._assetIdTable(db),
                        referencedColumn: $PlaybackCheckpointsReferences
                            ._assetIdTable(db)
                            .id,
                      ) as T;
                    }
                    if (passageId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.passageId,
                        referencedTable: $PlaybackCheckpointsReferences
                            ._passageIdTable(db),
                        referencedColumn: $PlaybackCheckpointsReferences
                            ._passageIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $PlaybackCheckpointsProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      PlaybackCheckpoints,
      PlaybackCheckpoint,
      $PlaybackCheckpointsFilterComposer,
      $PlaybackCheckpointsOrderingComposer,
      $PlaybackCheckpointsAnnotationComposer,
      $PlaybackCheckpointsCreateCompanionBuilder,
      $PlaybackCheckpointsUpdateCompanionBuilder,
      (PlaybackCheckpoint, $PlaybackCheckpointsReferences),
      PlaybackCheckpoint,
      PrefetchHooks Function({bool assetId, bool passageId})
    >;
typedef $ListeningSessionsCreateCompanionBuilder =
    ListeningSessionsCompanion Function({
      required String id,
      required String assetId,
      Value<String?> passageId,
      required int startedUtcMs,
      Value<int?> endedUtcMs,
      Value<int> playedWallMs,
      required double speed,
      Value<String?> completionReason,
      Value<int> rowid,
    });
typedef $ListeningSessionsUpdateCompanionBuilder =
    ListeningSessionsCompanion Function({
      Value<String> id,
      Value<String> assetId,
      Value<String?> passageId,
      Value<int> startedUtcMs,
      Value<int?> endedUtcMs,
      Value<int> playedWallMs,
      Value<double> speed,
      Value<String?> completionReason,
      Value<int> rowid,
    });

final class $ListeningSessionsReferences
    extends BaseReferences<_$AppDatabase, ListeningSessions, ListeningSession> {
  $ListeningSessionsReferences(super.$_db, super.$_table, super.$_typedResult);

  static AudioAssets _assetIdTable(_$AppDatabase db) => db.audioAssets
      .createAlias('listening_sessions__asset_id__audio_assets__id');

  $AudioAssetsProcessedTableManager get assetId {
    final $_column = $_itemColumn<String>('asset_id')!;

    final manager = $AudioAssetsTableManager(
      $_db,
      $_db.audioAssets,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_assetIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static SavedPassages _passageIdTable(_$AppDatabase db) => db.savedPassages
      .createAlias('listening_sessions__passage_id__saved_passages__id');

  $SavedPassagesProcessedTableManager? get passageId {
    final $_column = $_itemColumn<String>('passage_id');
    if ($_column == null) return null;
    final manager = $SavedPassagesTableManager(
      $_db,
      $_db.savedPassages,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_passageIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<ActivityEvents, List<ActivityEvent>>
  _activityEventsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.activityEvents,
    aliasName: 'listening_sessions__id__activity_events__session_id',
  );

  $ActivityEventsProcessedTableManager get activityEventsRefs {
    final manager = $ActivityEventsTableManager(
      $_db,
      $_db.activityEvents,
    ).filter((f) => f.sessionId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_activityEventsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $ListeningSessionsFilterComposer
    extends Composer<_$AppDatabase, ListeningSessions> {
  $ListeningSessionsFilterComposer({
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

  ColumnFilters<int> get startedUtcMs => $composableBuilder(
    column: $table.startedUtcMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endedUtcMs => $composableBuilder(
    column: $table.endedUtcMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get playedWallMs => $composableBuilder(
    column: $table.playedWallMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get speed => $composableBuilder(
    column: $table.speed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get completionReason => $composableBuilder(
    column: $table.completionReason,
    builder: (column) => ColumnFilters(column),
  );

  $AudioAssetsFilterComposer get assetId {
    final $AudioAssetsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.assetId,
      referencedTable: $db.audioAssets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $AudioAssetsFilterComposer(
            $db: $db,
            $table: $db.audioAssets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $SavedPassagesFilterComposer get passageId {
    final $SavedPassagesFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.passageId,
      referencedTable: $db.savedPassages,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $SavedPassagesFilterComposer(
            $db: $db,
            $table: $db.savedPassages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> activityEventsRefs(
    Expression<bool> Function($ActivityEventsFilterComposer f) f,
  ) {
    final $ActivityEventsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.activityEvents,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ActivityEventsFilterComposer(
            $db: $db,
            $table: $db.activityEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $ListeningSessionsOrderingComposer
    extends Composer<_$AppDatabase, ListeningSessions> {
  $ListeningSessionsOrderingComposer({
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

  ColumnOrderings<int> get startedUtcMs => $composableBuilder(
    column: $table.startedUtcMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endedUtcMs => $composableBuilder(
    column: $table.endedUtcMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get playedWallMs => $composableBuilder(
    column: $table.playedWallMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get speed => $composableBuilder(
    column: $table.speed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get completionReason => $composableBuilder(
    column: $table.completionReason,
    builder: (column) => ColumnOrderings(column),
  );

  $AudioAssetsOrderingComposer get assetId {
    final $AudioAssetsOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.assetId,
      referencedTable: $db.audioAssets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $AudioAssetsOrderingComposer(
            $db: $db,
            $table: $db.audioAssets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $SavedPassagesOrderingComposer get passageId {
    final $SavedPassagesOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.passageId,
      referencedTable: $db.savedPassages,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $SavedPassagesOrderingComposer(
            $db: $db,
            $table: $db.savedPassages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $ListeningSessionsAnnotationComposer
    extends Composer<_$AppDatabase, ListeningSessions> {
  $ListeningSessionsAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get startedUtcMs => $composableBuilder(
    column: $table.startedUtcMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get endedUtcMs => $composableBuilder(
    column: $table.endedUtcMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get playedWallMs => $composableBuilder(
    column: $table.playedWallMs,
    builder: (column) => column,
  );

  GeneratedColumn<double> get speed =>
      $composableBuilder(column: $table.speed, builder: (column) => column);

  GeneratedColumn<String> get completionReason => $composableBuilder(
    column: $table.completionReason,
    builder: (column) => column,
  );

  $AudioAssetsAnnotationComposer get assetId {
    final $AudioAssetsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.assetId,
      referencedTable: $db.audioAssets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $AudioAssetsAnnotationComposer(
            $db: $db,
            $table: $db.audioAssets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $SavedPassagesAnnotationComposer get passageId {
    final $SavedPassagesAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.passageId,
      referencedTable: $db.savedPassages,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $SavedPassagesAnnotationComposer(
            $db: $db,
            $table: $db.savedPassages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> activityEventsRefs<T extends Object>(
    Expression<T> Function($ActivityEventsAnnotationComposer a) f,
  ) {
    final $ActivityEventsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.activityEvents,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ActivityEventsAnnotationComposer(
            $db: $db,
            $table: $db.activityEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $ListeningSessionsTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          ListeningSessions,
          ListeningSession,
          $ListeningSessionsFilterComposer,
          $ListeningSessionsOrderingComposer,
          $ListeningSessionsAnnotationComposer,
          $ListeningSessionsCreateCompanionBuilder,
          $ListeningSessionsUpdateCompanionBuilder,
          (ListeningSession, $ListeningSessionsReferences),
          ListeningSession,
          PrefetchHooks Function({
            bool assetId,
            bool passageId,
            bool activityEventsRefs,
          })
        > {
  $ListeningSessionsTableManager(_$AppDatabase db, ListeningSessions table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $ListeningSessionsFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $ListeningSessionsOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $ListeningSessionsAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> assetId = const Value.absent(),
                Value<String?> passageId = const Value.absent(),
                Value<int> startedUtcMs = const Value.absent(),
                Value<int?> endedUtcMs = const Value.absent(),
                Value<int> playedWallMs = const Value.absent(),
                Value<double> speed = const Value.absent(),
                Value<String?> completionReason = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ListeningSessionsCompanion(
                id: id,
                assetId: assetId,
                passageId: passageId,
                startedUtcMs: startedUtcMs,
                endedUtcMs: endedUtcMs,
                playedWallMs: playedWallMs,
                speed: speed,
                completionReason: completionReason,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String assetId,
                Value<String?> passageId = const Value.absent(),
                required int startedUtcMs,
                Value<int?> endedUtcMs = const Value.absent(),
                Value<int> playedWallMs = const Value.absent(),
                required double speed,
                Value<String?> completionReason = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ListeningSessionsCompanion.insert(
                id: id,
                assetId: assetId,
                passageId: passageId,
                startedUtcMs: startedUtcMs,
                endedUtcMs: endedUtcMs,
                playedWallMs: playedWallMs,
                speed: speed,
                completionReason: completionReason,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<ListeningSessions, ListeningSession>(table),
                  $ListeningSessionsReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                assetId = false,
                passageId = false,
                activityEventsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (activityEventsRefs) db.activityEvents,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (assetId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.assetId,
                            referencedTable: $ListeningSessionsReferences
                                ._assetIdTable(db),
                            referencedColumn: $ListeningSessionsReferences
                                ._assetIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (passageId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.passageId,
                            referencedTable: $ListeningSessionsReferences
                                ._passageIdTable(db),
                            referencedColumn: $ListeningSessionsReferences
                                ._passageIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (activityEventsRefs)
                        await $_getPrefetchedData<
                          ListeningSession,
                          ListeningSessions,
                          ActivityEvent
                        >(
                          currentTable: table,
                          referencedTable: $ListeningSessionsReferences
                              ._activityEventsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $ListeningSessionsReferences(
                                db,
                                table,
                                p0,
                              ).activityEventsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.sessionId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $ListeningSessionsProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      ListeningSessions,
      ListeningSession,
      $ListeningSessionsFilterComposer,
      $ListeningSessionsOrderingComposer,
      $ListeningSessionsAnnotationComposer,
      $ListeningSessionsCreateCompanionBuilder,
      $ListeningSessionsUpdateCompanionBuilder,
      (ListeningSession, $ListeningSessionsReferences),
      ListeningSession,
      PrefetchHooks Function({
        bool assetId,
        bool passageId,
        bool activityEventsRefs,
      })
    >;
typedef $DailyActivityCreateCompanionBuilder = DailyActivityCompanion Function({
  required String localDate,
  required String timezonePolicy,
  Value<int> playedWallMs,
  required int goalMs,
  required int qualified,
  Value<int> rowid,
});
typedef $DailyActivityUpdateCompanionBuilder = DailyActivityCompanion Function({
  Value<String> localDate,
  Value<String> timezonePolicy,
  Value<int> playedWallMs,
  Value<int> goalMs,
  Value<int> qualified,
  Value<int> rowid,
});

final class $DailyActivityReferences
    extends BaseReferences<_$AppDatabase, DailyActivity, DailyActivityData> {
  $DailyActivityReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<ActivityEvents, List<ActivityEvent>>
  _activityEventsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.activityEvents,
    aliasName: 'daily_activity__local_date__activity_events__local_date',
  );

  $ActivityEventsProcessedTableManager get activityEventsRefs {
    final manager = $ActivityEventsTableManager($_db, $_db.activityEvents)
        .filter(
          (f) => f.localDate.localDate.sqlEquals(
            $_itemColumn<String>('local_date')!,
          ),
        );

    final cache = $_typedResult.readTableOrNull(_activityEventsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $DailyActivityFilterComposer
    extends Composer<_$AppDatabase, DailyActivity> {
  $DailyActivityFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get localDate => $composableBuilder(
    column: $table.localDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get timezonePolicy => $composableBuilder(
    column: $table.timezonePolicy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get playedWallMs => $composableBuilder(
    column: $table.playedWallMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get goalMs => $composableBuilder(
    column: $table.goalMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get qualified => $composableBuilder(
    column: $table.qualified,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> activityEventsRefs(
    Expression<bool> Function($ActivityEventsFilterComposer f) f,
  ) {
    final $ActivityEventsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.localDate,
      referencedTable: $db.activityEvents,
      getReferencedColumn: (t) => t.localDate,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ActivityEventsFilterComposer(
            $db: $db,
            $table: $db.activityEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $DailyActivityOrderingComposer
    extends Composer<_$AppDatabase, DailyActivity> {
  $DailyActivityOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get localDate => $composableBuilder(
    column: $table.localDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get timezonePolicy => $composableBuilder(
    column: $table.timezonePolicy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get playedWallMs => $composableBuilder(
    column: $table.playedWallMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get goalMs => $composableBuilder(
    column: $table.goalMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get qualified => $composableBuilder(
    column: $table.qualified,
    builder: (column) => ColumnOrderings(column),
  );
}

class $DailyActivityAnnotationComposer
    extends Composer<_$AppDatabase, DailyActivity> {
  $DailyActivityAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get localDate =>
      $composableBuilder(column: $table.localDate, builder: (column) => column);

  GeneratedColumn<String> get timezonePolicy => $composableBuilder(
    column: $table.timezonePolicy,
    builder: (column) => column,
  );

  GeneratedColumn<int> get playedWallMs => $composableBuilder(
    column: $table.playedWallMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get goalMs =>
      $composableBuilder(column: $table.goalMs, builder: (column) => column);

  GeneratedColumn<int> get qualified =>
      $composableBuilder(column: $table.qualified, builder: (column) => column);

  Expression<T> activityEventsRefs<T extends Object>(
    Expression<T> Function($ActivityEventsAnnotationComposer a) f,
  ) {
    final $ActivityEventsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.localDate,
      referencedTable: $db.activityEvents,
      getReferencedColumn: (t) => t.localDate,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ActivityEventsAnnotationComposer(
            $db: $db,
            $table: $db.activityEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $DailyActivityTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          DailyActivity,
          DailyActivityData,
          $DailyActivityFilterComposer,
          $DailyActivityOrderingComposer,
          $DailyActivityAnnotationComposer,
          $DailyActivityCreateCompanionBuilder,
          $DailyActivityUpdateCompanionBuilder,
          (DailyActivityData, $DailyActivityReferences),
          DailyActivityData,
          PrefetchHooks Function({bool activityEventsRefs})
        > {
  $DailyActivityTableManager(_$AppDatabase db, DailyActivity table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $DailyActivityFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $DailyActivityOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $DailyActivityAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> localDate = const Value.absent(),
                Value<String> timezonePolicy = const Value.absent(),
                Value<int> playedWallMs = const Value.absent(),
                Value<int> goalMs = const Value.absent(),
                Value<int> qualified = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DailyActivityCompanion(
                localDate: localDate,
                timezonePolicy: timezonePolicy,
                playedWallMs: playedWallMs,
                goalMs: goalMs,
                qualified: qualified,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String localDate,
                required String timezonePolicy,
                Value<int> playedWallMs = const Value.absent(),
                required int goalMs,
                required int qualified,
                Value<int> rowid = const Value.absent(),
              }) => DailyActivityCompanion.insert(
                localDate: localDate,
                timezonePolicy: timezonePolicy,
                playedWallMs: playedWallMs,
                goalMs: goalMs,
                qualified: qualified,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<DailyActivity, DailyActivityData>(table),
                  $DailyActivityReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({activityEventsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (activityEventsRefs) db.activityEvents,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (activityEventsRefs)
                    await $_getPrefetchedData<
                      DailyActivityData,
                      DailyActivity,
                      ActivityEvent
                    >(
                      currentTable: table,
                      referencedTable: $DailyActivityReferences
                          ._activityEventsRefsTable(db),
                      managerFromTypedResult: (p0) => $DailyActivityReferences(
                        db,
                        table,
                        p0,
                      ).activityEventsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.localDate == item.localDate,
                          ),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $DailyActivityProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      DailyActivity,
      DailyActivityData,
      $DailyActivityFilterComposer,
      $DailyActivityOrderingComposer,
      $DailyActivityAnnotationComposer,
      $DailyActivityCreateCompanionBuilder,
      $DailyActivityUpdateCompanionBuilder,
      (DailyActivityData, $DailyActivityReferences),
      DailyActivityData,
      PrefetchHooks Function({bool activityEventsRefs})
    >;
typedef $ActivityEventsCreateCompanionBuilder =
    ActivityEventsCompanion Function({
      required String id,
      required String sessionId,
      required String localDate,
      required int playedWallMs,
      required int utcMs,
      Value<int> rowid,
    });
typedef $ActivityEventsUpdateCompanionBuilder =
    ActivityEventsCompanion Function({
      Value<String> id,
      Value<String> sessionId,
      Value<String> localDate,
      Value<int> playedWallMs,
      Value<int> utcMs,
      Value<int> rowid,
    });

final class $ActivityEventsReferences
    extends BaseReferences<_$AppDatabase, ActivityEvents, ActivityEvent> {
  $ActivityEventsReferences(super.$_db, super.$_table, super.$_typedResult);

  static ListeningSessions _sessionIdTable(_$AppDatabase db) => db
      .listeningSessions
      .createAlias('activity_events__session_id__listening_sessions__id');

  $ListeningSessionsProcessedTableManager get sessionId {
    final $_column = $_itemColumn<String>('session_id')!;

    final manager = $ListeningSessionsTableManager(
      $_db,
      $_db.listeningSessions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sessionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static DailyActivity _localDateTable(_$AppDatabase db) => db.dailyActivity
      .createAlias('activity_events__local_date__daily_activity__local_date');

  $DailyActivityProcessedTableManager get localDate {
    final $_column = $_itemColumn<String>('local_date')!;

    final manager = $DailyActivityTableManager(
      $_db,
      $_db.dailyActivity,
    ).filter((f) => f.localDate.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_localDateTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $ActivityEventsFilterComposer
    extends Composer<_$AppDatabase, ActivityEvents> {
  $ActivityEventsFilterComposer({
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

  ColumnFilters<int> get playedWallMs => $composableBuilder(
    column: $table.playedWallMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get utcMs => $composableBuilder(
    column: $table.utcMs,
    builder: (column) => ColumnFilters(column),
  );

  $ListeningSessionsFilterComposer get sessionId {
    final $ListeningSessionsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.listeningSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ListeningSessionsFilterComposer(
            $db: $db,
            $table: $db.listeningSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $DailyActivityFilterComposer get localDate {
    final $DailyActivityFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.localDate,
      referencedTable: $db.dailyActivity,
      getReferencedColumn: (t) => t.localDate,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $DailyActivityFilterComposer(
            $db: $db,
            $table: $db.dailyActivity,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $ActivityEventsOrderingComposer
    extends Composer<_$AppDatabase, ActivityEvents> {
  $ActivityEventsOrderingComposer({
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

  ColumnOrderings<int> get playedWallMs => $composableBuilder(
    column: $table.playedWallMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get utcMs => $composableBuilder(
    column: $table.utcMs,
    builder: (column) => ColumnOrderings(column),
  );

  $ListeningSessionsOrderingComposer get sessionId {
    final $ListeningSessionsOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.listeningSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ListeningSessionsOrderingComposer(
            $db: $db,
            $table: $db.listeningSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $DailyActivityOrderingComposer get localDate {
    final $DailyActivityOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.localDate,
      referencedTable: $db.dailyActivity,
      getReferencedColumn: (t) => t.localDate,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $DailyActivityOrderingComposer(
            $db: $db,
            $table: $db.dailyActivity,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $ActivityEventsAnnotationComposer
    extends Composer<_$AppDatabase, ActivityEvents> {
  $ActivityEventsAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get playedWallMs => $composableBuilder(
    column: $table.playedWallMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get utcMs =>
      $composableBuilder(column: $table.utcMs, builder: (column) => column);

  $ListeningSessionsAnnotationComposer get sessionId {
    final $ListeningSessionsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.listeningSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ListeningSessionsAnnotationComposer(
            $db: $db,
            $table: $db.listeningSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $DailyActivityAnnotationComposer get localDate {
    final $DailyActivityAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.localDate,
      referencedTable: $db.dailyActivity,
      getReferencedColumn: (t) => t.localDate,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $DailyActivityAnnotationComposer(
            $db: $db,
            $table: $db.dailyActivity,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $ActivityEventsTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          ActivityEvents,
          ActivityEvent,
          $ActivityEventsFilterComposer,
          $ActivityEventsOrderingComposer,
          $ActivityEventsAnnotationComposer,
          $ActivityEventsCreateCompanionBuilder,
          $ActivityEventsUpdateCompanionBuilder,
          (ActivityEvent, $ActivityEventsReferences),
          ActivityEvent,
          PrefetchHooks Function({bool sessionId, bool localDate})
        > {
  $ActivityEventsTableManager(_$AppDatabase db, ActivityEvents table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $ActivityEventsFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $ActivityEventsOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $ActivityEventsAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> sessionId = const Value.absent(),
                Value<String> localDate = const Value.absent(),
                Value<int> playedWallMs = const Value.absent(),
                Value<int> utcMs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ActivityEventsCompanion(
                id: id,
                sessionId: sessionId,
                localDate: localDate,
                playedWallMs: playedWallMs,
                utcMs: utcMs,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String sessionId,
                required String localDate,
                required int playedWallMs,
                required int utcMs,
                Value<int> rowid = const Value.absent(),
              }) => ActivityEventsCompanion.insert(
                id: id,
                sessionId: sessionId,
                localDate: localDate,
                playedWallMs: playedWallMs,
                utcMs: utcMs,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<ActivityEvents, ActivityEvent>(table),
                  $ActivityEventsReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({sessionId = false, localDate = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (sessionId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.sessionId,
                        referencedTable: $ActivityEventsReferences
                            ._sessionIdTable(db),
                        referencedColumn: $ActivityEventsReferences
                            ._sessionIdTable(db)
                            .id,
                      ) as T;
                    }
                    if (localDate) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.localDate,
                        referencedTable: $ActivityEventsReferences
                            ._localDateTable(db),
                        referencedColumn: $ActivityEventsReferences
                            ._localDateTable(db)
                            .localDate,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $ActivityEventsProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      ActivityEvents,
      ActivityEvent,
      $ActivityEventsFilterComposer,
      $ActivityEventsOrderingComposer,
      $ActivityEventsAnnotationComposer,
      $ActivityEventsCreateCompanionBuilder,
      $ActivityEventsUpdateCompanionBuilder,
      (ActivityEvent, $ActivityEventsReferences),
      ActivityEvent,
      PrefetchHooks Function({bool sessionId, bool localDate})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $RecitersTableManager get reciters =>
      $RecitersTableManager(_db, _db.reciters);
  $AppSettingsTableManager get appSettings =>
      $AppSettingsTableManager(_db, _db.appSettings);
  $SurahsTableManager get surahs => $SurahsTableManager(_db, _db.surahs);
  $RecordingEditionsTableManager get recordingEditions =>
      $RecordingEditionsTableManager(_db, _db.recordingEditions);
  $AudioAssetsTableManager get audioAssets =>
      $AudioAssetsTableManager(_db, _db.audioAssets);
  $SavedPassagesTableManager get savedPassages =>
      $SavedPassagesTableManager(_db, _db.savedPassages);
  $FavoritesTableManager get favorites =>
      $FavoritesTableManager(_db, _db.favorites);
  $DownloadsTableManager get downloads =>
      $DownloadsTableManager(_db, _db.downloads);
  $PlaybackCheckpointsTableManager get playbackCheckpoints =>
      $PlaybackCheckpointsTableManager(_db, _db.playbackCheckpoints);
  $ListeningSessionsTableManager get listeningSessions =>
      $ListeningSessionsTableManager(_db, _db.listeningSessions);
  $DailyActivityTableManager get dailyActivity =>
      $DailyActivityTableManager(_db, _db.dailyActivity);
  $ActivityEventsTableManager get activityEvents =>
      $ActivityEventsTableManager(_db, _db.activityEvents);
}
