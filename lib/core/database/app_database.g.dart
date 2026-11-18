// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $BooksTable extends Books with TableInfo<$BooksTable, Book> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BooksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pageCountMeta = const VerificationMeta(
    'pageCount',
  );
  @override
  late final GeneratedColumn<int> pageCount = GeneratedColumn<int>(
    'page_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _importedAtMeta = const VerificationMeta(
    'importedAt',
  );
  @override
  late final GeneratedColumn<DateTime> importedAt = GeneratedColumn<DateTime>(
    'imported_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<ReflowStatus, String>
  reflowStatus = GeneratedColumn<String>(
    'reflow_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: Constant(ReflowStatus.pending.name),
  ).withConverter<ReflowStatus>($BooksTable.$converterreflowStatus);
  static const VerificationMeta _reflowProgressMeta = const VerificationMeta(
    'reflowProgress',
  );
  @override
  late final GeneratedColumn<double> reflowProgress = GeneratedColumn<double>(
    'reflow_progress',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    pageCount,
    importedAt,
    reflowStatus,
    reflowProgress,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'books';
  @override
  VerificationContext validateIntegrity(
    Insertable<Book> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('page_count')) {
      context.handle(
        _pageCountMeta,
        pageCount.isAcceptableOrUnknown(data['page_count']!, _pageCountMeta),
      );
    } else if (isInserting) {
      context.missing(_pageCountMeta);
    }
    if (data.containsKey('imported_at')) {
      context.handle(
        _importedAtMeta,
        importedAt.isAcceptableOrUnknown(data['imported_at']!, _importedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_importedAtMeta);
    }
    if (data.containsKey('reflow_progress')) {
      context.handle(
        _reflowProgressMeta,
        reflowProgress.isAcceptableOrUnknown(
          data['reflow_progress']!,
          _reflowProgressMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Book map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Book(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      pageCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}page_count'],
      )!,
      importedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}imported_at'],
      )!,
      reflowStatus: $BooksTable.$converterreflowStatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}reflow_status'],
        )!,
      ),
      reflowProgress: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}reflow_progress'],
      )!,
    );
  }

  @override
  $BooksTable createAlias(String alias) {
    return $BooksTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<ReflowStatus, String, String>
  $converterreflowStatus = const EnumNameConverter<ReflowStatus>(
    ReflowStatus.values,
  );
}

