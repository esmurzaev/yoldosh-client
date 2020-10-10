// main

package main

import (
	"log"
	"os"
	"runtime"
	"gopkg.in/yaml.v3"
	// "sync"
)

const (
	confPath        = "conf.yaml"
	ClientsMaxNum   = 1000000
	AdminMasterCode = uint64(0x105F218E5BFEC13E)
	MasterCode      = uint64(0x2D082E4CD3339301)
)

//-------------------------------------------------------------------------------------------------------

var (
	AdminMasterKey = []byte{0xA8, 0xFA, 0x08, 0x03, 0xDE, 0x6C, 0xF6, 0x25, 0xB1, 0xD5, 0xB9, 0x91, 0x1D, 0xA5, 0x56, 0xD6}
	MasterKey      = []byte{0xF1, 0xE5, 0xB8, 0x27, 0xDF, 0x61, 0x39, 0x27, 0x11, 0x4B, 0x31, 0x7A, 0x2A, 0x91, 0xCE, 0x79}
	// wg sync.WaitGroup
)

//-------------------------------------------------------------------------------------------------------

type config struct {
	Host string       `yaml:"host"`
	AdminPort string  `yaml:"adminPort"`
	ClientPort string `yaml:"clientPort"`
	DriverPort string `yaml:"driverPort"`
}

//-------------------------------------------------------------------------------------------------------

func loadConfig(confPath string) (*config, error) {
	conf := &config{}
	file, err := os.Open(confPath)
	if err != nil {
		return nil, err
	}
	defer file.Close()
	d := yaml.NewDecoder(file)
	if err := d.Decode(&conf); err != nil {
		return nil, err
	}
	return conf, nil
}

//-------------------------------------------------------------------------------------------------------

func main() {
	runtime.GOMAXPROCS(runtime.NumCPU())
	conf, err := loadConfig(confPath)
	if err != nil {
		log.Fatal(err)
	}
	log.Println("---------- Server started ----------")

	go func() {
		// wg.Add(1)
		log.Fatal(serveClient(conf.Host + conf.ClientPort))
	}()

	// go func() {
		// wg.Add(1)
		log.Fatal(serveDriver(conf.Host + conf.DriverPort))
	// }()
	
	// go func() {
		// wg.Add(1)
		// log.Fatal(serveAdmin(conf.Host + conf.AdminPort))
	// }()

	// wg.Wait()
}
