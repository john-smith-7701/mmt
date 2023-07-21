Uint8Array.prototype.sum = function() {
  return this.reduce((x, y) => x + y);
};
Uint8Array.prototype.checkSum = function() {
  return Uint8Array.of((256 - this.sum()) % 256);
};
Uint8Array.prototype.equals = function(other) {
  if (this.byteLength !== other.byteLength) {
    return false;
  }
  for (let i = 0; i < this.byteLength; ++i) {
    if (this[i] !== other[i]) {
      return false;
    }
  }
  return true;
};
Number.prototype.asLittleEndian = function() {
  const buffer = new ArrayBuffer(2);
  new DataView(buffer).setUint16(0, this, true);
  return new Uint8Array(buffer);
};
class Packet {
  constructor(payload) {
    this.payload = payload;
  }
  get header() {
    return this.payload.slice(0, 5);
  }
  get footer() {
    return this.payload.slice(-1)[0];
  }
}
class RCS380Packet extends Packet {
  constructor(payload) {
    super(payload);
    this.payload = payload;
  }
  get dataLengthAsBytes() {
    return this.payload.slice(5, 7);
  }
  get dataLength() {
    const buffer = new ArrayBuffer(2);
    const octedView = new Uint8Array(buffer);
    octedView[0] = this.payload[5];
    octedView[1] = this.payload[6];
    const view = new Uint16Array(buffer);
    return view[0];
  }
  get dataLengthCheckSum() {
    return this.payload[7];
  }
  get data() {
    return this.payload.slice(8, 8 + this.dataLength);
  }
  get dataCheckSum() {
    return this.payload[8 + this.dataLength];
  }
}
class AckPacket extends Packet {
  constructor() {
    const ackPacket = Uint8Array.of(0, 0, 255, 0, 255, 0);
    super(ackPacket);
  }
}
class SendPacket extends RCS380Packet {
  constructor(data) {
    const header = Uint8Array.of(0, 0, 255, 255, 255);
    const dataLength = data.byteLength.asLittleEndian();
    const dataLengthCheckSum = dataLength.checkSum();
    const dataCheckSum = data.checkSum();
    const footer = Uint8Array.of(0);
    const payload = Uint8Array.of(...header, ...dataLength, ...dataLengthCheckSum, ...data, ...dataCheckSum, ...footer);
    super(payload);
  }
}
class ReceivedPacket extends RCS380Packet {
  constructor(payload) {
    super(payload);
  }
}
class SuccessPacket extends ReceivedPacket {
  constructor(payload) {
    super(payload);
  }
}
class FailurePacket extends ReceivedPacket {
  constructor(payload) {
    super(payload);
  }
}
class RCS380 {
  constructor(device) {
    this.device = device;
    this.ackPacket = new AckPacket();
    this.maxReceiveSize = 290;
    this.inSetDefaultProtocol = Uint8Array.of(0, 24, 1, 1, 2, 1, 3, 0, 4, 0, 5, 0, 6, 0, 7, 8, 8, 0, 9, 0, 10, 0, 11, 0, 12, 0, 14, 4, 15, 0, 16, 0, 17, 0, 18, 0, 19, 6);
    this.tgSetDefaultProtocol = Uint8Array.of(0, 1, 1, 1, 2, 7);
    this.tgCommHeader = Uint8Array.of(0, 0, 255, 255, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
    this.defaultProtocol = this.inSetDefaultProtocol;
    this.frameWaitingTime = 2.474516;
    this.deltaFrameWaitingTime = 49152 / 1356e4;
    this.timeout = this.frameWaitingTime + this.deltaFrameWaitingTime;
  }
  static async connect() {
    //const filter = {vendorId: 1356, productId: 3529};
    const filter = {vendorId: 1356};
    const options = {
      filters: [filter]
    };
    const device = await navigator.usb.requestDevice(options);
    await device.open();
    await device.selectConfiguration(1);
    await device.claimInterface(0);
    return new RCS380(device);
  }
  async write(packet) {
    console.info(">>>>> send >>>>>");
    console.log(packet.payload);
    try {
      await this.device.transferOut(2, packet.payload);
    } catch (e) {
      console.error(e);
    }
  }
  async read() {
    const result = await this.device.transferIn(1, this.maxReceiveSize);
    const rawPacket = result.data !== void 0 ? new Uint8Array(result.data.buffer) : Uint8Array.of(0, 0, 255, 0, 255, 0, 0, 0, 0);
    console.info("<<<<< receive <<<<<");
    console.log(rawPacket);
    const errorPacketHeader = Uint8Array.of(0, 0, 255, 0, 255);
    if (rawPacket.slice(0, 5).equals(errorPacketHeader)) {
      return new FailurePacket(rawPacket);
    } else {
      return new SuccessPacket(rawPacket);
    }
  }
  buildCommand(commandCode, rawCommand) {
    const header = 214;
    const command = Uint8Array.of(header, commandCode, ...rawCommand);
    return new SendPacket(command);
  }
  parseTimeout(timeoutValue) {
    const buffer = new ArrayBuffer(2);
    const hexTimeout = Math.min(timeoutValue, 65535);
    const view = new DataView(buffer);
    view.setUint16(0, hexTimeout, true);
    return new Uint8Array(buffer);
  }
  parseTimeoutIn(timeoutS) {
    if (timeoutS === 0) {
      return this.parseTimeout(0);
    } else {
      return this.parseTimeout((Math.floor(timeoutS * 1e3) + 1) * 10);
    }
  }
  parseTimeoutTg(timeoutS) {
    return this.parseTimeout(Math.floor(timeoutS * 1e3));
  }
  async sendTypeBCommandAndReceiveResult(commandCode, rawCommand) {
    const command = this.buildCommand(commandCode, rawCommand);
    await this.write(command);
    await this.read();
    return this.read();
  }
  async sendAck() {
    await this.write(this.ackPacket);
  }
  async setCommandType() {
    const commandType = Uint8Array.of(1);
    await this.sendTypeBCommandAndReceiveResult(42, commandType);
  }
  async switchRf() {
    const rf = Uint8Array.of(0);
    await this.sendTypeBCommandAndReceiveResult(6, rf);
  }
  async inSetRf(rf) {
    await this.sendTypeBCommandAndReceiveResult(0, rf);
  }
  async inSetProtocol(protocol) {
    await this.sendTypeBCommandAndReceiveResult(2, protocol);
  }
  async inCommRf(data, timeoutS) {
    const timeout = this.parseTimeoutIn(timeoutS);
    const command = new Uint8Array([...timeout, ...data]);
    return this.sendTypeBCommandAndReceiveResult(4, command);
  }
  async sendInPreparationCommands(rf, protocol) {
    await this.inSetRf(rf);
    await this.inSetProtocol(this.inSetDefaultProtocol);
    await this.inSetProtocol(protocol);
  }
  async sendPreparationCommands(rf, protocol) {
    await this.sendInPreparationCommands(rf, protocol);
  }
  async tgSetRf(rf) {
    await this.sendTypeBCommandAndReceiveResult(64, rf);
  }
  async tgSetProtocol(protocol) {
    await this.sendTypeBCommandAndReceiveResult(66, protocol);
  }
  async tgCommRf(data, timeoutS) {
    const timeout = this.parseTimeoutTg(timeoutS);
    const response = new Uint8Array([...this.tgCommHeader, ...timeout, ...data]);
    return this.sendTypeBCommandAndReceiveResult(72, response);
  }
  async sendTgPreparationCommands(rf, protocol) {
    await this.tgSetRf(rf);
    await this.tgSetProtocol(this.tgSetDefaultProtocol);
    await this.tgSetProtocol(protocol);
  }
  async initDevice() {
    console.info("Initialize RC-S380");
    await this.sendAck();
    await this.setCommandType();
    await this.switchRf();
    await this.switchRf();
  }
  async disconnect() {
    console.info("Disconnect RC-S380");
    await this.switchRf();
    await this.sendAck();
  }
}
export {RCS380, ReceivedPacket};
export default null;

