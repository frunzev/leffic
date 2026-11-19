import 'dart:io';

const int _anyPort = 0;

Future<int> findFreeLoopbackPort() async {
  final probe = await ServerSocket.bind(InternetAddress.loopbackIPv4, _anyPort);
  final port = probe.port;

  await probe.close();

  return port;
}
