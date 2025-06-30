// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cached_relay.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetCachedRelayCollection on Isar {
  IsarCollection<CachedRelay> get cachedRelays => this.collection();
}

const CachedRelaySchema = CollectionSchema(
  name: r'CachedRelay',
  id: 10,
  properties: {
    r'averageResponseTime': PropertySchema(
      id: 0,
      name: r'averageResponseTime',
      type: IsarType.double,
    ),
    r'contact': PropertySchema(
      id: 1,
      name: r'contact',
      type: IsarType.string,
    ),
    r'description': PropertySchema(
      id: 2,
      name: r'description',
      type: IsarType.string,
    ),
    r'failedConnections': PropertySchema(
      id: 3,
      name: r'failedConnections',
      type: IsarType.long,
    ),
    r'firstSeen': PropertySchema(
      id: 4,
      name: r'firstSeen',
      type: IsarType.dateTime,
    ),
    r'isHealthy': PropertySchema(
      id: 5,
      name: r'isHealthy',
      type: IsarType.bool,
    ),
    r'lastConnected': PropertySchema(
      id: 6,
      name: r'lastConnected',
      type: IsarType.dateTime,
    ),
    r'name': PropertySchema(
      id: 7,
      name: r'name',
      type: IsarType.string,
    ),
    r'pubkey': PropertySchema(
      id: 8,
      name: r'pubkey',
      type: IsarType.string,
    ),
    r'readPubkeys': PropertySchema(
      id: 9,
      name: r'readPubkeys',
      type: IsarType.stringList,
    ),
    r'reliabilityScore': PropertySchema(
      id: 10,
      name: r'reliabilityScore',
      type: IsarType.long,
    ),
    r'software': PropertySchema(
      id: 11,
      name: r'software',
      type: IsarType.string,
    ),
    r'status': PropertySchema(
      id: 12,
      name: r'status',
      type: IsarType.byte,
      enumMap: _CachedRelaystatusEnumValueMap,
    ),
    r'successfulConnections': PropertySchema(
      id: 13,
      name: r'successfulConnections',
      type: IsarType.long,
    ),
    r'supportedNips': PropertySchema(
      id: 14,
      name: r'supportedNips',
      type: IsarType.longList,
    ),
    r'url': PropertySchema(
      id: 15,
      name: r'url',
      type: IsarType.string,
    ),
    r'version': PropertySchema(
      id: 16,
      name: r'version',
      type: IsarType.string,
    ),
    r'writePubkeys': PropertySchema(
      id: 17,
      name: r'writePubkeys',
      type: IsarType.stringList,
    )
  },
  estimateSize: _cachedRelayEstimateSize,
  serialize: _cachedRelaySerialize,
  deserialize: _cachedRelayDeserialize,
  deserializeProp: _cachedRelayDeserializeProp,
  idName: r'id',
  indexes: {
    r'url': IndexSchema(
      id: 11,
      name: r'url',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'url',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'lastConnected': IndexSchema(
      id: 12,
      name: r'lastConnected',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'lastConnected',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _cachedRelayGetId,
  getLinks: _cachedRelayGetLinks,
  attach: _cachedRelayAttach,
  version: '3.1.0+1',
);

int _cachedRelayEstimateSize(
  CachedRelay object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.contact;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.description;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.name;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.pubkey;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.readPubkeys.length * 3;
  {
    for (var i = 0; i < object.readPubkeys.length; i++) {
      final value = object.readPubkeys[i];
      bytesCount += value.length * 3;
    }
  }
  {
    final value = object.software;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.supportedNips.length * 8;
  bytesCount += 3 + object.url.length * 3;
  {
    final value = object.version;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.writePubkeys.length * 3;
  {
    for (var i = 0; i < object.writePubkeys.length; i++) {
      final value = object.writePubkeys[i];
      bytesCount += value.length * 3;
    }
  }
  return bytesCount;
}

void _cachedRelaySerialize(
  CachedRelay object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDouble(offsets[0], object.averageResponseTime);
  writer.writeString(offsets[1], object.contact);
  writer.writeString(offsets[2], object.description);
  writer.writeLong(offsets[3], object.failedConnections);
  writer.writeDateTime(offsets[4], object.firstSeen);
  writer.writeBool(offsets[5], object.isHealthy);
  writer.writeDateTime(offsets[6], object.lastConnected);
  writer.writeString(offsets[7], object.name);
  writer.writeString(offsets[8], object.pubkey);
  writer.writeStringList(offsets[9], object.readPubkeys);
  writer.writeLong(offsets[10], object.reliabilityScore);
  writer.writeString(offsets[11], object.software);
  writer.writeByte(offsets[12], object.status.index);
  writer.writeLong(offsets[13], object.successfulConnections);
  writer.writeLongList(offsets[14], object.supportedNips);
  writer.writeString(offsets[15], object.url);
  writer.writeString(offsets[16], object.version);
  writer.writeStringList(offsets[17], object.writePubkeys);
}

CachedRelay _cachedRelayDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = CachedRelay();
  object.averageResponseTime = reader.readDouble(offsets[0]);
  object.contact = reader.readStringOrNull(offsets[1]);
  object.description = reader.readStringOrNull(offsets[2]);
  object.failedConnections = reader.readLong(offsets[3]);
  object.firstSeen = reader.readDateTime(offsets[4]);
  object.id = id;
  object.lastConnected = reader.readDateTime(offsets[6]);
  object.name = reader.readStringOrNull(offsets[7]);
  object.pubkey = reader.readStringOrNull(offsets[8]);
  object.readPubkeys = reader.readStringList(offsets[9]) ?? [];
  object.software = reader.readStringOrNull(offsets[11]);
  object.status =
      _CachedRelaystatusValueEnumMap[reader.readByteOrNull(offsets[12])] ??
          RelayStatus.unknown;
  object.successfulConnections = reader.readLong(offsets[13]);
  object.supportedNips = reader.readLongList(offsets[14]) ?? [];
  object.url = reader.readString(offsets[15]);
  object.version = reader.readStringOrNull(offsets[16]);
  object.writePubkeys = reader.readStringList(offsets[17]) ?? [];
  return object;
}

P _cachedRelayDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDouble(offset)) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readLong(offset)) as P;
    case 4:
      return (reader.readDateTime(offset)) as P;
    case 5:
      return (reader.readBool(offset)) as P;
    case 6:
      return (reader.readDateTime(offset)) as P;
    case 7:
      return (reader.readStringOrNull(offset)) as P;
    case 8:
      return (reader.readStringOrNull(offset)) as P;
    case 9:
      return (reader.readStringList(offset) ?? []) as P;
    case 10:
      return (reader.readLong(offset)) as P;
    case 11:
      return (reader.readStringOrNull(offset)) as P;
    case 12:
      return (_CachedRelaystatusValueEnumMap[reader.readByteOrNull(offset)] ??
          RelayStatus.unknown) as P;
    case 13:
      return (reader.readLong(offset)) as P;
    case 14:
      return (reader.readLongList(offset) ?? []) as P;
    case 15:
      return (reader.readString(offset)) as P;
    case 16:
      return (reader.readStringOrNull(offset)) as P;
    case 17:
      return (reader.readStringList(offset) ?? []) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _CachedRelaystatusEnumValueMap = {
  'unknown': 0,
  'connected': 1,
  'disconnected': 2,
  'error': 3,
  'banned': 4,
};
const _CachedRelaystatusValueEnumMap = {
  0: RelayStatus.unknown,
  1: RelayStatus.connected,
  2: RelayStatus.disconnected,
  3: RelayStatus.error,
  4: RelayStatus.banned,
};

Id _cachedRelayGetId(CachedRelay object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _cachedRelayGetLinks(CachedRelay object) {
  return [];
}

void _cachedRelayAttach(
    IsarCollection<dynamic> col, Id id, CachedRelay object) {
  object.id = id;
}

extension CachedRelayByIndex on IsarCollection<CachedRelay> {
  Future<CachedRelay?> getByUrl(String url) {
    return getByIndex(r'url', [url]);
  }

  CachedRelay? getByUrlSync(String url) {
    return getByIndexSync(r'url', [url]);
  }

  Future<bool> deleteByUrl(String url) {
    return deleteByIndex(r'url', [url]);
  }

  bool deleteByUrlSync(String url) {
    return deleteByIndexSync(r'url', [url]);
  }

  Future<List<CachedRelay?>> getAllByUrl(List<String> urlValues) {
    final values = urlValues.map((e) => [e]).toList();
    return getAllByIndex(r'url', values);
  }

  List<CachedRelay?> getAllByUrlSync(List<String> urlValues) {
    final values = urlValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'url', values);
  }

  Future<int> deleteAllByUrl(List<String> urlValues) {
    final values = urlValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'url', values);
  }

  int deleteAllByUrlSync(List<String> urlValues) {
    final values = urlValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'url', values);
  }

  Future<Id> putByUrl(CachedRelay object) {
    return putByIndex(r'url', object);
  }

  Id putByUrlSync(CachedRelay object, {bool saveLinks = true}) {
    return putByIndexSync(r'url', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByUrl(List<CachedRelay> objects) {
    return putAllByIndex(r'url', objects);
  }

  List<Id> putAllByUrlSync(List<CachedRelay> objects, {bool saveLinks = true}) {
    return putAllByIndexSync(r'url', objects, saveLinks: saveLinks);
  }
}

extension CachedRelayQueryWhereSort
    on QueryBuilder<CachedRelay, CachedRelay, QWhere> {
  QueryBuilder<CachedRelay, CachedRelay, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterWhere> anyLastConnected() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'lastConnected'),
      );
    });
  }
}

