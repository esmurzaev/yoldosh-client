class TypeConvert {
  TypeConvert._();

  // ------------------------------------------------------------
  // For 16 bit types

  // To BigEndian bytes
  static List<int> int16ToBytes(int value) {
    List<int> result = List<int>(2);
    result[0] = (value >> 8) & 0xff;
    result[1] = value & 0xff;
    return result;
  }
  /*
  // From BigEndian bytes
  static int bytesToInt16(List<int> value) {
    return value[1] | value[0] << 8;
  }
  */

  // ------------------------------------------------------------
  // For 32 bit types

  // To BigEndian bytes
  static List<int> int32ToBytes(int value) {
    List<int> result = List<int>(4);
    result[0] = (value >> 24) & 0xff;
    result[1] = (value >> 16) & 0xff;
    result[2] = (value >> 8) & 0xff;
    result[3] = value & 0xff;
    return result;
  }
  /*
  // From BigEndian bytes
  static int bytesToInt32(List<int> value) {
    return value[3] | value[2] << 8 | value[1] << 16 | value[0] << 24;
  }
  */

  // ------------------------------------------------------------
  // For 64 bit types
  /*
  // To BigEndian bytes
  static List<int> int64ToBytes(int value) {
    List<int> result = List<int>(8);
    result[0] = (value >> 56) & 0xff;
    result[1] = (value >> 48) & 0xff;
    result[2] = (value >> 40) & 0xff;
    result[3] = (value >> 32) & 0xff;
    result[4] = (value >> 24) & 0xff;
    result[5] = (value >> 16) & 0xff;
    result[6] = (value >> 8) & 0xff;
    result[7] = value & 0xff;
    return result;
  }

  // From BigEndian bytes
  static int bytesToInt64(List<int> value) {
    return value[7] |
        value[6] << 8 |
        value[5] << 16 |
        value[4] << 24 |
        value[3] << 32 |
        value[2] << 40 |
        value[1] << 48 |
        value[0] << 56;
  }
  */
  // ------------------------------------------------------------
  // For position & double types

  static List<int> positionToBytes(double lat, double lon) {
    final latInt = (lat * 1e6).toInt();
    final lonInt = (lon * 1e6).toInt();
    return int32ToBytes(latInt) + int32ToBytes(lonInt);
  }

  // From BigEndian bytes
  static double bytesToDouble(List<int> value) {
    return (value[3] | value[2] << 8 | value[1] << 16 | value[0] << 24) / 1e6;
  }

  // ------------------------------------------------------------

  // Uint8List int32BigEndianBytes(int value) => Uint8List(4)..buffer.asByteData().setInt32(0, value, Endian.big);
/*
Uint8List bytes = ...;
var blob = ByteData.sublistView(bytes);
var x = blob.getUint32(0, Endian.little);


var bdata = new ByteData(8);
bdata.setFloat32(0, 3.04);
int huh = bdata.getInt32(0); // 0x40428f5c
*/
}