class Book extends DataClass implements Insertable<Book> {
  final String id;
  final String title;
  final int pageCount;
  final DateTime importedAt;
  final ReflowStatus reflowStatus;
  final double reflowProgress;
  const Book({
    required this.id,
    required this.title,
    required this.pageCount,
    required this.importedAt,
    required this.reflowStatus,
    required this.reflowProgress,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['page_count'] = Variable<int>(pageCount);
    map['imported_at'] = Variable<DateTime>(importedAt);
    {
      map['reflow_status'] = Variable<String>(
        $BooksTable.$converterreflowStatus.toSql(reflowStatus),
      );
    }
    map['reflow_progress'] = Variable<double>(reflowProgress);
    return map;
  }

  BooksCompanion toCompanion(bool nullToAbsent) {
    return BooksCompanion(
      id: Value(id),
      title: Value(title),
      pageCount: Value(pageCount),
      importedAt: Value(importedAt),
      reflowStatus: Value(reflowStatus),
      reflowProgress: Value(reflowProgress),
    );
  }

  factory Book.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Book(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      pageCount: serializer.fromJson<int>(json['pageCount']),
      importedAt: serializer.fromJson<DateTime>(json['importedAt']),
      reflowStatus: $BooksTable.$converterreflowStatus.fromJson(
        serializer.fromJson<String>(json['reflowStatus']),
      ),
      reflowProgress: serializer.fromJson<double>(json['reflowProgress']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'pageCount': serializer.toJson<int>(pageCount),
      'importedAt': serializer.toJson<DateTime>(importedAt),
      'reflowStatus': serializer.toJson<String>(
        $BooksTable.$converterreflowStatus.toJson(reflowStatus),
      ),
      'reflowProgress': serializer.toJson<double>(reflowProgress),
    };
  }

  Book copyWith({
    String? id,
    String? title,
    int? pageCount,
    DateTime? importedAt,
    ReflowStatus? reflowStatus,
    double? reflowProgress,
  }) => Book(
    id: id ?? this.id,
    title: title ?? this.title,
    pageCount: pageCount ?? this.pageCount,
    importedAt: importedAt ?? this.importedAt,
    reflowStatus: reflowStatus ?? this.reflowStatus,
    reflowProgress: reflowProgress ?? this.reflowProgress,
  );
  Book copyWithCompanion(BooksCompanion data) {
    return Book(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      pageCount: data.pageCount.present ? data.pageCount.value : this.pageCount,
      importedAt: data.importedAt.present
          ? data.importedAt.value
          : this.importedAt,
      reflowStatus: data.reflowStatus.present
          ? data.reflowStatus.value
          : this.reflowStatus,
      reflowProgress: data.reflowProgress.present
          ? data.reflowProgress.value
          : this.reflowProgress,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Book(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('pageCount: $pageCount, ')
          ..write('importedAt: $importedAt, ')
          ..write('reflowStatus: $reflowStatus, ')
          ..write('reflowProgress: $reflowProgress')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    pageCount,
    importedAt,
    reflowStatus,
    reflowProgress,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Book &&
          other.id == this.id &&
          other.title == this.title &&
          other.pageCount == this.pageCount &&
          other.importedAt == this.importedAt &&
          other.reflowStatus == this.reflowStatus &&
          other.reflowProgress == this.reflowProgress);
}

class BooksCompanion extends UpdateCompanion<Book> {
  final Value<String> id;
  final Value<String> title;
  final Value<int> pageCount;
  final Value<DateTime> importedAt;
  final Value<ReflowStatus> reflowStatus;
  final Value<double> reflowProgress;
  final Value<int> rowid;
  const BooksCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.pageCount = const Value.absent(),
    this.importedAt = const Value.absent(),
    this.reflowStatus = const Value.absent(),
    this.reflowProgress = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BooksCompanion.insert({
    required String id,
    required String title,
    required int pageCount,
    required DateTime importedAt,
    this.reflowStatus = const Value.absent(),
    this.reflowProgress = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       pageCount = Value(pageCount),
       importedAt = Value(importedAt);
  static Insertable<Book> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<int>? pageCount,
    Expression<DateTime>? importedAt,
    Expression<String>? reflowStatus,
    Expression<double>? reflowProgress,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (pageCount != null) 'page_count': pageCount,
      if (importedAt != null) 'imported_at': importedAt,
      if (reflowStatus != null) 'reflow_status': reflowStatus,
      if (reflowProgress != null) 'reflow_progress': reflowProgress,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BooksCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<int>? pageCount,
    Value<DateTime>? importedAt,
    Value<ReflowStatus>? reflowStatus,
    Value<double>? reflowProgress,
    Value<int>? rowid,
  }) {
    return BooksCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      pageCount: pageCount ?? this.pageCount,
      importedAt: importedAt ?? this.importedAt,
      reflowStatus: reflowStatus ?? this.reflowStatus,
      reflowProgress: reflowProgress ?? this.reflowProgress,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (pageCount.present) {
      map['page_count'] = Variable<int>(pageCount.value);
    }
    if (importedAt.present) {
      map['imported_at'] = Variable<DateTime>(importedAt.value);
    }
    if (reflowStatus.present) {
      map['reflow_status'] = Variable<String>(
        $BooksTable.$converterreflowStatus.toSql(reflowStatus.value),
      );
    }
    if (reflowProgress.present) {
      map['reflow_progress'] = Variable<double>(reflowProgress.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BooksCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('pageCount: $pageCount, ')
          ..write('importedAt: $importedAt, ')
          ..write('reflowStatus: $reflowStatus, ')
          ..write('reflowProgress: $reflowProgress, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PreferencesTable extends Preferences
    with TableInfo<$PreferencesTable, Preference> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PreferencesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'preferences';
  @override
  VerificationContext validateIntegrity(
    Insertable<Preference> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  Preference map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Preference(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $PreferencesTable createAlias(String alias) {
    return $PreferencesTable(attachedDatabase, alias);
  }
}

class Preference extends DataClass implements Insertable<Preference> {
  final String key;
  final String value;
  const Preference({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  PreferencesCompanion toCompanion(bool nullToAbsent) {
    return PreferencesCompanion(key: Value(key), value: Value(value));
  }

  factory Preference.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Preference(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  Preference copyWith({String? key, String? value}) =>
      Preference(key: key ?? this.key, value: value ?? this.value);
  Preference copyWithCompanion(PreferencesCompanion data) {
    return Preference(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Preference(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Preference &&
          other.key == this.key &&
          other.value == this.value);
}

class PreferencesCompanion extends UpdateCompanion<Preference> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const PreferencesCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PreferencesCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<Preference> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PreferencesCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return PreferencesCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PreferencesCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReadingPositionsTable extends ReadingPositions
    with TableInfo<$ReadingPositionsTable, ReadingPositionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReadingPositionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _bookIdMeta = const VerificationMeta('bookId');
  @override
  late final GeneratedColumn<String> bookId = GeneratedColumn<String>(
    'book_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<ReadingView, String> view =
      GeneratedColumn<String>(
        'view',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<ReadingView>($ReadingPositionsTable.$converterview);
  static const VerificationMeta _pageMeta = const VerificationMeta('page');
  @override
  late final GeneratedColumn<int> page = GeneratedColumn<int>(
    'page',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _blockIdMeta = const VerificationMeta(
    'blockId',
  );
  @override
  late final GeneratedColumn<String> blockId = GeneratedColumn<String>(
    'block_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _progressMeta = const VerificationMeta(
    'progress',
  );
  @override
  late final GeneratedColumn<double> progress = GeneratedColumn<double>(
    'progress',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    bookId,
    view,
    page,
    blockId,
    progress,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reading_positions';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReadingPositionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('book_id')) {
      context.handle(
        _bookIdMeta,
        bookId.isAcceptableOrUnknown(data['book_id']!, _bookIdMeta),
      );
    } else if (isInserting) {
      context.missing(_bookIdMeta);
    }
    if (data.containsKey('page')) {
      context.handle(
        _pageMeta,
        page.isAcceptableOrUnknown(data['page']!, _pageMeta),
      );
    } else if (isInserting) {
      context.missing(_pageMeta);
    }
    if (data.containsKey('block_id')) {
      context.handle(
        _blockIdMeta,
        blockId.isAcceptableOrUnknown(data['block_id']!, _blockIdMeta),
      );
    }
    if (data.containsKey('progress')) {
      context.handle(
        _progressMeta,
        progress.isAcceptableOrUnknown(data['progress']!, _progressMeta),
      );
    } else if (isInserting) {
      context.missing(_progressMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {bookId, view};
  @override
  ReadingPositionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReadingPositionRow(
      bookId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}book_id'],
      )!,
      view: $ReadingPositionsTable.$converterview.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}view'],
        )!,
      ),
      page: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}page'],
      )!,
      blockId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}block_id'],
      ),
      progress: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}progress'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ReadingPositionsTable createAlias(String alias) {
    return $ReadingPositionsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<ReadingView, String, String> $converterview =
      const EnumNameConverter<ReadingView>(ReadingView.values);
}

class ReadingPositionRow extends DataClass
    implements Insertable<ReadingPositionRow> {
  final String bookId;
  final ReadingView view;
  final int page;
  final String? blockId;
  final double progress;
  final DateTime updatedAt;
  const ReadingPositionRow({
    required this.bookId,
    required this.view,
    required this.page,
    this.blockId,
    required this.progress,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['book_id'] = Variable<String>(bookId);
    {
      map['view'] = Variable<String>(
        $ReadingPositionsTable.$converterview.toSql(view),
      );
    }
    map['page'] = Variable<int>(page);
    if (!nullToAbsent || blockId != null) {
      map['block_id'] = Variable<String>(blockId);
    }
    map['progress'] = Variable<double>(progress);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ReadingPositionsCompanion toCompanion(bool nullToAbsent) {
    return ReadingPositionsCompanion(
      bookId: Value(bookId),
      view: Value(view),
      page: Value(page),
      blockId: blockId == null && nullToAbsent
          ? const Value.absent()
          : Value(blockId),
      progress: Value(progress),
      updatedAt: Value(updatedAt),
    );
  }

  factory ReadingPositionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReadingPositionRow(
      bookId: serializer.fromJson<String>(json['bookId']),
      view: $ReadingPositionsTable.$converterview.fromJson(
        serializer.fromJson<String>(json['view']),
      ),
      page: serializer.fromJson<int>(json['page']),
      blockId: serializer.fromJson<String?>(json['blockId']),
      progress: serializer.fromJson<double>(json['progress']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'bookId': serializer.toJson<String>(bookId),
      'view': serializer.toJson<String>(
        $ReadingPositionsTable.$converterview.toJson(view),
      ),
      'page': serializer.toJson<int>(page),
      'blockId': serializer.toJson<String?>(blockId),
      'progress': serializer.toJson<double>(progress),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ReadingPositionRow copyWith({
    String? bookId,
    ReadingView? view,
    int? page,
    Value<String?> blockId = const Value.absent(),
    double? progress,
    DateTime? updatedAt,
  }) => ReadingPositionRow(
    bookId: bookId ?? this.bookId,
    view: view ?? this.view,
    page: page ?? this.page,
    blockId: blockId.present ? blockId.value : this.blockId,
    progress: progress ?? this.progress,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ReadingPositionRow copyWithCompanion(ReadingPositionsCompanion data) {
    return ReadingPositionRow(
      bookId: data.bookId.present ? data.bookId.value : this.bookId,
      view: data.view.present ? data.view.value : this.view,
      page: data.page.present ? data.page.value : this.page,
      blockId: data.blockId.present ? data.blockId.value : this.blockId,
      progress: data.progress.present ? data.progress.value : this.progress,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReadingPositionRow(')
          ..write('bookId: $bookId, ')
          ..write('view: $view, ')
          ..write('page: $page, ')
          ..write('blockId: $blockId, ')
          ..write('progress: $progress, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(bookId, view, page, blockId, progress, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReadingPositionRow &&
          other.bookId == this.bookId &&
          other.view == this.view &&
          other.page == this.page &&
          other.blockId == this.blockId &&
          other.progress == this.progress &&
          other.updatedAt == this.updatedAt);
}

class ReadingPositionsCompanion extends UpdateCompanion<ReadingPositionRow> {
  final Value<String> bookId;
  final Value<ReadingView> view;
  final Value<int> page;
  final Value<String?> blockId;
  final Value<double> progress;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ReadingPositionsCompanion({
    this.bookId = const Value.absent(),
    this.view = const Value.absent(),
    this.page = const Value.absent(),
    this.blockId = const Value.absent(),
    this.progress = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReadingPositionsCompanion.insert({
    required String bookId,
    required ReadingView view,
    required int page,
    this.blockId = const Value.absent(),
    required double progress,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : bookId = Value(bookId),
       view = Value(view),
       page = Value(page),
       progress = Value(progress),
       updatedAt = Value(updatedAt);
  static Insertable<ReadingPositionRow> custom({
    Expression<String>? bookId,
    Expression<String>? view,
    Expression<int>? page,
    Expression<String>? blockId,
    Expression<double>? progress,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (bookId != null) 'book_id': bookId,
      if (view != null) 'view': view,
      if (page != null) 'page': page,
      if (blockId != null) 'block_id': blockId,
      if (progress != null) 'progress': progress,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReadingPositionsCompanion copyWith({
    Value<String>? bookId,
    Value<ReadingView>? view,
    Value<int>? page,
    Value<String?>? blockId,
    Value<double>? progress,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return ReadingPositionsCompanion(
      bookId: bookId ?? this.bookId,
      view: view ?? this.view,
      page: page ?? this.page,
      blockId: blockId ?? this.blockId,
      progress: progress ?? this.progress,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (bookId.present) {
      map['book_id'] = Variable<String>(bookId.value);
    }
    if (view.present) {
      map['view'] = Variable<String>(
        $ReadingPositionsTable.$converterview.toSql(view.value),
      );
    }
    if (page.present) {
      map['page'] = Variable<int>(page.value);
    }
    if (blockId.present) {
      map['block_id'] = Variable<String>(blockId.value);
    }
    if (progress.present) {
      map['progress'] = Variable<double>(progress.value);
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
    return (StringBuffer('ReadingPositionsCompanion(')
          ..write('bookId: $bookId, ')
          ..write('view: $view, ')
          ..write('page: $page, ')
          ..write('blockId: $blockId, ')
          ..write('progress: $progress, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AnnotationsTable extends Annotations
    with TableInfo<$AnnotationsTable, AnnotationRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AnnotationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _bookIdMeta = const VerificationMeta('bookId');
  @override
  late final GeneratedColumn<String> bookId = GeneratedColumn<String>(
    'book_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<ReadingView, String> view =
      GeneratedColumn<String>(
        'view',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<ReadingView>($AnnotationsTable.$converterview);
  static const VerificationMeta _pageMeta = const VerificationMeta('page');
  @override
  late final GeneratedColumn<int> page = GeneratedColumn<int>(
    'page',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startMeta = const VerificationMeta('start');
  @override
  late final GeneratedColumn<int> start = GeneratedColumn<int>(
    'start',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endMeta = const VerificationMeta('end');
  @override
  late final GeneratedColumn<int> end = GeneratedColumn<int>(
    'end',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _quoteMeta = const VerificationMeta('quote');
  @override
  late final GeneratedColumn<String> quote = GeneratedColumn<String>(
    'quote',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<HighlightColor, String> color =
      GeneratedColumn<String>(
        'color',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<HighlightColor>($AnnotationsTable.$convertercolor);
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _blockIdMeta = const VerificationMeta(
    'blockId',
  );
  @override
  late final GeneratedColumn<String> blockId = GeneratedColumn<String>(
    'block_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _prefixMeta = const VerificationMeta('prefix');
  @override
  late final GeneratedColumn<String> prefix = GeneratedColumn<String>(
    'prefix',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _suffixMeta = const VerificationMeta('suffix');
  @override
  late final GeneratedColumn<String> suffix = GeneratedColumn<String>(
    'suffix',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _engineVersionMeta = const VerificationMeta(
    'engineVersion',
  );
  @override
  late final GeneratedColumn<int> engineVersion = GeneratedColumn<int>(
    'engine_version',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _orphanedMeta = const VerificationMeta(
    'orphaned',
  );
  @override
  late final GeneratedColumn<bool> orphaned = GeneratedColumn<bool>(
    'orphaned',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("orphaned" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    bookId,
    view,
    page,
    start,
    end,
    quote,
    color,
    note,
    blockId,
    prefix,
    suffix,
    engineVersion,
    orphaned,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'annotations';
  @override
  VerificationContext validateIntegrity(
    Insertable<AnnotationRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('book_id')) {
      context.handle(
        _bookIdMeta,
        bookId.isAcceptableOrUnknown(data['book_id']!, _bookIdMeta),
      );
    } else if (isInserting) {
      context.missing(_bookIdMeta);
    }
    if (data.containsKey('page')) {
      context.handle(
        _pageMeta,
        page.isAcceptableOrUnknown(data['page']!, _pageMeta),
      );
    } else if (isInserting) {
      context.missing(_pageMeta);
    }
    if (data.containsKey('start')) {
      context.handle(
        _startMeta,
        start.isAcceptableOrUnknown(data['start']!, _startMeta),
      );
    } else if (isInserting) {
      context.missing(_startMeta);
    }
    if (data.containsKey('end')) {
      context.handle(
        _endMeta,
        end.isAcceptableOrUnknown(data['end']!, _endMeta),
      );
    } else if (isInserting) {
      context.missing(_endMeta);
    }
    if (data.containsKey('quote')) {
      context.handle(
        _quoteMeta,
        quote.isAcceptableOrUnknown(data['quote']!, _quoteMeta),
      );
    } else if (isInserting) {
      context.missing(_quoteMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('block_id')) {
      context.handle(
        _blockIdMeta,
        blockId.isAcceptableOrUnknown(data['block_id']!, _blockIdMeta),
      );
    }
    if (data.containsKey('prefix')) {
      context.handle(
        _prefixMeta,
        prefix.isAcceptableOrUnknown(data['prefix']!, _prefixMeta),
      );
    }
    if (data.containsKey('suffix')) {
      context.handle(
        _suffixMeta,
        suffix.isAcceptableOrUnknown(data['suffix']!, _suffixMeta),
      );
    }
    if (data.containsKey('engine_version')) {
      context.handle(
        _engineVersionMeta,
        engineVersion.isAcceptableOrUnknown(
          data['engine_version']!,
          _engineVersionMeta,
        ),
      );
    }
    if (data.containsKey('orphaned')) {
      context.handle(
        _orphanedMeta,
        orphaned.isAcceptableOrUnknown(data['orphaned']!, _orphanedMeta),
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AnnotationRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AnnotationRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      bookId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}book_id'],
      )!,
      view: $AnnotationsTable.$converterview.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}view'],
        )!,
      ),
      page: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}page'],
      )!,
      start: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start'],
      )!,
      end: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}end'],
      )!,
      quote: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}quote'],
      )!,
      color: $AnnotationsTable.$convertercolor.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}color'],
        )!,
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      blockId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}block_id'],
      ),
      prefix: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}prefix'],
      )!,
      suffix: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}suffix'],
      )!,
      engineVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}engine_version'],
      ),
      orphaned: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}orphaned'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $AnnotationsTable createAlias(String alias) {
    return $AnnotationsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<ReadingView, String, String> $converterview =
      const EnumNameConverter<ReadingView>(ReadingView.values);
  static JsonTypeConverter2<HighlightColor, String, String> $convertercolor =
      const EnumNameConverter<HighlightColor>(HighlightColor.values);
}

class AnnotationRow extends DataClass implements Insertable<AnnotationRow> {
  final int id;
  final String bookId;
  final ReadingView view;
  final int page;
  final int start;
  final int end;
  final String quote;
  final HighlightColor color;
  final String? note;
  final String? blockId;
  final String prefix;
  final String suffix;
  final int? engineVersion;
  final bool orphaned;
  final DateTime createdAt;
  const AnnotationRow({
    required this.id,
    required this.bookId,
    required this.view,
    required this.page,
    required this.start,
    required this.end,
    required this.quote,
    required this.color,
    this.note,
    this.blockId,
    required this.prefix,
    required this.suffix,
    this.engineVersion,
    required this.orphaned,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['book_id'] = Variable<String>(bookId);
    {
      map['view'] = Variable<String>(
        $AnnotationsTable.$converterview.toSql(view),
      );
    }
    map['page'] = Variable<int>(page);
    map['start'] = Variable<int>(start);
    map['end'] = Variable<int>(end);
    map['quote'] = Variable<String>(quote);
    {
      map['color'] = Variable<String>(
        $AnnotationsTable.$convertercolor.toSql(color),
      );
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    if (!nullToAbsent || blockId != null) {
      map['block_id'] = Variable<String>(blockId);
    }
    map['prefix'] = Variable<String>(prefix);
    map['suffix'] = Variable<String>(suffix);
    if (!nullToAbsent || engineVersion != null) {
      map['engine_version'] = Variable<int>(engineVersion);
    }
    map['orphaned'] = Variable<bool>(orphaned);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  AnnotationsCompanion toCompanion(bool nullToAbsent) {
    return AnnotationsCompanion(
      id: Value(id),
      bookId: Value(bookId),
      view: Value(view),
      page: Value(page),
      start: Value(start),
      end: Value(end),
      quote: Value(quote),
      color: Value(color),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      blockId: blockId == null && nullToAbsent
          ? const Value.absent()
          : Value(blockId),
      prefix: Value(prefix),
      suffix: Value(suffix),
      engineVersion: engineVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(engineVersion),
      orphaned: Value(orphaned),
      createdAt: Value(createdAt),
    );
  }

  factory AnnotationRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AnnotationRow(
      id: serializer.fromJson<int>(json['id']),
      bookId: serializer.fromJson<String>(json['bookId']),
      view: $AnnotationsTable.$converterview.fromJson(
        serializer.fromJson<String>(json['view']),
      ),
      page: serializer.fromJson<int>(json['page']),
      start: serializer.fromJson<int>(json['start']),
      end: serializer.fromJson<int>(json['end']),
      quote: serializer.fromJson<String>(json['quote']),
      color: $AnnotationsTable.$convertercolor.fromJson(
        serializer.fromJson<String>(json['color']),
      ),
      note: serializer.fromJson<String?>(json['note']),
      blockId: serializer.fromJson<String?>(json['blockId']),
      prefix: serializer.fromJson<String>(json['prefix']),
      suffix: serializer.fromJson<String>(json['suffix']),
      engineVersion: serializer.fromJson<int?>(json['engineVersion']),
      orphaned: serializer.fromJson<bool>(json['orphaned']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'bookId': serializer.toJson<String>(bookId),
      'view': serializer.toJson<String>(
        $AnnotationsTable.$converterview.toJson(view),
      ),
      'page': serializer.toJson<int>(page),
      'start': serializer.toJson<int>(start),
      'end': serializer.toJson<int>(end),
      'quote': serializer.toJson<String>(quote),
      'color': serializer.toJson<String>(
        $AnnotationsTable.$convertercolor.toJson(color),
      ),
      'note': serializer.toJson<String?>(note),
      'blockId': serializer.toJson<String?>(blockId),
      'prefix': serializer.toJson<String>(prefix),
      'suffix': serializer.toJson<String>(suffix),
      'engineVersion': serializer.toJson<int?>(engineVersion),
      'orphaned': serializer.toJson<bool>(orphaned),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  AnnotationRow copyWith({
    int? id,
    String? bookId,
    ReadingView? view,
    int? page,
    int? start,
    int? end,
    String? quote,
    HighlightColor? color,
    Value<String?> note = const Value.absent(),
    Value<String?> blockId = const Value.absent(),
    String? prefix,
    String? suffix,
    Value<int?> engineVersion = const Value.absent(),
    bool? orphaned,
    DateTime? createdAt,
  }) => AnnotationRow(
    id: id ?? this.id,
    bookId: bookId ?? this.bookId,
    view: view ?? this.view,
    page: page ?? this.page,
    start: start ?? this.start,
    end: end ?? this.end,
    quote: quote ?? this.quote,
    color: color ?? this.color,
    note: note.present ? note.value : this.note,
    blockId: blockId.present ? blockId.value : this.blockId,
    prefix: prefix ?? this.prefix,
    suffix: suffix ?? this.suffix,
    engineVersion: engineVersion.present
        ? engineVersion.value
        : this.engineVersion,
    orphaned: orphaned ?? this.orphaned,
    createdAt: createdAt ?? this.createdAt,
  );
  AnnotationRow copyWithCompanion(AnnotationsCompanion data) {
    return AnnotationRow(
      id: data.id.present ? data.id.value : this.id,
      bookId: data.bookId.present ? data.bookId.value : this.bookId,
      view: data.view.present ? data.view.value : this.view,
      page: data.page.present ? data.page.value : this.page,
      start: data.start.present ? data.start.value : this.start,
      end: data.end.present ? data.end.value : this.end,
      quote: data.quote.present ? data.quote.value : this.quote,
      color: data.color.present ? data.color.value : this.color,
      note: data.note.present ? data.note.value : this.note,
      blockId: data.blockId.present ? data.blockId.value : this.blockId,
      prefix: data.prefix.present ? data.prefix.value : this.prefix,
      suffix: data.suffix.present ? data.suffix.value : this.suffix,
      engineVersion: data.engineVersion.present
          ? data.engineVersion.value
          : this.engineVersion,
      orphaned: data.orphaned.present ? data.orphaned.value : this.orphaned,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AnnotationRow(')
          ..write('id: $id, ')
          ..write('bookId: $bookId, ')
          ..write('view: $view, ')
          ..write('page: $page, ')
          ..write('start: $start, ')
          ..write('end: $end, ')
          ..write('quote: $quote, ')
          ..write('color: $color, ')
          ..write('note: $note, ')
          ..write('blockId: $blockId, ')
          ..write('prefix: $prefix, ')
          ..write('suffix: $suffix, ')
          ..write('engineVersion: $engineVersion, ')
          ..write('orphaned: $orphaned, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    bookId,
    view,
    page,
    start,
    end,
    quote,
    color,
    note,
    blockId,
    prefix,
    suffix,
    engineVersion,
    orphaned,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AnnotationRow &&
          other.id == this.id &&
          other.bookId == this.bookId &&
          other.view == this.view &&
          other.page == this.page &&
          other.start == this.start &&
          other.end == this.end &&
          other.quote == this.quote &&
          other.color == this.color &&
          other.note == this.note &&
          other.blockId == this.blockId &&
          other.prefix == this.prefix &&
          other.suffix == this.suffix &&
          other.engineVersion == this.engineVersion &&
          other.orphaned == this.orphaned &&
          other.createdAt == this.createdAt);
}

class AnnotationsCompanion extends UpdateCompanion<AnnotationRow> {
  final Value<int> id;
  final Value<String> bookId;
  final Value<ReadingView> view;
  final Value<int> page;
  final Value<int> start;
  final Value<int> end;
  final Value<String> quote;
  final Value<HighlightColor> color;
  final Value<String?> note;
  final Value<String?> blockId;
  final Value<String> prefix;
  final Value<String> suffix;
  final Value<int?> engineVersion;
  final Value<bool> orphaned;
  final Value<DateTime> createdAt;
  const AnnotationsCompanion({
    this.id = const Value.absent(),
    this.bookId = const Value.absent(),
    this.view = const Value.absent(),
    this.page = const Value.absent(),
    this.start = const Value.absent(),
    this.end = const Value.absent(),
    this.quote = const Value.absent(),
    this.color = const Value.absent(),
    this.note = const Value.absent(),
    this.blockId = const Value.absent(),
    this.prefix = const Value.absent(),
    this.suffix = const Value.absent(),
    this.engineVersion = const Value.absent(),
    this.orphaned = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  AnnotationsCompanion.insert({
    this.id = const Value.absent(),
    required String bookId,
    required ReadingView view,
    required int page,
    required int start,
    required int end,
    required String quote,
    required HighlightColor color,
    this.note = const Value.absent(),
    this.blockId = const Value.absent(),
    this.prefix = const Value.absent(),
    this.suffix = const Value.absent(),
    this.engineVersion = const Value.absent(),
    this.orphaned = const Value.absent(),
    required DateTime createdAt,
  }) : bookId = Value(bookId),
       view = Value(view),
       page = Value(page),
       start = Value(start),
       end = Value(end),
       quote = Value(quote),
       color = Value(color),
       createdAt = Value(createdAt);
  static Insertable<AnnotationRow> custom({
    Expression<int>? id,
    Expression<String>? bookId,
    Expression<String>? view,
    Expression<int>? page,
    Expression<int>? start,
    Expression<int>? end,
    Expression<String>? quote,
    Expression<String>? color,
    Expression<String>? note,
    Expression<String>? blockId,
    Expression<String>? prefix,
    Expression<String>? suffix,
    Expression<int>? engineVersion,
    Expression<bool>? orphaned,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (bookId != null) 'book_id': bookId,
      if (view != null) 'view': view,
      if (page != null) 'page': page,
      if (start != null) 'start': start,
      if (end != null) 'end': end,
      if (quote != null) 'quote': quote,
      if (color != null) 'color': color,
      if (note != null) 'note': note,
      if (blockId != null) 'block_id': blockId,
      if (prefix != null) 'prefix': prefix,
      if (suffix != null) 'suffix': suffix,
      if (engineVersion != null) 'engine_version': engineVersion,
      if (orphaned != null) 'orphaned': orphaned,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  AnnotationsCompanion copyWith({
    Value<int>? id,
    Value<String>? bookId,
    Value<ReadingView>? view,
    Value<int>? page,
    Value<int>? start,
    Value<int>? end,
    Value<String>? quote,
    Value<HighlightColor>? color,
    Value<String?>? note,
    Value<String?>? blockId,
    Value<String>? prefix,
    Value<String>? suffix,
    Value<int?>? engineVersion,
    Value<bool>? orphaned,
    Value<DateTime>? createdAt,
  }) {
    return AnnotationsCompanion(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      view: view ?? this.view,
      page: page ?? this.page,
      start: start ?? this.start,
      end: end ?? this.end,
      quote: quote ?? this.quote,
      color: color ?? this.color,
      note: note ?? this.note,
      blockId: blockId ?? this.blockId,
      prefix: prefix ?? this.prefix,
      suffix: suffix ?? this.suffix,
      engineVersion: engineVersion ?? this.engineVersion,
      orphaned: orphaned ?? this.orphaned,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (bookId.present) {
      map['book_id'] = Variable<String>(bookId.value);
    }
    if (view.present) {
      map['view'] = Variable<String>(
        $AnnotationsTable.$converterview.toSql(view.value),
      );
    }
    if (page.present) {
      map['page'] = Variable<int>(page.value);
    }
    if (start.present) {
      map['start'] = Variable<int>(start.value);
    }
    if (end.present) {
      map['end'] = Variable<int>(end.value);
    }
    if (quote.present) {
      map['quote'] = Variable<String>(quote.value);
    }
    if (color.present) {
      map['color'] = Variable<String>(
        $AnnotationsTable.$convertercolor.toSql(color.value),
      );
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (blockId.present) {
      map['block_id'] = Variable<String>(blockId.value);
    }
    if (prefix.present) {
      map['prefix'] = Variable<String>(prefix.value);
    }
    if (suffix.present) {
      map['suffix'] = Variable<String>(suffix.value);
    }
    if (engineVersion.present) {
      map['engine_version'] = Variable<int>(engineVersion.value);
    }
    if (orphaned.present) {
      map['orphaned'] = Variable<bool>(orphaned.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AnnotationsCompanion(')
          ..write('id: $id, ')
          ..write('bookId: $bookId, ')
          ..write('view: $view, ')
          ..write('page: $page, ')
          ..write('start: $start, ')
          ..write('end: $end, ')
          ..write('quote: $quote, ')
          ..write('color: $color, ')
          ..write('note: $note, ')
          ..write('blockId: $blockId, ')
          ..write('prefix: $prefix, ')
          ..write('suffix: $suffix, ')
          ..write('engineVersion: $engineVersion, ')
          ..write('orphaned: $orphaned, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $BooksTable books = $BooksTable(this);
  late final $PreferencesTable preferences = $PreferencesTable(this);
  late final $ReadingPositionsTable readingPositions = $ReadingPositionsTable(
    this,
  );
  late final $AnnotationsTable annotations = $AnnotationsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    books,
    preferences,
    readingPositions,
    annotations,
  ];
}

typedef $$BooksTableCreateCompanionBuilder = BooksCompanion Function({
  required String id,
  required String title,
  required int pageCount,
  required DateTime importedAt,
  Value<ReflowStatus> reflowStatus,
  Value<double> reflowProgress,
  Value<int> rowid,
});
typedef $$BooksTableUpdateCompanionBuilder = BooksCompanion Function({
  Value<String> id,
  Value<String> title,
  Value<int> pageCount,
  Value<DateTime> importedAt,
  Value<ReflowStatus> reflowStatus,
  Value<double> reflowProgress,
  Value<int> rowid,
});

class $$BooksTableFilterComposer extends Composer<_$AppDatabase, $BooksTable> {
  $$BooksTableFilterComposer({
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

  ColumnFilters<int> get pageCount => $composableBuilder(
    column: $table.pageCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get importedAt => $composableBuilder(
    column: $table.importedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<ReflowStatus, ReflowStatus, String>
  get reflowStatus => $composableBuilder(
    column: $table.reflowStatus,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<double> get reflowProgress => $composableBuilder(
    column: $table.reflowProgress,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BooksTableOrderingComposer
    extends Composer<_$AppDatabase, $BooksTable> {
  $$BooksTableOrderingComposer({
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

  ColumnOrderings<int> get pageCount => $composableBuilder(
    column: $table.pageCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get importedAt => $composableBuilder(
    column: $table.importedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reflowStatus => $composableBuilder(
    column: $table.reflowStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get reflowProgress => $composableBuilder(
    column: $table.reflowProgress,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BooksTableAnnotationComposer
    extends Composer<_$AppDatabase, $BooksTable> {
  $$BooksTableAnnotationComposer({
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

  GeneratedColumn<int> get pageCount =>
      $composableBuilder(column: $table.pageCount, builder: (column) => column);

  GeneratedColumn<DateTime> get importedAt => $composableBuilder(
    column: $table.importedAt,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<ReflowStatus, String> get reflowStatus =>
      $composableBuilder(
        column: $table.reflowStatus,
        builder: (column) => column,
      );

  GeneratedColumn<double> get reflowProgress => $composableBuilder(
    column: $table.reflowProgress,
    builder: (column) => column,
  );
}

class $$BooksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BooksTable,
          Book,
          $$BooksTableFilterComposer,
          $$BooksTableOrderingComposer,
          $$BooksTableAnnotationComposer,
          $$BooksTableCreateCompanionBuilder,
          $$BooksTableUpdateCompanionBuilder,
          (Book, BaseReferences<_$AppDatabase, $BooksTable, Book>),
          Book,
          PrefetchHooks Function()
        > {
  $$BooksTableTableManager(_$AppDatabase db, $BooksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BooksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BooksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BooksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<int> pageCount = const Value.absent(),
                Value<DateTime> importedAt = const Value.absent(),
                Value<ReflowStatus> reflowStatus = const Value.absent(),
                Value<double> reflowProgress = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BooksCompanion(
                id: id,
                title: title,
                pageCount: pageCount,
                importedAt: importedAt,
                reflowStatus: reflowStatus,
                reflowProgress: reflowProgress,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                required int pageCount,
                required DateTime importedAt,
                Value<ReflowStatus> reflowStatus = const Value.absent(),
                Value<double> reflowProgress = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BooksCompanion.insert(
                id: id,
                title: title,
                pageCount: pageCount,
                importedAt: importedAt,
                reflowStatus: reflowStatus,
                reflowProgress: reflowProgress,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$BooksTable, Book>(table),
                  BaseReferences<_$AppDatabase, $BooksTable, Book>(
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

typedef $$BooksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BooksTable,
      Book,
      $$BooksTableFilterComposer,
      $$BooksTableOrderingComposer,
      $$BooksTableAnnotationComposer,
      $$BooksTableCreateCompanionBuilder,
      $$BooksTableUpdateCompanionBuilder,
      (Book, BaseReferences<_$AppDatabase, $BooksTable, Book>),
      Book,
      PrefetchHooks Function()
    >;
typedef $$PreferencesTableCreateCompanionBuilder =
    PreferencesCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$PreferencesTableUpdateCompanionBuilder =
    PreferencesCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$PreferencesTableFilterComposer
    extends Composer<_$AppDatabase, $PreferencesTable> {
  $$PreferencesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PreferencesTableOrderingComposer
    extends Composer<_$AppDatabase, $PreferencesTable> {
  $$PreferencesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PreferencesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PreferencesTable> {
  $$PreferencesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$PreferencesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PreferencesTable,
          Preference,
          $$PreferencesTableFilterComposer,
          $$PreferencesTableOrderingComposer,
          $$PreferencesTableAnnotationComposer,
          $$PreferencesTableCreateCompanionBuilder,
          $$PreferencesTableUpdateCompanionBuilder,
          (
            Preference,
            BaseReferences<_$AppDatabase, $PreferencesTable, Preference>,
          ),
          Preference,
          PrefetchHooks Function()
        > {
  $$PreferencesTableTableManager(_$AppDatabase db, $PreferencesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PreferencesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PreferencesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PreferencesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => PreferencesCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => PreferencesCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PreferencesTable, Preference>(table),
                  BaseReferences<_$AppDatabase, $PreferencesTable, Preference>(
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

typedef $$PreferencesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PreferencesTable,
      Preference,
      $$PreferencesTableFilterComposer,
      $$PreferencesTableOrderingComposer,
      $$PreferencesTableAnnotationComposer,
      $$PreferencesTableCreateCompanionBuilder,
      $$PreferencesTableUpdateCompanionBuilder,
      (
        Preference,
        BaseReferences<_$AppDatabase, $PreferencesTable, Preference>,
      ),
      Preference,
      PrefetchHooks Function()
    >;
typedef $$ReadingPositionsTableCreateCompanionBuilder =
    ReadingPositionsCompanion Function({
      required String bookId,
      required ReadingView view,
      required int page,
      Value<String?> blockId,
      required double progress,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$ReadingPositionsTableUpdateCompanionBuilder =
    ReadingPositionsCompanion Function({
      Value<String> bookId,
      Value<ReadingView> view,
      Value<int> page,
      Value<String?> blockId,
      Value<double> progress,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$ReadingPositionsTableFilterComposer
    extends Composer<_$AppDatabase, $ReadingPositionsTable> {
  $$ReadingPositionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get bookId => $composableBuilder(
    column: $table.bookId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<ReadingView, ReadingView, String> get view =>
      $composableBuilder(
        column: $table.view,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get page => $composableBuilder(
    column: $table.page,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get blockId => $composableBuilder(
    column: $table.blockId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get progress => $composableBuilder(
    column: $table.progress,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ReadingPositionsTableOrderingComposer
    extends Composer<_$AppDatabase, $ReadingPositionsTable> {
  $$ReadingPositionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get bookId => $composableBuilder(
    column: $table.bookId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get view => $composableBuilder(
    column: $table.view,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get page => $composableBuilder(
    column: $table.page,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get blockId => $composableBuilder(
    column: $table.blockId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get progress => $composableBuilder(
    column: $table.progress,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ReadingPositionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReadingPositionsTable> {
  $$ReadingPositionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get bookId =>
      $composableBuilder(column: $table.bookId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ReadingView, String> get view =>
      $composableBuilder(column: $table.view, builder: (column) => column);

  GeneratedColumn<int> get page =>
      $composableBuilder(column: $table.page, builder: (column) => column);

  GeneratedColumn<String> get blockId =>
      $composableBuilder(column: $table.blockId, builder: (column) => column);

  GeneratedColumn<double> get progress =>
      $composableBuilder(column: $table.progress, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ReadingPositionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReadingPositionsTable,
          ReadingPositionRow,
          $$ReadingPositionsTableFilterComposer,
          $$ReadingPositionsTableOrderingComposer,
          $$ReadingPositionsTableAnnotationComposer,
          $$ReadingPositionsTableCreateCompanionBuilder,
          $$ReadingPositionsTableUpdateCompanionBuilder,
          (
            ReadingPositionRow,
            BaseReferences<
              _$AppDatabase,
              $ReadingPositionsTable,
              ReadingPositionRow
            >,
          ),
          ReadingPositionRow,
          PrefetchHooks Function()
        > {
  $$ReadingPositionsTableTableManager(
    _$AppDatabase db,
    $ReadingPositionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReadingPositionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReadingPositionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReadingPositionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> bookId = const Value.absent(),
                Value<ReadingView> view = const Value.absent(),
                Value<int> page = const Value.absent(),
                Value<String?> blockId = const Value.absent(),
                Value<double> progress = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReadingPositionsCompanion(
                bookId: bookId,
                view: view,
                page: page,
                blockId: blockId,
                progress: progress,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String bookId,
                required ReadingView view,
                required int page,
                Value<String?> blockId = const Value.absent(),
                required double progress,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => ReadingPositionsCompanion.insert(
                bookId: bookId,
                view: view,
                page: page,
                blockId: blockId,
                progress: progress,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ReadingPositionsTable, ReadingPositionRow>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $ReadingPositionsTable,
                    ReadingPositionRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ReadingPositionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReadingPositionsTable,
      ReadingPositionRow,
      $$ReadingPositionsTableFilterComposer,
      $$ReadingPositionsTableOrderingComposer,
      $$ReadingPositionsTableAnnotationComposer,
      $$ReadingPositionsTableCreateCompanionBuilder,
      $$ReadingPositionsTableUpdateCompanionBuilder,
      (
        ReadingPositionRow,
        BaseReferences<
          _$AppDatabase,
          $ReadingPositionsTable,
          ReadingPositionRow
        >,
      ),
      ReadingPositionRow,
      PrefetchHooks Function()
    >;
typedef $$AnnotationsTableCreateCompanionBuilder =
    AnnotationsCompanion Function({
      Value<int> id,
      required String bookId,
      required ReadingView view,
      required int page,
      required int start,
      required int end,
      required String quote,
      required HighlightColor color,
      Value<String?> note,
      Value<String?> blockId,
      Value<String> prefix,
      Value<String> suffix,
      Value<int?> engineVersion,
      Value<bool> orphaned,
      required DateTime createdAt,
    });
typedef $$AnnotationsTableUpdateCompanionBuilder =
    AnnotationsCompanion Function({
      Value<int> id,
      Value<String> bookId,
      Value<ReadingView> view,
      Value<int> page,
      Value<int> start,
      Value<int> end,
      Value<String> quote,
      Value<HighlightColor> color,
      Value<String?> note,
      Value<String?> blockId,
      Value<String> prefix,
      Value<String> suffix,
      Value<int?> engineVersion,
      Value<bool> orphaned,
      Value<DateTime> createdAt,
    });

class $$AnnotationsTableFilterComposer
    extends Composer<_$AppDatabase, $AnnotationsTable> {
  $$AnnotationsTableFilterComposer({
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

  ColumnFilters<String> get bookId => $composableBuilder(
    column: $table.bookId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<ReadingView, ReadingView, String> get view =>
      $composableBuilder(
        column: $table.view,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get page => $composableBuilder(
    column: $table.page,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get start => $composableBuilder(
    column: $table.start,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get end => $composableBuilder(
    column: $table.end,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get quote => $composableBuilder(
    column: $table.quote,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<HighlightColor, HighlightColor, String>
  get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get blockId => $composableBuilder(
    column: $table.blockId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get prefix => $composableBuilder(
    column: $table.prefix,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get suffix => $composableBuilder(
    column: $table.suffix,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get engineVersion => $composableBuilder(
    column: $table.engineVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get orphaned => $composableBuilder(
    column: $table.orphaned,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AnnotationsTableOrderingComposer
    extends Composer<_$AppDatabase, $AnnotationsTable> {
  $$AnnotationsTableOrderingComposer({
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

  ColumnOrderings<String> get bookId => $composableBuilder(
    column: $table.bookId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get view => $composableBuilder(
    column: $table.view,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get page => $composableBuilder(
    column: $table.page,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get start => $composableBuilder(
    column: $table.start,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get end => $composableBuilder(
    column: $table.end,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get quote => $composableBuilder(
    column: $table.quote,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get blockId => $composableBuilder(
    column: $table.blockId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get prefix => $composableBuilder(
    column: $table.prefix,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get suffix => $composableBuilder(
    column: $table.suffix,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get engineVersion => $composableBuilder(
    column: $table.engineVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get orphaned => $composableBuilder(
    column: $table.orphaned,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AnnotationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AnnotationsTable> {
  $$AnnotationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get bookId =>
      $composableBuilder(column: $table.bookId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ReadingView, String> get view =>
      $composableBuilder(column: $table.view, builder: (column) => column);

  GeneratedColumn<int> get page =>
      $composableBuilder(column: $table.page, builder: (column) => column);

  GeneratedColumn<int> get start =>
      $composableBuilder(column: $table.start, builder: (column) => column);

  GeneratedColumn<int> get end =>
      $composableBuilder(column: $table.end, builder: (column) => column);

  GeneratedColumn<String> get quote =>
      $composableBuilder(column: $table.quote, builder: (column) => column);

  GeneratedColumnWithTypeConverter<HighlightColor, String> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get blockId =>
      $composableBuilder(column: $table.blockId, builder: (column) => column);

  GeneratedColumn<String> get prefix =>
      $composableBuilder(column: $table.prefix, builder: (column) => column);

  GeneratedColumn<String> get suffix =>
      $composableBuilder(column: $table.suffix, builder: (column) => column);

  GeneratedColumn<int> get engineVersion => $composableBuilder(
    column: $table.engineVersion,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get orphaned =>
      $composableBuilder(column: $table.orphaned, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$AnnotationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AnnotationsTable,
          AnnotationRow,
          $$AnnotationsTableFilterComposer,
          $$AnnotationsTableOrderingComposer,
          $$AnnotationsTableAnnotationComposer,
          $$AnnotationsTableCreateCompanionBuilder,
          $$AnnotationsTableUpdateCompanionBuilder,
          (
            AnnotationRow,
            BaseReferences<_$AppDatabase, $AnnotationsTable, AnnotationRow>,
          ),
          AnnotationRow,
          PrefetchHooks Function()
        > {
  $$AnnotationsTableTableManager(_$AppDatabase db, $AnnotationsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AnnotationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AnnotationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AnnotationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> bookId = const Value.absent(),
                Value<ReadingView> view = const Value.absent(),
                Value<int> page = const Value.absent(),
                Value<int> start = const Value.absent(),
                Value<int> end = const Value.absent(),
                Value<String> quote = const Value.absent(),
                Value<HighlightColor> color = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<String?> blockId = const Value.absent(),
                Value<String> prefix = const Value.absent(),
                Value<String> suffix = const Value.absent(),
                Value<int?> engineVersion = const Value.absent(),
                Value<bool> orphaned = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => AnnotationsCompanion(
                id: id,
                bookId: bookId,
                view: view,
                page: page,
                start: start,
                end: end,
                quote: quote,
                color: color,
                note: note,
                blockId: blockId,
                prefix: prefix,
                suffix: suffix,
                engineVersion: engineVersion,
                orphaned: orphaned,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String bookId,
                required ReadingView view,
                required int page,
                required int start,
                required int end,
                required String quote,
                required HighlightColor color,
                Value<String?> note = const Value.absent(),
                Value<String?> blockId = const Value.absent(),
                Value<String> prefix = const Value.absent(),
                Value<String> suffix = const Value.absent(),
                Value<int?> engineVersion = const Value.absent(),
                Value<bool> orphaned = const Value.absent(),
                required DateTime createdAt,
              }) => AnnotationsCompanion.insert(
                id: id,
                bookId: bookId,
                view: view,
                page: page,
                start: start,
                end: end,
                quote: quote,
                color: color,
                note: note,
                blockId: blockId,
                prefix: prefix,
                suffix: suffix,
                engineVersion: engineVersion,
                orphaned: orphaned,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AnnotationsTable, AnnotationRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $AnnotationsTable,
                    AnnotationRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AnnotationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AnnotationsTable,
      AnnotationRow,
      $$AnnotationsTableFilterComposer,
      $$AnnotationsTableOrderingComposer,
      $$AnnotationsTableAnnotationComposer,
      $$AnnotationsTableCreateCompanionBuilder,
      $$AnnotationsTableUpdateCompanionBuilder,
      (
        AnnotationRow,
        BaseReferences<_$AppDatabase, $AnnotationsTable, AnnotationRow>,
      ),
      AnnotationRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$BooksTableTableManager get books =>
      $$BooksTableTableManager(_db, _db.books);
  $$PreferencesTableTableManager get preferences =>
      $$PreferencesTableTableManager(_db, _db.preferences);
  $$ReadingPositionsTableTableManager get readingPositions =>
      $$ReadingPositionsTableTableManager(_db, _db.readingPositions);
  $$AnnotationsTableTableManager get annotations =>
      $$AnnotationsTableTableManager(_db, _db.annotations);
}
