//

package main

import (
	"encoding/binary"
	"net"
	"sync/atomic"
	"time"
)

var (
	clientsNum                aint
	driversNum                aint
	statsClientsSuccessConns  aint // Counter for total client successful authentications
	statsClientsFailedConns   aint // Counter for total client failed authentications
	statsClientsFailedPackets aint //
	statsClientsCancelMatches aint // Counter for total client failed matches
	statsDriversSuccessConns  aint // Counter for total driver successful authentications
	statsDriversFailedConns   aint // Counter for total driver failed authentications
	statsDriversFailedPackets aint //
	statsDriversCancelMatches aint //
	statsClientsFailedMatches aint // Counter for total driver failed matches
	statsClientsCancels       aint //
	statsFoundedMatches       aint // Counter for total founded matches
	statsSuccessMatches       aint // Counter for total successful matches
)

type aint struct{ v uintptr }

func (a *aint) add() {
	atomic.AddUintptr(&a.v, uintptr(1))
}
func (a *aint) delete() {
	atomic.AddUintptr(&a.v, ^uintptr(0))
}
func (a *aint) get() uint64 {
	return uint64(atomic.LoadUintptr(&a.v))
}

/*
func (a *aint) set(i int) int {
	return int(atomic.SwapUintptr(&a.v, uintptr(i)))
}

type abool struct{ v uint32 }

func (a *abool) on() bool {
	return atomic.LoadUint32(&a.v) != 0
}
func (a *abool) set(t bool) bool {
	if t {
		return atomic.SwapUint32(&a.v, 1) != 0
	}
	return atomic.SwapUint32(&a.v, 0) != 0
}
*/

func serveAdmin(addr string) error {
	lAddr, err := net.ResolveTCPAddr("tcp", addr)
	if err != nil {
		return err
	}
	ln, err := net.ListenTCP("tcp", lAddr)
	if err != nil {
		return err
	}
	defer func () {
		ln.Close()
		// wg.Done()
	}()
	var tempDelay time.Duration

	for {
		conn, err := ln.AcceptTCP()
		if err != nil {
			if ne, ok := err.(net.Error); ok && ne.Temporary() {
				if tempDelay == 0 {
					tempDelay = 5 * time.Millisecond
				} else {
					tempDelay *= 2
				}
				if max := 1 * time.Second; tempDelay > max {
					tempDelay = max
				}
				time.Sleep(tempDelay)
				continue
			}
			return err
		}
		tempDelay = 0
		go handleAdmin(conn)
	}
}

func handleAdmin(conn *net.TCPConn) {
	if !authAdmin(conn) {
		conn.Close()
		return
	}

	defer func() {
		conn.Close()
	}()

	var (
		exitFlag bool
		buf = make([]byte, 123)
	)

	for {
		length, err := conn.Read(buf[:3])
		if err != nil || buf[0] != 0x47 || length != 3 {
			return
		}

		switch buf[1] {
		default:
			return

		case 0x01: // Number of connected users and stats get
			if !exitFlag {
			exitFlag = true
				go func(conn *net.TCPConn) {
					var buf = make([]byte, 255)
					for {
						n := binary.PutUvarint(buf[3:], clientsNum.get())
						n += 3
						n += binary.PutUvarint(buf[n:], driversNum.get())
						n += binary.PutUvarint(buf[n:], statsClientsSuccessConns.get())
						n += binary.PutUvarint(buf[n:], statsClientsFailedConns.get())
						n += binary.PutUvarint(buf[n:], statsClientsFailedPackets.get())
						n += binary.PutUvarint(buf[n:], statsClientsCancelMatches.get())
						n += binary.PutUvarint(buf[n:], statsDriversSuccessConns.get())
						n += binary.PutUvarint(buf[n:], statsDriversFailedConns.get())
						n += binary.PutUvarint(buf[n:], statsDriversFailedPackets.get())
						n += binary.PutUvarint(buf[n:], statsClientsFailedMatches.get())
						n += binary.PutUvarint(buf[n:], statsClientsCancels.get())
						n += binary.PutUvarint(buf[n:], statsFoundedMatches.get())
						n += binary.PutUvarint(buf[n:], statsSuccessMatches.get())
						buf[2] = byte(n)
						if _, err = conn.Write(buf[:n]); err != nil {
							exitFlag = false
							return
						}
						time.Sleep(1 * time.Minute)
					}
				}(conn)
			}
		}
	}
}