extension CachedRelayQueryWhere
    on QueryBuilder<CachedRelay, CachedRelay, QWhereClause> {
  QueryBuilder<CachedRelay, CachedRelay, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterWhereClause> idNotEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterWhereClause> urlEqualTo(
      String url) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'url',
        value: [url],
      ));
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterWhereClause> urlNotEqualTo(
      String url) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'url',
              lower: [],
              upper: [url],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'url',
              lower: [url],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'url',
              lower: [url],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'url',
              lower: [],
              upper: [url],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterWhereClause>
      lastConnectedEqualTo(DateTime lastConnected) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'lastConnected',
        value: [lastConnected],
      ));
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterWhereClause>
      lastConnectedNotEqualTo(DateTime lastConnected) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'lastConnected',
              lower: [],
              upper: [lastConnected],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'lastConnected',
              lower: [lastConnected],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'lastConnected',
              lower: [lastConnected],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'lastConnected',
              lower: [],
              upper: [lastConnected],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterWhereClause>
      lastConnectedGreaterThan(
    DateTime lastConnected, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'lastConnected',
        lower: [lastConnected],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterWhereClause>
      lastConnectedLessThan(
    DateTime lastConnected, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'lastConnected',
        lower: [],
        upper: [lastConnected],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterWhereClause>
      lastConnectedBetween(
    DateTime lowerLastConnected,
    DateTime upperLastConnected, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'lastConnected',
        lower: [lowerLastConnected],
        includeLower: includeLower,
        upper: [upperLastConnected],
        includeUpper: includeUpper,
      ));
    });
  }
}

