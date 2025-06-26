// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cached_profile.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetCachedProfileCollection on Isar {
  IsarCollection<CachedProfile> get cachedProfiles => this.collection();
}

const CachedProfileSchema = CollectionSchema(
  name: r'CachedProfile',
  id: -3272954809300854847,
  properties: {
    r'about': PropertySchema(
      id: 0,
      name: r'about',
      type: IsarType.string,
    ),
    r'banner': PropertySchema(
      id: 1,
      name: r'banner',
      type: IsarType.string,
    ),
    r'createdAt': PropertySchema(
      id: 2,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'displayName': PropertySchema(
      id: 3,
      name: r'displayName',
      type: IsarType.string,
    ),
    r'failedImageUrls': PropertySchema(
      id: 4,
      name: r'failedImageUrls',
      type: IsarType.stringList,
    ),
    r'isStale': PropertySchema(
      id: 5,
      name: r'isStale',
      type: IsarType.bool,
    ),
    r'lastUpdated': PropertySchema(
      id: 6,
      name: r'lastUpdated',
      type: IsarType.dateTime,
    ),
    r'lud16': PropertySchema(
      id: 7,
      name: r'lud16',
      type: IsarType.string,
    ),
    r'name': PropertySchema(
      id: 8,
      name: r'name',
      type: IsarType.string,
    ),
    r'nip05': PropertySchema(
      id: 9,
      name: r'nip05',
      type: IsarType.string,
    ),
    r'picture': PropertySchema(
      id: 10,
      name: r'picture',
      type: IsarType.string,
    ),
    r'pubkey': PropertySchema(
      id: 11,
      name: r'pubkey',
      type: IsarType.string,
    ),
    r'website': PropertySchema(
      id: 12,
      name: r'website',
      type: IsarType.string,
    )
  },
  estimateSize: _cachedProfileEstimateSize,
  serialize: _cachedProfileSerialize,
  deserialize: _cachedProfileDeserialize,
  deserializeProp: _cachedProfileDeserializeProp,
  idName: r'id',
  indexes: {
    r'pubkey': IndexSchema(
      id: -5440107494565194882,
      name: r'pubkey',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'pubkey',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'lastUpdated': IndexSchema(
      id: 8989359681631629925,
      name: r'lastUpdated',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'lastUpdated',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _cachedProfileGetId,
  getLinks: _cachedProfileGetLinks,
  attach: _cachedProfileAttach,
  version: '3.1.0+1',
);

int _cachedProfileEstimateSize(
  CachedProfile object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.about;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.banner;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.displayName;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.failedImageUrls.length * 3;
  {
    for (var i = 0; i < object.failedImageUrls.length; i++) {
      final value = object.failedImageUrls[i];
      bytesCount += value.length * 3;
    }
  }
  {
    final value = object.lud16;
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
    final value = object.nip05;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.picture;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.pubkey.length * 3;
  {
    final value = object.website;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _cachedProfileSerialize(
  CachedProfile object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.about);
  writer.writeString(offsets[1], object.banner);
  writer.writeDateTime(offsets[2], object.createdAt);
  writer.writeString(offsets[3], object.displayName);
  writer.writeStringList(offsets[4], object.failedImageUrls);
  writer.writeBool(offsets[5], object.isStale);
  writer.writeDateTime(offsets[6], object.lastUpdated);
  writer.writeString(offsets[7], object.lud16);
  writer.writeString(offsets[8], object.name);
  writer.writeString(offsets[9], object.nip05);
  writer.writeString(offsets[10], object.picture);
  writer.writeString(offsets[11], object.pubkey);
  writer.writeString(offsets[12], object.website);
}

CachedProfile _cachedProfileDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = CachedProfile();
  object.about = reader.readStringOrNull(offsets[0]);
  object.banner = reader.readStringOrNull(offsets[1]);
  object.createdAt = reader.readDateTime(offsets[2]);
  object.displayName = reader.readStringOrNull(offsets[3]);
  object.failedImageUrls = reader.readStringList(offsets[4]) ?? [];
  object.id = id;
  object.lastUpdated = reader.readDateTime(offsets[6]);
  object.lud16 = reader.readStringOrNull(offsets[7]);
  object.name = reader.readStringOrNull(offsets[8]);
  object.nip05 = reader.readStringOrNull(offsets[9]);
  object.picture = reader.readStringOrNull(offsets[10]);
  object.pubkey = reader.readString(offsets[11]);
  object.website = reader.readStringOrNull(offsets[12]);
  return object;
}

P _cachedProfileDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (reader.readDateTime(offset)) as P;
    case 3:
      return (reader.readStringOrNull(offset)) as P;
    case 4:
      return (reader.readStringList(offset) ?? []) as P;
    case 5:
      return (reader.readBool(offset)) as P;
    case 6:
      return (reader.readDateTime(offset)) as P;
    case 7:
      return (reader.readStringOrNull(offset)) as P;
    case 8:
      return (reader.readStringOrNull(offset)) as P;
    case 9:
      return (reader.readStringOrNull(offset)) as P;
    case 10:
      return (reader.readStringOrNull(offset)) as P;
    case 11:
      return (reader.readString(offset)) as P;
    case 12:
      return (reader.readStringOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _cachedProfileGetId(CachedProfile object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _cachedProfileGetLinks(CachedProfile object) {
  return [];
}

void _cachedProfileAttach(
    IsarCollection<dynamic> col, Id id, CachedProfile object) {
  object.id = id;
}

extension CachedProfileByIndex on IsarCollection<CachedProfile> {
  Future<CachedProfile?> getByPubkey(String pubkey) {
    return getByIndex(r'pubkey', [pubkey]);
  }

  CachedProfile? getByPubkeySync(String pubkey) {
    return getByIndexSync(r'pubkey', [pubkey]);
  }

  Future<bool> deleteByPubkey(String pubkey) {
    return deleteByIndex(r'pubkey', [pubkey]);
  }

  bool deleteByPubkeySync(String pubkey) {
    return deleteByIndexSync(r'pubkey', [pubkey]);
  }

  Future<List<CachedProfile?>> getAllByPubkey(List<String> pubkeyValues) {
    final values = pubkeyValues.map((e) => [e]).toList();
    return getAllByIndex(r'pubkey', values);
  }

  List<CachedProfile?> getAllByPubkeySync(List<String> pubkeyValues) {
    final values = pubkeyValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'pubkey', values);
  }

  Future<int> deleteAllByPubkey(List<String> pubkeyValues) {
    final values = pubkeyValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'pubkey', values);
  }

  int deleteAllByPubkeySync(List<String> pubkeyValues) {
    final values = pubkeyValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'pubkey', values);
  }

  Future<Id> putByPubkey(CachedProfile object) {
    return putByIndex(r'pubkey', object);
  }

  Id putByPubkeySync(CachedProfile object, {bool saveLinks = true}) {
    return putByIndexSync(r'pubkey', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByPubkey(List<CachedProfile> objects) {
    return putAllByIndex(r'pubkey', objects);
  }

  List<Id> putAllByPubkeySync(List<CachedProfile> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'pubkey', objects, saveLinks: saveLinks);
  }
}

extension CachedProfileQueryWhereSort
    on QueryBuilder<CachedProfile, CachedProfile, QWhere> {
  QueryBuilder<CachedProfile, CachedProfile, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterWhere> anyLastUpdated() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'lastUpdated'),
      );
    });
  }
}

