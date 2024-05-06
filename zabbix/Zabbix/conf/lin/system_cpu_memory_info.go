package main

import (
        "fmt"
        "math"
        "github.com/shirou/gopsutil/load"
        "github.com/shirou/gopsutil/mem"
        "github.com/shirou/gopsutil/host"
        "strings"
)

func get_cpu_load() (*load.AvgStat, error) {
        return load.Avg()
}

func get_mem_info() (*mem.VirtualMemoryStat, error) {
        return mem.VirtualMemory()
}

func get_host_info() (*host.InfoStat, error) {
        return host.Info()
}

func main()  {
        cpuLoad, err := get_cpu_load()
        if err != nil {
                fmt.Println(err)
                return
        }

        memoryInfo, err := get_mem_info()
        total := float64(memoryInfo.Total) / (1024 * 1024 * 1024)
        if err != nil {
                fmt.Println(err)
                return
        }

        hostInfo, err := get_host_info()
        var os_V string
        if hostInfo.OS == "windows" {
                platformVersion := strings.Split(hostInfo.PlatformVersion, ".")
                os_V = strings.Join(platformVersion[:3], ".")
        } else {
                platformVersion := strings.Split(hostInfo.PlatformVersion, ".")
                os_V = strings.Join(platformVersion[:2], ".")
        }
        if err != nil {
                fmt.Println(err)
                return
        }

        fmt.Printf("{\"cpu_load1\": %.2f, \"cpu_load5\": %.2f, \"cpu_load15\": %.2f}\n", cpuLoad.Load1, cpuLoad.Load5, cpuLoad.Load15)
        fmt.Printf("{\"Mem_Total\": %v, \"Mem_UsedPercent\": %.2f}\n", int(math.Round(total)), memoryInfo.UsedPercent)
        fmt.Printf("{\"Hostname\": \"%v\", \"Uptime\": %v, \"OS_version\": \"%v\"}\n", hostInfo.Hostname, hostInfo.Uptime, os_V)
}