extension CachedRelayQueryFilter
    on QueryBuilder<CachedRelay, CachedRelay, QFilterCondition> {
  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition>
      averageResponseTimeEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'averageResponseTime',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition>
      averageResponseTimeGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'averageResponseTime',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition>
      averageResponseTimeLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'averageResponseTime',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition>
      averageResponseTimeBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'averageResponseTime',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition>
      contactIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'contact',
      ));
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition>
      contactIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'contact',
      ));
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition> contactEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'contact',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition>
      contactGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'contact',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition> contactLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'contact',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition> contactBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'contact',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition>
      contactStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'contact',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition> contactEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'contact',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition> contactContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'contact',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition> contactMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'contact',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition>
      contactIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'contact',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition>
      contactIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'contact',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition>
      descriptionIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'description',
      ));
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition>
      descriptionIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'description',
      ));
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition>
      descriptionEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition>
      descriptionGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition>
      descriptionLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition>
      descriptionBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'description',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition>
      descriptionStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition>
      descriptionEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition>
      descriptionContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition>
      descriptionMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'description',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition>
      descriptionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'description',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition>
      descriptionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'description',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition>
      failedConnectionsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'failedConnections',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition>
      failedConnectionsGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'failedConnections',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition>
      failedConnectionsLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'failedConnections',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition>
      failedConnectionsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'failedConnections',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition>
      firstSeenEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'firstSeen',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition>
      firstSeenGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'firstSeen',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition>
      firstSeenLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'firstSeen',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition>
      firstSeenBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'firstSeen',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition>
      isHealthyEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isHealthy',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition>
      lastConnectedEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastConnected',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition>
      lastConnectedGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lastConnected',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition>
      lastConnectedLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lastConnected',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition>
      lastConnectedBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lastConnected',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition> nameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'name',
      ));
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition>
      nameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'name',
      ));
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition> nameEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition> nameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition> nameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition> nameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'name',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition> nameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition> nameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition> nameContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition> nameMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'name',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition> nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition>
      nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition> pubkeyIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'pubkey',
      ));
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition>
      pubkeyIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'pubkey',
      ));
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition> pubkeyEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'pubkey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition>
      pubkeyGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'pubkey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition> pubkeyLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'pubkey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition> pubkeyBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'pubkey',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition>
      pubkeyStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'pubkey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition> pubkeyEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'pubkey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition> pubkeyContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'pubkey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition> pubkeyMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'pubkey',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition>
      pubkeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'pubkey',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition>
      pubkeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'pubkey',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition>
      readPubkeysElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'readPubkeys',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition>
      readPubkeysElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'readPubkeys',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition>
      readPubkeysElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'readPubkeys',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition>
      readPubkeysElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'readPubkeys',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition>
      readPubkeysElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'readPubkeys',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition>
      readPubkeysElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'readPubkeys',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition>
      readPubkeysElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'readPubkeys',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition>
      readPubkeysElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'readPubkeys',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition>
      readPubkeysElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'readPubkeys',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition>
      readPubkeysElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'readPubkeys',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition>
      readPubkeysLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'readPubkeys',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition>
      readPubkeysIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'readPubkeys',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition>
      readPubkeysIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'readPubkeys',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition>
      readPubkeysLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'readPubkeys',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition>
      readPubkeysLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'readPubkeys',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition>
      readPubkeysLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'readPubkeys',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition>
      reliabilityScoreEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'reliabilityScore',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition>
      reliabilityScoreGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'reliabilityScore',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition>
      reliabilityScoreLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'reliabilityScore',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition>
      reliabilityScoreBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'reliabilityScore',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition>
      softwareIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'software',
      ));
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition>
      softwareIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'software',
      ));
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition> softwareEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'software',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition>
      softwareGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'software',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition>
      softwareLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'software',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition> softwareBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'software',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition>
      softwareStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'software',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition>
      softwareEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'software',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition>
      softwareContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'software',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition> softwareMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'software',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition>
      softwareIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'software',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition>
      softwareIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'software',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition> statusEqualTo(
      RelayStatus value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'status',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition>
      statusGreaterThan(
    RelayStatus value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'status',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition> statusLessThan(
    RelayStatus value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'status',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition> statusBetween(
    RelayStatus lower,
    RelayStatus upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'status',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition>
      successfulConnectionsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'successfulConnections',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition>
      successfulConnectionsGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'successfulConnections',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition>
      successfulConnectionsLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'successfulConnections',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition>
      successfulConnectionsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'successfulConnections',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition>
      supportedNipsElementEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'supportedNips',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition>
      supportedNipsElementGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'supportedNips',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition>
      supportedNipsElementLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'supportedNips',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition>
      supportedNipsElementBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'supportedNips',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition>
      supportedNipsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'supportedNips',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition>
      supportedNipsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'supportedNips',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition>
      supportedNipsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'supportedNips',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition>
      supportedNipsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'supportedNips',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition>
      supportedNipsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'supportedNips',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition>
      supportedNipsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'supportedNips',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition> urlEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'url',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition> urlGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'url',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition> urlLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'url',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition> urlBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'url',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition> urlStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'url',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition> urlEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'url',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition> urlContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'url',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition> urlMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'url',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition> urlIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'url',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition>
      urlIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'url',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition>
      versionIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'version',
      ));
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition>
      versionIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'version',
      ));
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition> versionEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'version',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition>
      versionGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'version',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition> versionLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'version',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition> versionBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'version',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition>
      versionStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'version',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition> versionEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'version',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition> versionContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'version',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition> versionMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'version',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition>
      versionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'version',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition>
      versionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'version',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition>
      writePubkeysElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'writePubkeys',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition>
      writePubkeysElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'writePubkeys',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition>
      writePubkeysElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'writePubkeys',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition>
      writePubkeysElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'writePubkeys',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition>
      writePubkeysElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'writePubkeys',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition>
      writePubkeysElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'writePubkeys',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition>
      writePubkeysElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'writePubkeys',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition>
      writePubkeysElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'writePubkeys',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition>
      writePubkeysElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'writePubkeys',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition>
      writePubkeysElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'writePubkeys',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition>
      writePubkeysLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'writePubkeys',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition>
      writePubkeysIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'writePubkeys',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition>
      writePubkeysIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'writePubkeys',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition>
      writePubkeysLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'writePubkeys',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition>
      writePubkeysLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'writePubkeys',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterFilterCondition>
      writePubkeysLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'writePubkeys',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }
}

