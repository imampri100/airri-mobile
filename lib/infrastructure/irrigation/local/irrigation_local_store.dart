import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'package:airri_mobile/domain/irrigation/entities.dart';
import 'package:airri_mobile/domain/irrigation/i_irrigation_local_store.dart';

// Implementasi IIrrigationLocalStore memakai SQLite (sqflite).
// Menyimpan log sensor & irigasi yang sudah disinkron dari device,
// rentang gap yang terdeteksi, dan storageId device terakhir yang
// diketahui. Detailnya ada di storage.md bagian "Deteksi gap dari sisi
// mobile app".
class IrrigationLocalStore implements IIrrigationLocalStore {
  static const _dbName = 'irrigation_logs.db';
  static const _dbVersion = 1;

  Database? _db;

  Future<Database> get _database async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dir = await getDatabasesPath();
    final path = p.join(dir, _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE sensor_logs (
            id INTEGER PRIMARY KEY,
            createdAt INTEGER,
            soilMoisture REAL,
            airHumidity REAL,
            airTemperature REAL,
            lightIntensity REAL,
            isIrrigationRun INTEGER
          )
        ''');
        await db.execute('''
          CREATE TABLE irrigation_logs (
            id INTEGER PRIMARY KEY,
            createdAt INTEGER,
            runAt INTEGER,
            stopAt INTEGER,
            durationSecond INTEGER,
            milliliter REAL
          )
        ''');
        await db.execute('''
          CREATE TABLE sync_gaps (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            logType TEXT NOT NULL,
            fromId INTEGER NOT NULL,
            toId INTEGER NOT NULL,
            anchorAt INTEGER
          )
        ''');
        await db.execute('''
          CREATE TABLE kv (
            key TEXT PRIMARY KEY,
            value TEXT
          )
        ''');
        // Index createdAt supaya query filter tanggal di History date
        // picker tetap cepat walau sudah puluhan ribu baris.
        await db.execute(
            'CREATE INDEX idx_sensor_logs_createdAt ON sensor_logs(createdAt)');
        await db.execute(
            'CREATE INDEX idx_irrigation_logs_createdAt ON irrigation_logs(createdAt)');
      },
    );
  }

  // ---------- sensor logs ----------

  @override
  Future<int> maxSensorLogId() async {
    final db = await _database;
    final rows = await db.rawQuery('SELECT MAX(id) AS m FROM sensor_logs');
    return (rows.first['m'] as int?) ?? 0;
  }

  @override
  Future<void> insertSensorLogs(List<SensorLogEntry> logs) async {
    if (logs.isEmpty) return;
    final db = await _database;
    final batch = db.batch();
    for (final e in logs) {
      batch.insert(
        'sensor_logs',
        {
          'id': e.id,
          'createdAt': e.createdAt?.millisecondsSinceEpoch,
          'soilMoisture': e.reading.soilMoisture,
          'airHumidity': e.reading.airHumidity,
          'airTemperature': e.reading.airTemperature,
          'lightIntensity': e.reading.lightIntensity,
          'isIrrigationRun': e.isIrrigationRun ? 1 : 0,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  @override
  Future<List<SensorLogEntry>> sensorLogs({
    int limit = 100,
    DateTime? from,
    DateTime? to,
  }) async {
    final db = await _database;
    final rows = from == null && to == null
        ? await db.query('sensor_logs', orderBy: 'id DESC', limit: limit)
        : await db.query(
            'sensor_logs',
            where: 'createdAt >= ? AND createdAt <= ?',
            whereArgs: [
              from?.millisecondsSinceEpoch ?? 0,
              to?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch,
            ],
            orderBy: 'id DESC',
          );
    return rows.map(_sensorLogFromRow).toList();
  }

  SensorLogEntry _sensorLogFromRow(Map<String, Object?> row) {
    return SensorLogEntry(
      id: row['id'] as int,
      createdAt: row['createdAt'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(row['createdAt'] as int),
      reading: SensorReading(
        soilMoisture: (row['soilMoisture'] as num).toDouble(),
        airHumidity: (row['airHumidity'] as num).toDouble(),
        airTemperature: (row['airTemperature'] as num).toDouble(),
        lightIntensity: (row['lightIntensity'] as num).toDouble(),
      ),
      isIrrigationRun: (row['isIrrigationRun'] as int) == 1,
    );
  }

  // ---------- irrigation logs ----------

  @override
  Future<int> maxIrrigationLogId() async {
    final db = await _database;
    final rows =
        await db.rawQuery('SELECT MAX(id) AS m FROM irrigation_logs');
    return (rows.first['m'] as int?) ?? 0;
  }

  @override
  Future<void> insertIrrigationLogs(List<IrrigationLogEntry> logs) async {
    if (logs.isEmpty) return;
    final db = await _database;
    final batch = db.batch();
    for (final e in logs) {
      batch.insert(
        'irrigation_logs',
        {
          'id': e.id,
          'createdAt': e.createdAt?.millisecondsSinceEpoch,
          'runAt': e.runAt?.millisecondsSinceEpoch,
          'stopAt': e.stopAt?.millisecondsSinceEpoch,
          'durationSecond': e.durationSecond,
          'milliliter': e.milliliter,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  @override
  Future<List<IrrigationLogEntry>> irrigationLogs({
    int limit = 100,
    DateTime? from,
    DateTime? to,
  }) async {
    final db = await _database;
    final rows = from == null && to == null
        ? await db.query('irrigation_logs', orderBy: 'id DESC', limit: limit)
        : await db.query(
            'irrigation_logs',
            where: 'createdAt >= ? AND createdAt <= ?',
            whereArgs: [
              from?.millisecondsSinceEpoch ?? 0,
              to?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch,
            ],
            orderBy: 'id DESC',
          );
    return rows.map(_irrigationLogFromRow).toList();
  }

  IrrigationLogEntry _irrigationLogFromRow(Map<String, Object?> row) {
    return IrrigationLogEntry(
      id: row['id'] as int,
      createdAt: row['createdAt'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(row['createdAt'] as int),
      runAt: row['runAt'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(row['runAt'] as int),
      stopAt: row['stopAt'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(row['stopAt'] as int),
      durationSecond: row['durationSecond'] as int,
      milliliter: (row['milliliter'] as num).toDouble(),
    );
  }

  // ---------- statistik ----------

  // Ekspresi SQL untuk kunci grouping bucket sesuai granularitas. Aman
  // diinterpolasi langsung karena hanya dibangun dari enum tetap, bukan
  // dari input user.
  String _bucketKeyExpr(StatsGranularity g) => switch (g) {
        StatsGranularity.day =>
          "date(createdAt/1000, 'unixepoch', 'localtime')",
        StatsGranularity.week =>
          "strftime('%Y-%W', createdAt/1000, 'unixepoch', 'localtime')",
        StatsGranularity.month =>
          "strftime('%Y-%m', createdAt/1000, 'unixepoch', 'localtime')",
      };

  @override
  Future<List<DailyStat>> dailyStats({
    required DateTime from,
    required DateTime to,
    required StatsGranularity granularity,
  }) async {
    final db = await _database;
    final fromMs = from.millisecondsSinceEpoch;
    final toMs = to.millisecondsSinceEpoch;
    final bucketKeyExpr = _bucketKeyExpr(granularity);

    final soilRows = await db.rawQuery('''
      SELECT $bucketKeyExpr AS bucketKey,
             MIN(date(createdAt/1000, 'unixepoch', 'localtime')) AS bucketDate,
             AVG(soilMoisture) AS avgSoil
      FROM sensor_logs
      WHERE createdAt >= ? AND createdAt <= ?
      GROUP BY bucketKey
    ''', [fromMs, toMs]);

    final irrigationRows = await db.rawQuery('''
      SELECT $bucketKeyExpr AS bucketKey,
             MIN(date(createdAt/1000, 'unixepoch', 'localtime')) AS bucketDate,
             SUM(milliliter) AS totalMl,
             COUNT(*) AS cnt
      FROM irrigation_logs
      WHERE createdAt >= ? AND createdAt <= ?
      GROUP BY bucketKey
    ''', [fromMs, toMs]);

    final byBucket = <String,
        ({String date, double avgSoil, double totalMl, int cnt})>{};
    for (final row in soilRows) {
      final key = row['bucketKey'] as String;
      byBucket[key] = (
        date: row['bucketDate'] as String,
        avgSoil: (row['avgSoil'] as num?)?.toDouble() ?? 0,
        totalMl: byBucket[key]?.totalMl ?? 0,
        cnt: byBucket[key]?.cnt ?? 0,
      );
    }
    for (final row in irrigationRows) {
      final key = row['bucketKey'] as String;
      byBucket[key] = (
        date: byBucket[key]?.date ?? row['bucketDate'] as String,
        avgSoil: byBucket[key]?.avgSoil ?? 0,
        totalMl: (row['totalMl'] as num?)?.toDouble() ?? 0,
        cnt: (row['cnt'] as int?) ?? 0,
      );
    }

    final keys = byBucket.keys.toList()..sort();
    return keys
        .map((key) => DailyStat(
              date: DateTime.parse(byBucket[key]!.date),
              avgSoilMoisture: byBucket[key]!.avgSoil,
              totalWaterMl: byBucket[key]!.totalMl,
              irrigationCount: byBucket[key]!.cnt,
            ))
        .toList();
  }

  @override
  Future<StatisticsSummary> periodSummary({
    required DateTime from,
    required DateTime to,
  }) async {
    final db = await _database;
    final fromMs = from.millisecondsSinceEpoch;
    final toMs = to.millisecondsSinceEpoch;

    final soilRows = await db.rawQuery(
      'SELECT AVG(soilMoisture) AS avgSoil FROM sensor_logs WHERE createdAt >= ? AND createdAt <= ?',
      [fromMs, toMs],
    );
    final irrigationRows = await db.rawQuery(
      'SELECT SUM(milliliter) AS totalMl, COUNT(*) AS cnt FROM irrigation_logs WHERE createdAt >= ? AND createdAt <= ?',
      [fromMs, toMs],
    );

    return StatisticsSummary(
      avgSoilMoisture: (soilRows.first['avgSoil'] as num?)?.toDouble() ?? 0,
      totalWaterMl: (irrigationRows.first['totalMl'] as num?)?.toDouble() ?? 0,
      irrigationCount: (irrigationRows.first['cnt'] as int?) ?? 0,
    );
  }

  // ---------- gaps ----------

  @override
  Future<void> recordGap(SyncGap gap) async {
    final db = await _database;
    await db.insert('sync_gaps', {
      'logType': gap.logType,
      'fromId': gap.fromId,
      'toId': gap.toId,
      'anchorAt': gap.anchorAt?.millisecondsSinceEpoch,
    });
  }

  @override
  Future<List<SyncGap>> gaps({String? logType}) async {
    final db = await _database;
    final rows = await db.query(
      'sync_gaps',
      where: logType == null ? null : 'logType = ?',
      whereArgs: logType == null ? null : [logType],
      orderBy: 'toId DESC',
    );
    return rows
        .map((row) => SyncGap(
              logType: row['logType'] as String,
              fromId: row['fromId'] as int,
              toId: row['toId'] as int,
              anchorAt: row['anchorAt'] == null
                  ? null
                  : DateTime.fromMillisecondsSinceEpoch(
                      row['anchorAt'] as int),
            ))
        .toList();
  }

  // ---------- storage identity ----------

  @override
  Future<String?> getStorageId() async {
    final db = await _database;
    final rows =
        await db.query('kv', where: 'key = ?', whereArgs: ['storageId']);
    return rows.isEmpty ? null : rows.first['value'] as String?;
  }

  @override
  Future<void> setStorageId(String value) async {
    final db = await _database;
    await db.insert('kv', {'key': 'storageId', 'value': value},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<void> clearAll() async {
    final db = await _database;
    final batch = db.batch();
    batch.delete('sensor_logs');
    batch.delete('irrigation_logs');
    batch.delete('sync_gaps');
    batch.delete('kv');
    await batch.commit(noResult: true);
  }
}