extension CachedProfileQueryWhere
    on QueryBuilder<CachedProfile, CachedProfile, QWhereClause> {
  QueryBuilder<CachedProfile, CachedProfile, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterWhereClause> idNotEqualTo(
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

  QueryBuilder<CachedProfile, CachedProfile, QAfterWhereClause> idGreaterThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterWhereClause> idBetween(
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

  QueryBuilder<CachedProfile, CachedProfile, QAfterWhereClause> pubkeyEqualTo(
      String pubkey) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'pubkey',
        value: [pubkey],
      ));
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterWhereClause>
      pubkeyNotEqualTo(String pubkey) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'pubkey',
              lower: [],
              upper: [pubkey],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'pubkey',
              lower: [pubkey],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'pubkey',
              lower: [pubkey],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'pubkey',
              lower: [],
              upper: [pubkey],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterWhereClause>
      lastUpdatedEqualTo(DateTime lastUpdated) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'lastUpdated',
        value: [lastUpdated],
      ));
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterWhereClause>
      lastUpdatedNotEqualTo(DateTime lastUpdated) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'lastUpdated',
              lower: [],
              upper: [lastUpdated],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'lastUpdated',
              lower: [lastUpdated],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'lastUpdated',
              lower: [lastUpdated],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'lastUpdated',
              lower: [],
              upper: [lastUpdated],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterWhereClause>
      lastUpdatedGreaterThan(
    DateTime lastUpdated, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'lastUpdated',
        lower: [lastUpdated],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterWhereClause>
      lastUpdatedLessThan(
    DateTime lastUpdated, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'lastUpdated',
        lower: [],
        upper: [lastUpdated],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterWhereClause>
      lastUpdatedBetween(
    DateTime lowerLastUpdated,
    DateTime upperLastUpdated, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'lastUpdated',
        lower: [lowerLastUpdated],
        includeLower: includeLower,
        upper: [upperLastUpdated],
        includeUpper: includeUpper,
      ));
    });
  }
}

