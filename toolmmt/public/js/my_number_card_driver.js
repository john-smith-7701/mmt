import * as  __commonjs_module0 from "./rc_s380_driver.js";
const {RCS380} = __commonjs_module0;
;
import jsSha from "./jssha.js";
class Type4BPacket {
  constructor(rawPacketData) {
    this.rawPacketData = rawPacketData;
  }
  get header() {
    return this.rawPacketData.slice(0, 8);
  }
  get data() {
    return this.rawPacketData.slice(8, -2);
  }
  get status() {
    return this.rawPacketData.slice(-2);
  }
}
class Type4BTag {
  constructor(rcs380) {
    this.rcs380 = rcs380;
    this.nfcID = new Uint8Array(0);
    this.pni = 0;
    this.protocol = Uint8Array.of(11, 1, 9, 1, 12, 1, 10, 1, 0, 20);
    this.rf = Uint8Array.of(3, 7, 15, 7);
  }
  static async connect() {
    const device = await RCS380.connect();
    return new Type4BTag(device);
  }
  async sendSenseType4BCommand() {
    const payload = Uint8Array.of(5, 0, 16);
    return this.rcs380.inCommRf(payload, 0.03);
  }
  async findType4BTag() {
    console.info("===== find Type 4B tag =====");
    while (this.nfcID.byteLength === 0) {
      await this.rcs380.sendPreparationCommands(this.rf, this.protocol);
      const result = await this.sendSenseType4BCommand();
      this.nfcID = result.data.slice(8, 12);
    }
  }
  async sendAttribute() {
    console.info("===== send attrib =====");
    await this.rcs380.sendPreparationCommands(this.rf, this.protocol);
    const attribute = new Uint8Array(1 + this.nfcID.byteLength + 4);
    attribute.set(Uint8Array.of(29), 0);
    attribute.set(this.nfcID, 1);
    attribute.set(Uint8Array.of(0, 8, 1, 0), 1 + this.nfcID.byteLength);
    await this.rcs380.inCommRf(attribute, 0.03);
  }
  async connectToCard() {
    await this.rcs380.initDevice();
    await this.findType4BTag();
    await this.sendAttribute();
  }
  async exchange(type4BCommand, timeoutMs) {
    const pfb = 2 | this.pni;
    const data = Uint8Array.of(pfb, ...type4BCommand);
    const response = await this.rcs380.inCommRf(data, timeoutMs);
    if ((response.data[7] & 238) === 2) {
      this.pni = (this.pni + 1) % 2;
    }
    if (Boolean(response.data[7] & 16)) {
      console.info("===== send a2 =====");
      await this.rcs380.sendPreparationCommands(this.rf, this.protocol);
      const a2Response = await this.rcs380.inCommRf(Uint8Array.of(162 | this.pni), timeoutMs);
      const a2Packet = new Type4BPacket(a2Response.data);
      const a2Result = Uint8Array.of(...response.data, ...a2Packet.data, ...a2Packet.status);
      this.pni = (this.pni + 1) % 2;
      return new Type4BPacket(a2Result);
    } else {
      return new Type4BPacket(response.data);
    }
  }
  async sendCommand(type4BCommand) {
    await this.rcs380.sendPreparationCommands(this.rf, this.protocol);
    return this.exchange(type4BCommand, this.rcs380.timeout);
  }
  resetNfcID() {
    this.nfcID = new Uint8Array(0);
  }
}
class ASN1Error {
  constructor(message) {
    this.message = message;
    this.name = "ASN1Error";
  }
  toString() {
    return this.name + ": " + this.message;
  }
}
class FewBinarySizeError extends ASN1Error {
}
class UnexpectedTagSizeError extends ASN1Error {
}
class TruncatedTagOrLengthError extends ASN1Error {
}
class ASN1Partial {
  constructor(binary) {
    this.binary = binary;
    this.offset = 0;
    this.length = 0;
    this.parseTag();
    this.parseLength();
  }
  parseTag() {
    let tagSize = 1;
    if (this.binary.byteLength < 2) {
      throw new FewBinarySizeError("few binary size");
    }
    if ((this.binary[0] & 31) === 31) {
      tagSize += 1;
      if ((this.binary[1] & 128) !== 0) {
        throw new UnexpectedTagSizeError("unexpected tag size");
      }
    }
    this.offset = tagSize;
  }
  parseLength() {
    if (this.offset >= this.binary.byteLength) {
      throw new FewBinarySizeError("few binary size");
    }
    let b = this.binary[this.offset];
    this.offset += 1;
    if ((b & 128) === 0) {
      this.length = b;
    } else {
      const lol = b & 127;
      for (let n of [...Array(lol).keys()]) {
        if (this.offset >= this.binary.byteLength) {
          throw new TruncatedTagOrLengthError("truncated tag or length");
        }
        b = this.binary[this.offset];
        this.offset += 1;
        this.length <<= 8;
        this.length |= b;
      }
    }
  }
  get size() {
    return this.offset + this.length;
  }
}
class MessagePacket {
  constructor(message, hashType) {
    this.header = {
      "SHA-1": Uint8Array.of(48, 33, 48, 9, 6, 5, 43, 14, 3, 2, 26, 5, 0, 4, 20),
      "SHA-256": Uint8Array.of(48, 49, 48, 13, 6, 9, 96, 134, 72, 1, 101, 3, 4, 2, 1, 5, 0, 4, 32),
      "SHA-384": Uint8Array.of(48, 65, 48, 13, 6, 9, 96, 134, 72, 1, 101, 3, 4, 2, 2, 5, 0, 4, 48),
      "SHA-512": Uint8Array.of(48, 81, 48, 13, 6, 9, 96, 134, 72, 1, 101, 3, 4, 2, 3, 5, 0, 4, 64)
    };
    const hasher = new jsSha(hashType, "TEXT");
    hasher.update(message);
    const signCommand = Uint8Array.of(128, 42, 0, 128);
    const hashedMessage = new Uint8Array(hasher.getHash("ARRAYBUFFER"));
    const header = this.header[hashType];
    const dataLength = Uint8Array.of(hashedMessage.byteLength + header.byteLength);
    const suffix = 0;
    this.payload = Uint8Array.of(...signCommand, ...dataLength, ...header, ...hashedMessage, suffix);
  }
  static asSHA1(message) {
    return new MessagePacket(message, "SHA-1");
  }
  static asSHA256(message) {
    return new MessagePacket(message, "SHA-256");
  }
  static asSHA384(message) {
    return new MessagePacket(message, "SHA-384");
  }
  static asSHA512(message) {
    return new MessagePacket(message, "SHA-512");
  }
  static makeMessagePacket(hashType, message) {
    return MessagePacket.makePacketFunctions[hashType](message);
  }
}
MessagePacket.makePacketFunctions = {
  "SHA-1": MessagePacket.asSHA1,
  "SHA-256": MessagePacket.asSHA256,
  "SHA-384": MessagePacket.asSHA384,
  "SHA-512": MessagePacket.asSHA512
};
class PersonalData {
  constructor(rawData) {
    const decoder = new TextDecoder("UTF-8");
    let berLength = new ASN1Partial(rawData);
    let tmpRawData = rawData.slice(berLength.offset);
    const headerLength = tmpRawData[2];
    tmpRawData = tmpRawData.slice(3 + headerLength);
    berLength = new ASN1Partial(tmpRawData);
    const nameLength = berLength.length;
    this.name = decoder.decode(tmpRawData.slice(berLength.offset, berLength.size));
    tmpRawData = tmpRawData.slice(berLength.size);
    berLength = new ASN1Partial(tmpRawData);
    const addressLength = berLength.length;;
    this.address = decoder.decode(tmpRawData.slice(berLength.offset, berLength.size));
    tmpRawData = tmpRawData.slice(berLength.size);
    const birthdayLength = tmpRawData[2];
    const birthday = decoder.decode(tmpRawData.slice(3, 3 + birthdayLength));
    const year = Number(birthday.slice(0, 4));
    const month = Number(birthday.slice(4, 6)) - 1;
    const date = Number(birthday.slice(6, 8));
    console.error(year, month, date);
    this.birthday = new Date(year, month, date);
    tmpRawData = tmpRawData.slice(3 + birthdayLength);
    const sex = decoder.decode(Uint8Array.of(tmpRawData[3]));
    if (sex === "1") {
      this.sex = "\u7537\u6027";
    } else if (sex === "2") {
      this.sex = "\u5973\u6027";
    } else if (sex === "9") {
      this.sex = "\u9069\u7528\u4E0D\u80FD";
    } else {
      this.sex = "\u4E0D\u660E";
    }
  }
}
class MyNumberCard {
  constructor(device) {
    this.device = device;
  }
  static async connect() {
    const device = await Type4BTag.connect();
    return new MyNumberCard(device);
  }
  async disconnect() {
    console.info("===== disconnect =====");
    await this.device.rcs380.disconnect();
    this.device.resetNfcID();
  }
  createAdpuCase3Command(header, rawCommand) {
    const length = Uint8Array.of(rawCommand.byteLength);
    const command = Uint8Array.of(...header, ...length, ...rawCommand);
    return command;
  }
  async selectDF(dedicatedFile) {
    console.info("===== select dedicatedFile =====");
    const header = Uint8Array.of(0, 164, 4, 12, 10);
    const command = Uint8Array.of(...header, ...dedicatedFile);
    return this.device.sendCommand(command);
  }
  async selectEF(elementaryFile) {
    console.info("===== select ef =====");
    const header = Uint8Array.of(0, 164, 2, 12);
    const command = this.createAdpuCase3Command(header, elementaryFile);
    return this.device.sendCommand(command);
  }
  async verifyPin(rawPin) {
    console.info("===== verify pin =====");
    const pin = Uint8Array.from(rawPin.split("").map((c) => c.charCodeAt(0)));
    const header = Uint8Array.of(0, 32, 0, 128);
    const command = this.createAdpuCase3Command(header, pin);
    return this.device.sendCommand(command);
  }
  async selectCardInfoAP() {
    const cardInfoAP = Uint8Array.of(211, 146, 16, 0, 49, 0, 1, 1, 4, 8);
    return this.selectDF(cardInfoAP);
  }
  async selectCertAP() {
    const certAP = Uint8Array.of(211, 146, 240, 0, 38, 1, 0, 0, 0, 1);
    return this.selectDF(certAP);
  }
  async selectMyNumberEF() {
    return this.selectEF(Uint8Array.of(0, 1));
  }
  async selectPersonalDataEF() {
    return this.selectEF(Uint8Array.of(0, 2));
  }
  async selectCardInfoPinEF() {
    return this.selectEF(Uint8Array.of(0, 17));
  }
  async selectRSAPrivateKeyPinEF() {
    return this.selectEF(Uint8Array.of(0, 24));
  }
  async selectRSAPublicKeyEF() {
    return this.selectEF(Uint8Array.of(0, 10));
  }
  async selectRSAPrivateKeyIEF() {
    return this.selectEF(Uint8Array.of(0, 23));
  }
  async signMessage(hashType, message) {
    console.info("===== sign =====");
    const command = MessagePacket.makeMessagePacket(hashType, message).payload;
    return this.device.sendCommand(command);
  }
  async checkPublicKeyLength() {
    console.info("===== check Public Key length =====");
    const readPublicKeyCommand = Uint8Array.of(0, 176, 0, 0, 7);
    const response = await this.device.sendCommand(readPublicKeyCommand);
    const parser = new ASN1Partial(response.data);
    return parser.size;
  }
  async readBinary(size) {
    const result = new Uint8Array(size);
    let position = 0;
    let loopCount = 0; 
    while (position < size && loopCount < 10) {
      let length = 0;
      if (size - position > 255) {
        length = 0;
      } else {
        length = size - position;
      }
      const readBinaryCommand = Uint8Array.of(0, 176, position >> 8 & 255, position & 255, length);
      const response = await this.device.sendCommand(readBinaryCommand);
      result.set(response.data, position);
      position += response.data.byteLength;
      if(response.data.byteLength == 0){
          loopCount++;
      }
    }
    return result;
  }
  async getMyNumber(pin) {
    await this.device.connectToCard();
    await this.selectCardInfoAP();
    await this.selectCardInfoPinEF();
    await this.verifyPin(pin);
    await this.selectMyNumberEF();
    const myNumber = await this.readBinary(16);
    await this.disconnect();
    return String.fromCharCode(...myNumber.slice(3, 15));
  }
  async getPersonalData(pin) {
    await this.device.connectToCard();
    await this.selectCardInfoAP();
    await this.selectCardInfoPinEF();
    await this.verifyPin(pin);
    await this.selectPersonalDataEF();
    const lengthPacket = await this.readBinary(7);
    const parser = new ASN1Partial(lengthPacket);
    const personalData = await this.readBinary(parser.size);
    await this.disconnect();
    return new PersonalData(personalData);
  }
  async signMessageWithPrivateKey(hashType, pin, message) {
    await this.device.connectToCard();
    await this.selectCertAP();
    await this.selectRSAPrivateKeyPinEF();
    await this.verifyPin(pin);
    await this.selectRSAPrivateKeyIEF();
    const signedMessage = await this.signMessage(hashType, message);
    await this.disconnect();
    return signedMessage.data;
  }
  async getPublicKey() {
    await this.device.connectToCard();
    await this.selectCertAP();
    await this.selectRSAPublicKeyEF();
    const publicKeyLength = await this.checkPublicKeyLength();
    const publicKey = await this.readBinary(publicKeyLength);
    await this.disconnect();
    return publicKey;
  }
}
export {MyNumberCard, Type4BTag};
export default null;