extension CachedRelayQueryObject
    on QueryBuilder<CachedRelay, CachedRelay, QFilterCondition> {}

extension CachedRelayQueryLinks
    on QueryBuilder<CachedRelay, CachedRelay, QFilterCondition> {}

extension CachedRelayQuerySortBy
    on QueryBuilder<CachedRelay, CachedRelay, QSortBy> {
  QueryBuilder<CachedRelay, CachedRelay, QAfterSortBy>
      sortByAverageResponseTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'averageResponseTime', Sort.asc);
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterSortBy>
      sortByAverageResponseTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'averageResponseTime', Sort.desc);
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterSortBy> sortByContact() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'contact', Sort.asc);
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterSortBy> sortByContactDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'contact', Sort.desc);
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterSortBy> sortByDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.asc);
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterSortBy> sortByDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.desc);
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterSortBy>
      sortByFailedConnections() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'failedConnections', Sort.asc);
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterSortBy>
      sortByFailedConnectionsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'failedConnections', Sort.desc);
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterSortBy> sortByFirstSeen() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'firstSeen', Sort.asc);
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterSortBy> sortByFirstSeenDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'firstSeen', Sort.desc);
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterSortBy> sortByIsHealthy() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isHealthy', Sort.asc);
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterSortBy> sortByIsHealthyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isHealthy', Sort.desc);
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterSortBy> sortByLastConnected() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastConnected', Sort.asc);
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterSortBy>
      sortByLastConnectedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastConnected', Sort.desc);
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterSortBy> sortByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterSortBy> sortByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterSortBy> sortByPubkey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pubkey', Sort.asc);
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterSortBy> sortByPubkeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pubkey', Sort.desc);
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterSortBy>
      sortByReliabilityScore() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reliabilityScore', Sort.asc);
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterSortBy>
      sortByReliabilityScoreDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reliabilityScore', Sort.desc);
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterSortBy> sortBySoftware() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'software', Sort.asc);
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterSortBy> sortBySoftwareDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'software', Sort.desc);
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterSortBy> sortByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterSortBy> sortByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterSortBy>
      sortBySuccessfulConnections() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'successfulConnections', Sort.asc);
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterSortBy>
      sortBySuccessfulConnectionsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'successfulConnections', Sort.desc);
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterSortBy> sortByUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'url', Sort.asc);
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterSortBy> sortByUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'url', Sort.desc);
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterSortBy> sortByVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'version', Sort.asc);
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterSortBy> sortByVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'version', Sort.desc);
    });
  }
}