extension CachedProfileQueryFilter
    on QueryBuilder<CachedProfile, CachedProfile, QFilterCondition> {
  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
      aboutIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'about',
      ));
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
      aboutIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'about',
      ));
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
      aboutEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'about',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
      aboutGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'about',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
      aboutLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'about',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
      aboutBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'about',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
      aboutStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'about',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
      aboutEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'about',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
      aboutContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'about',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
      aboutMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'about',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
      aboutIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'about',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
      aboutIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'about',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
      bannerIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'banner',
      ));
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
      bannerIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'banner',
      ));
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
      bannerEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'banner',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
      bannerGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'banner',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
      bannerLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'banner',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
      bannerBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'banner',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
      bannerStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'banner',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
      bannerEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'banner',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
      bannerContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'banner',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
      bannerMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'banner',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
      bannerIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'banner',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
      bannerIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'banner',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
      createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
      createdAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
      createdAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
      createdAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'createdAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
      displayNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'displayName',
      ));
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
      displayNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'displayName',
      ));
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
      displayNameEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'displayName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
      displayNameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'displayName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
      displayNameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'displayName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
      displayNameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'displayName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
      displayNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'displayName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
      displayNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'displayName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
      displayNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'displayName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
      displayNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'displayName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
      displayNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'displayName',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
      displayNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'displayName',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
      failedImageUrlsElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'failedImageUrls',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
      failedImageUrlsElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'failedImageUrls',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
      failedImageUrlsElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'failedImageUrls',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
      failedImageUrlsElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'failedImageUrls',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
      failedImageUrlsElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'failedImageUrls',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
      failedImageUrlsElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'failedImageUrls',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
      failedImageUrlsElementContains(String value,
          {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'failedImageUrls',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
      failedImageUrlsElementMatches(String pattern,
          {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'failedImageUrls',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
      failedImageUrlsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'failedImageUrls',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
      failedImageUrlsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'failedImageUrls',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
      failedImageUrlsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'failedImageUrls',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
      failedImageUrlsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'failedImageUrls',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
      failedImageUrlsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'failedImageUrls',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
      failedImageUrlsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'failedImageUrls',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
      failedImageUrlsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'failedImageUrls',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
      failedImageUrlsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'failedImageUrls',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
      idGreaterThan(
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

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition> idBetween(
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

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
      isStaleEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isStale',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
      lastUpdatedEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastUpdated',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
      lastUpdatedGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lastUpdated',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
      lastUpdatedLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lastUpdated',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
      lastUpdatedBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lastUpdated',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
      lud16IsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'lud16',
      ));
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
      lud16IsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'lud16',
      ));
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
      lud16EqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lud16',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
      lud16GreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lud16',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
      lud16LessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lud16',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
      lud16Between(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lud16',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
      lud16StartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'lud16',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
      lud16EndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'lud16',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
      lud16Contains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'lud16',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
      lud16Matches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'lud16',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
      lud16IsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lud16',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
      lud16IsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'lud16',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
      nameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'name',
      ));
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
      nameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'name',
      ));
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition> nameEqualTo(
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

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
      nameGreaterThan(
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

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
      nameLessThan(
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

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition> nameBetween(
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

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
      nameStartsWith(
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

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
      nameEndsWith(
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

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
      nameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition> nameMatches(
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

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
      nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
      nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
      nip05IsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'nip05',
      ));
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
      nip05IsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'nip05',
      ));
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
      nip05EqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'nip05',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
      nip05GreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'nip05',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
      nip05LessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'nip05',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
      nip05Between(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'nip05',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
      nip05StartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'nip05',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
      nip05EndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'nip05',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
      nip05Contains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'nip05',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
      nip05Matches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'nip05',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
      nip05IsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'nip05',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
      nip05IsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'nip05',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
      pictureIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'picture',
      ));
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
      pictureIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'picture',
      ));
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
      pictureEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'picture',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
      pictureGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'picture',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
      pictureLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'picture',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
      pictureBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'picture',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
      pictureStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'picture',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
      pictureEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'picture',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
      pictureContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'picture',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
      pictureMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'picture',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
      pictureIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'picture',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
      pictureIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'picture',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
      pubkeyEqualTo(
    String value, {
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

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
      pubkeyGreaterThan(
    String value, {
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

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
      pubkeyLessThan(
    String value, {
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

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
      pubkeyBetween(
    String lower,
    String upper, {
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

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
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

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
      pubkeyEndsWith(
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

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
      pubkeyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'pubkey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
      pubkeyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'pubkey',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
      pubkeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'pubkey',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
      pubkeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'pubkey',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
      websiteIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'website',
      ));
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
      websiteIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'website',
      ));
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
      websiteEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'website',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
      websiteGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'website',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
      websiteLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'website',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
      websiteBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'website',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
      websiteStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'website',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
      websiteEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'website',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
      websiteContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'website',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
      websiteMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'website',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
      websiteIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'website',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterFilterCondition>
      websiteIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'website',
        value: '',
      ));
    });
  }
}

