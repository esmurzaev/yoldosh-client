class Configs {
  const Configs._();

  static const appTitle = 'YOLDOSH';
  static const appVersion = '1.0.0';

  static const serviceHost = '34.91.24.28'; //'192.168.1.33'; // 89.236.213.235
  static const clientPort = 60001;
  static const driverPort = 60002;

  static const seatPrice = 1400;
  static const tariffs = <String>['0', '100', '200', '300', '400', '500'];

  static const masterCode = [0x2D, 0x08, 0x2E, 0x4C, 0xD3, 0x33, 0x93, 0x01]; // Int64(0x2D082E4CD3339301);
  static const masterKey = [
    0xF1,
    0xE5,
    0xB8,
    0x27,
    0xDF,
    0x61,
    0x39,
    0x27,
    0x11,
    0x4B,
    0x31,
    0x7A,
    0x2A,
    0x91,
    0xCE,
    0x79
  ];
}