extension CachedRelayQuerySortThenBy
    on QueryBuilder<CachedRelay, CachedRelay, QSortThenBy> {
  QueryBuilder<CachedRelay, CachedRelay, QAfterSortBy>
      thenByAverageResponseTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'averageResponseTime', Sort.asc);
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterSortBy>
      thenByAverageResponseTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'averageResponseTime', Sort.desc);
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterSortBy> thenByContact() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'contact', Sort.asc);
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterSortBy> thenByContactDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'contact', Sort.desc);
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterSortBy> thenByDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.asc);
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterSortBy> thenByDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.desc);
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterSortBy>
      thenByFailedConnections() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'failedConnections', Sort.asc);
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterSortBy>
      thenByFailedConnectionsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'failedConnections', Sort.desc);
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterSortBy> thenByFirstSeen() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'firstSeen', Sort.asc);
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterSortBy> thenByFirstSeenDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'firstSeen', Sort.desc);
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterSortBy> thenByIsHealthy() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isHealthy', Sort.asc);
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterSortBy> thenByIsHealthyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isHealthy', Sort.desc);
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterSortBy> thenByLastConnected() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastConnected', Sort.asc);
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterSortBy>
      thenByLastConnectedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastConnected', Sort.desc);
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterSortBy> thenByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterSortBy> thenByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterSortBy> thenByPubkey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pubkey', Sort.asc);
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterSortBy> thenByPubkeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pubkey', Sort.desc);
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterSortBy>
      thenByReliabilityScore() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reliabilityScore', Sort.asc);
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterSortBy>
      thenByReliabilityScoreDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reliabilityScore', Sort.desc);
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterSortBy> thenBySoftware() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'software', Sort.asc);
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterSortBy> thenBySoftwareDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'software', Sort.desc);
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterSortBy> thenByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterSortBy> thenByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterSortBy>
      thenBySuccessfulConnections() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'successfulConnections', Sort.asc);
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterSortBy>
      thenBySuccessfulConnectionsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'successfulConnections', Sort.desc);
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterSortBy> thenByUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'url', Sort.asc);
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterSortBy> thenByUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'url', Sort.desc);
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterSortBy> thenByVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'version', Sort.asc);
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QAfterSortBy> thenByVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'version', Sort.desc);
    });
  }
}