extension CachedProfileQueryObject
    on QueryBuilder<CachedProfile, CachedProfile, QFilterCondition> {}

extension CachedProfileQueryLinks
    on QueryBuilder<CachedProfile, CachedProfile, QFilterCondition> {}

extension CachedProfileQuerySortBy
    on QueryBuilder<CachedProfile, CachedProfile, QSortBy> {
  QueryBuilder<CachedProfile, CachedProfile, QAfterSortBy> sortByAbout() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'about', Sort.asc);
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterSortBy> sortByAboutDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'about', Sort.desc);
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterSortBy> sortByBanner() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'banner', Sort.asc);
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterSortBy> sortByBannerDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'banner', Sort.desc);
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterSortBy> sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterSortBy>
      sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterSortBy> sortByDisplayName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'displayName', Sort.asc);
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterSortBy>
      sortByDisplayNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'displayName', Sort.desc);
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterSortBy> sortByIsStale() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isStale', Sort.asc);
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterSortBy> sortByIsStaleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isStale', Sort.desc);
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterSortBy> sortByLastUpdated() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUpdated', Sort.asc);
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterSortBy>
      sortByLastUpdatedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUpdated', Sort.desc);
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterSortBy> sortByLud16() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lud16', Sort.asc);
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterSortBy> sortByLud16Desc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lud16', Sort.desc);
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterSortBy> sortByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterSortBy> sortByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterSortBy> sortByNip05() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nip05', Sort.asc);
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterSortBy> sortByNip05Desc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nip05', Sort.desc);
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterSortBy> sortByPicture() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'picture', Sort.asc);
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterSortBy> sortByPictureDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'picture', Sort.desc);
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterSortBy> sortByPubkey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pubkey', Sort.asc);
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterSortBy> sortByPubkeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pubkey', Sort.desc);
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterSortBy> sortByWebsite() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'website', Sort.asc);
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterSortBy> sortByWebsiteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'website', Sort.desc);
    });
  }
}

