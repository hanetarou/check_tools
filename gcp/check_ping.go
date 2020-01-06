package main

import (
        "context"
        "os"
        "net"
        "fmt"
        "io"
        "time"
        "golang.org/x/net/icmp"
        "golang.org/x/net/ipv4"

        monitoring "cloud.google.com/go/monitoring/apiv3"
        "google.golang.org/genproto/googleapis/api/label"
        "google.golang.org/genproto/googleapis/api/metric"
        metricpb "google.golang.org/genproto/googleapis/api/metric"
        monitoringpb "google.golang.org/genproto/googleapis/monitoring/v3"
)

// createCustomMetric creates a custom metric specified by the metric type.
func createCustomMetric(w io.Writer, projectID, metricType string) (*metricpb.MetricDescriptor, error) {
        ctx := context.Background()
        c, err := monitoring.NewMetricClient(ctx)
        if err != nil {
                return nil, err
        }
        md := &metric.MetricDescriptor{
                Name: "Custom Metric",
                Type: metricType,
                Labels: []*label.LabelDescriptor{{
                        Key:         "environment",
                        ValueType:   label.LabelDescriptor_STRING,
                        Description: "An arbitrary measurement",
                }},
                MetricKind:  metric.MetricDescriptor_GAUGE,
                ValueType:   metric.MetricDescriptor_INT64,
                Unit:        "s",
                Description: "An arbitrary measurement",
                DisplayName: "Custom Metric",
        }
        req := &monitoringpb.CreateMetricDescriptorRequest{
                Name:             "projects/" + projectID,
                MetricDescriptor: md,
        }
        m, err := c.CreateMetricDescriptor(ctx, req)
        if err != nil {
                return nil, fmt.Errorf("could not create custom metric: %v", err)
        }

        fmt.Fprintf(w, "Created %s\n", m.GetName())
        return m, nil
}

func ping(targetIp string, timeout time.Duration) {
        // 事前準備
        ipv4Addr := net.ParseIP(targetIp)
        if ipv4Addr == nil {
                fmt.Printf("ipv4: %v", targetIp)
        }
        c, err := icmp.ListenPacket("ipv4:icmp", "0.0.0.0")
        if err != nil {
                fmt.Printf("ListenPacket: %v", err)
        }
        defer c.Close()

        // ICMP Request送信
        wm := icmp.Message {
                Type: ipv4.ICMPTypeEcho,
                Code: 0,
                Body: &icmp.Echo {
                        ID: os.Getpid() & 0xffff,
                        Seq: 0,
                        Data: []byte("HELLO-R-U-THERE"),
                },
        }
        wb, err := wm.Marshal(nil)
        if err != nil {
                fmt.Printf("Marshal: %v", err)
        }
        if _, err := c.WriteTo(wb, &net.IPAddr{IP: ipv4Addr}); err != nil {
                fmt.Printf("WriteTo: %v", err)
        }

        // ICMP Reply受信
        c.SetReadDeadline(time.Now().Add(timeout))
        rb := make([]byte, 1500)
        n, _, err := c.ReadFrom(rb)

        if err != nil {
                fmt.Print("U")
        } else {
                rm, err := icmp.ParseMessage(ipv4.ICMPTypeEcho.Protocol(), rb[:n])
                if err == nil && rm.Type == ipv4.ICMPTypeEchoReply {
                        fmt.Print("!")
                } else {
                        fmt.Print("U")
                }
        }
}

func main() {
        fmt.Printf("check_ping")
        ping("0.0.0.0", 100)
}