extension CachedRelayQueryWhereDistinct
    on QueryBuilder<CachedRelay, CachedRelay, QDistinct> {
  QueryBuilder<CachedRelay, CachedRelay, QDistinct>
      distinctByAverageResponseTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'averageResponseTime');
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QDistinct> distinctByContact(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'contact', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QDistinct> distinctByDescription(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'description', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QDistinct>
      distinctByFailedConnections() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'failedConnections');
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QDistinct> distinctByFirstSeen() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'firstSeen');
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QDistinct> distinctByIsHealthy() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isHealthy');
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QDistinct> distinctByLastConnected() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastConnected');
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QDistinct> distinctByName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'name', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QDistinct> distinctByPubkey(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'pubkey', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QDistinct> distinctByReadPubkeys() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'readPubkeys');
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QDistinct>
      distinctByReliabilityScore() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'reliabilityScore');
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QDistinct> distinctBySoftware(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'software', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QDistinct> distinctByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'status');
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QDistinct>
      distinctBySuccessfulConnections() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'successfulConnections');
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QDistinct> distinctBySupportedNips() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'supportedNips');
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QDistinct> distinctByUrl(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'url', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QDistinct> distinctByVersion(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'version', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CachedRelay, CachedRelay, QDistinct> distinctByWritePubkeys() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'writePubkeys');
    });
  }
}

extension CachedRelayQueryProperty
    on QueryBuilder<CachedRelay, CachedRelay, QQueryProperty> {
  QueryBuilder<CachedRelay, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<CachedRelay, double, QQueryOperations>
      averageResponseTimeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'averageResponseTime');
    });
  }

  QueryBuilder<CachedRelay, String?, QQueryOperations> contactProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'contact');
    });
  }

  QueryBuilder<CachedRelay, String?, QQueryOperations> descriptionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'description');
    });
  }

  QueryBuilder<CachedRelay, int, QQueryOperations> failedConnectionsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'failedConnections');
    });
  }

  QueryBuilder<CachedRelay, DateTime, QQueryOperations> firstSeenProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'firstSeen');
    });
  }

  QueryBuilder<CachedRelay, bool, QQueryOperations> isHealthyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isHealthy');
    });
  }

  QueryBuilder<CachedRelay, DateTime, QQueryOperations>
      lastConnectedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastConnected');
    });
  }

  QueryBuilder<CachedRelay, String?, QQueryOperations> nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'name');
    });
  }

  QueryBuilder<CachedRelay, String?, QQueryOperations> pubkeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'pubkey');
    });
  }

  QueryBuilder<CachedRelay, List<String>, QQueryOperations>
      readPubkeysProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'readPubkeys');
    });
  }

  QueryBuilder<CachedRelay, int, QQueryOperations> reliabilityScoreProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'reliabilityScore');
    });
  }

  QueryBuilder<CachedRelay, String?, QQueryOperations> softwareProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'software');
    });
  }

  QueryBuilder<CachedRelay, RelayStatus, QQueryOperations> statusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'status');
    });
  }

  QueryBuilder<CachedRelay, int, QQueryOperations>
      successfulConnectionsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'successfulConnections');
    });
  }

  QueryBuilder<CachedRelay, List<int>, QQueryOperations>
      supportedNipsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'supportedNips');
    });
  }

  QueryBuilder<CachedRelay, String, QQueryOperations> urlProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'url');
    });
  }

  QueryBuilder<CachedRelay, String?, QQueryOperations> versionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'version');
    });
  }

  QueryBuilder<CachedRelay, List<String>, QQueryOperations>
      writePubkeysProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'writePubkeys');
    });
  }
}