extension CachedProfileQuerySortThenBy
    on QueryBuilder<CachedProfile, CachedProfile, QSortThenBy> {
  QueryBuilder<CachedProfile, CachedProfile, QAfterSortBy> thenByAbout() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'about', Sort.asc);
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterSortBy> thenByAboutDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'about', Sort.desc);
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterSortBy> thenByBanner() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'banner', Sort.asc);
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterSortBy> thenByBannerDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'banner', Sort.desc);
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterSortBy> thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterSortBy>
      thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterSortBy> thenByDisplayName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'displayName', Sort.asc);
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterSortBy>
      thenByDisplayNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'displayName', Sort.desc);
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterSortBy> thenByIsStale() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isStale', Sort.asc);
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterSortBy> thenByIsStaleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isStale', Sort.desc);
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterSortBy> thenByLastUpdated() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUpdated', Sort.asc);
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterSortBy>
      thenByLastUpdatedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUpdated', Sort.desc);
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterSortBy> thenByLud16() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lud16', Sort.asc);
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterSortBy> thenByLud16Desc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lud16', Sort.desc);
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterSortBy> thenByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterSortBy> thenByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterSortBy> thenByNip05() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nip05', Sort.asc);
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterSortBy> thenByNip05Desc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nip05', Sort.desc);
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterSortBy> thenByPicture() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'picture', Sort.asc);
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterSortBy> thenByPictureDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'picture', Sort.desc);
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterSortBy> thenByPubkey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pubkey', Sort.asc);
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterSortBy> thenByPubkeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pubkey', Sort.desc);
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterSortBy> thenByWebsite() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'website', Sort.asc);
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QAfterSortBy> thenByWebsiteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'website', Sort.desc);
    });
  }
}

extension CachedProfileQueryWhereDistinct
    on QueryBuilder<CachedProfile, CachedProfile, QDistinct> {
  QueryBuilder<CachedProfile, CachedProfile, QDistinct> distinctByAbout(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'about', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QDistinct> distinctByBanner(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'banner', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QDistinct> distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QDistinct> distinctByDisplayName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'displayName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QDistinct>
      distinctByFailedImageUrls() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'failedImageUrls');
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QDistinct> distinctByIsStale() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isStale');
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QDistinct>
      distinctByLastUpdated() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastUpdated');
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QDistinct> distinctByLud16(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lud16', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QDistinct> distinctByName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'name', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QDistinct> distinctByNip05(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'nip05', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QDistinct> distinctByPicture(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'picture', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QDistinct> distinctByPubkey(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'pubkey', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CachedProfile, CachedProfile, QDistinct> distinctByWebsite(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'website', caseSensitive: caseSensitive);
    });
  }
}

extension CachedProfileQueryProperty
    on QueryBuilder<CachedProfile, CachedProfile, QQueryProperty> {
  QueryBuilder<CachedProfile, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<CachedProfile, String?, QQueryOperations> aboutProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'about');
    });
  }

  QueryBuilder<CachedProfile, String?, QQueryOperations> bannerProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'banner');
    });
  }

  QueryBuilder<CachedProfile, DateTime, QQueryOperations> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<CachedProfile, String?, QQueryOperations> displayNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'displayName');
    });
  }

  QueryBuilder<CachedProfile, List<String>, QQueryOperations>
      failedImageUrlsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'failedImageUrls');
    });
  }

  QueryBuilder<CachedProfile, bool, QQueryOperations> isStaleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isStale');
    });
  }

  QueryBuilder<CachedProfile, DateTime, QQueryOperations>
      lastUpdatedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastUpdated');
    });
  }

  QueryBuilder<CachedProfile, String?, QQueryOperations> lud16Property() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lud16');
    });
  }

  QueryBuilder<CachedProfile, String?, QQueryOperations> nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'name');
    });
  }

  QueryBuilder<CachedProfile, String?, QQueryOperations> nip05Property() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'nip05');
    });
  }

  QueryBuilder<CachedProfile, String?, QQueryOperations> pictureProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'picture');
    });
  }

  QueryBuilder<CachedProfile, String, QQueryOperations> pubkeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'pubkey');
    });
  }

  QueryBuilder<CachedProfile, String?, QQueryOperations> websiteProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'website');
    });
  }
}
