import 'package:flutter_test/flutter_test.dart';
import 'package:izi_kiosco/data/monitoring/monitoring_commands.dart';
import 'package:izi_kiosco/data/telemetry/telemetry.dart';
import 'package:izi_kiosco/domain/models/monitoring_heartbeat_response.dart';

void main() {
  late DateTime now;
  late PendingCommandQueue queue;

  MonitoringCommand command(String id, {Duration expiresIn = const Duration(minutes: 10)}) =>
      MonitoringCommand(id: id, type: 'reload_app', expiresAt: now.add(expiresIn));

  setUp(() {
    now = DateTime.utc(2026, 10, 12, 14);
    queue = PendingCommandQueue(now: () => now);
    Telemetry.install(Telemetry());
  });

  test('keeps each command once, and logs it once', () {
    queue.enqueue([command('c1')]);
    queue.enqueue([command('c1'), command('c2')]);
    expect(queue.pending.map((c) => c.id), ['c1', 'c2']);
    expect(Telemetry.recent().where((e) => e.type == 'monitoring.command_received'), hasLength(2));
  });

  test('drops what expired, and never takes an expired one', () {
    queue.enqueue([command('c1', expiresIn: const Duration(minutes: 1)), command('c2')]);
    queue.enqueue([command('old', expiresIn: Duration.zero)]);
    now = now.add(const Duration(minutes: 2));
    expect(queue.pending.map((c) => c.id), ['c2']);
  });

  test('keeps at most the latest 20', () {
    queue.enqueue([for (var i = 0; i < 25; i++) command('c$i')]);
    expect(queue.pending, hasLength(PendingCommandQueue.capacity));
    expect(queue.pending.first.id, 'c5');
  });

  test('the executor takes a command out', () {
    queue.enqueue([command('c1')]);
    expect(queue.take('c1')?.id, 'c1');
    expect(queue.pending, isEmpty);
    expect(queue.take('c1'), isNull);
  });
}
