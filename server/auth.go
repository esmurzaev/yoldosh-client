// authentication

package main

import (
	"crypto/cipher"
	"crypto/aes"
	"encoding/binary"
	"net"
	"time"
	// "fmt"
)

func auth(conn *net.TCPConn) bool {
	buf := make([]byte, 17)
	length, err := conn.Read(buf)
	if  length != 17 || err != nil {
		// fmt.Println("Auth failed: packet length error")
		return false
	}

	if (buf[0] != 0x01) {
		buf[0] = 0x40
		buf[1] = 0x01
		conn.Write(buf[:2]) // API version error
		// fmt.Println("Auth failed: api version error")
		return false
	}
	
	buf = buf[1:]
	// Decrypt packet
	block, err := aes.NewCipher(MasterKey)
	if err != nil {
		// panic(err)
		return false
	}
	iv := make([]byte, aes.BlockSize)
	// buf = buf[aes.BlockSize:]
	mode := cipher.NewCBCDecrypter(block, iv)
	mode.CryptBlocks(buf, buf)
	// Code check
	code := binary.BigEndian.Uint64(buf[:8])
	if code != MasterCode {
		// fmt.Println("Auth failed: master code error")
		return false
	}
	// Timestamp check
	stamp := binary.BigEndian.Uint32(buf[8:12])
	t := time.Now()
	s := uint32(t.Unix())
	if stamp-180 > s || stamp+180 < s {
		buf[0] = 0x40
		buf[1] = 0x02
		conn.Write(buf[:2]) // Time error
		// fmt.Println(buf[8:12])
		// fmt.Println("Auth failed: time error")
		return false
	}
	// Conn configuration
	conn.SetDeadline(t.Add(120 * time.Minute))
	return true
}
/*
func authDriver(conn *net.TCPConn) bool {
	buf := make([]byte, 17)
	length, err := conn.Read(buf)
	if  length != 17 || err != nil {
		return false
	}

	if (buf[0] != 0x01) {
		buf[0] = 0x40
		buf[1] = 0x01
		conn.Write(buf[:2]) // API version error
		return false
	}
	
	buf = buf[1:]
	// Decrypt packet
	block, err := aes.NewCipher(DriversMasterKey)
	if err != nil {
		panic(err)
	}
	iv := make([]byte, aes.BlockSize)
	// buf = buf[aes.BlockSize:]
	mode := cipher.NewCBCDecrypter(block, iv)
	mode.CryptBlocks(buf, buf)
	// Code check
	code := binary.LittleEndian.Uint64(buf[:8])
	if code != DriversMasterCode {
		return false
	}
	// Timestamp check
	stamp := binary.LittleEndian.Uint32(buf[8:12])
	t := time.Now()
	s := uint32(t.Unix())
	if stamp-180 > s || stamp+180 < s {
		buf[0] = 0x40
		buf[1] = 0x02
		conn.Write(buf[:2]) // Time not correct
		fmt.Println(buf[8:12])
		return false
	}
	// Conn configuration
	conn.SetDeadline(t.Add(60 * time.Minute))
	return true
}
*/
func authAdmin(conn *net.TCPConn) bool {
	buf := make([]byte, 17)
	length, err := conn.Read(buf)
	if buf[0] != 0x0A || length != 17 || err != nil {
		return false
	}
	// Decrypt packet
	block, _ := aes.NewCipher(AdminMasterKey)
	block.Decrypt(buf[1:17], buf[1:17])
	// Code check
	code := binary.BigEndian.Uint64(buf[1:9])
	if code != AdminMasterCode {
		return false
	}
	// Timestamp check
	stamp := binary.BigEndian.Uint32(buf[9:13])
	t := time.Now()
	s := uint32(t.Unix())
	if stamp-60 > s || stamp+60 < s {
		buf[1] = 0x02
		conn.Write(buf[:2]) // Time not correct
		return false
	}
	// Conn configuration
	conn.SetDeadline(t.Add(24 * time.Hour))
	return true
}
