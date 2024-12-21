package networking

import (
	"github.com/pulumi/pulumi-hetzner/sdk/go/hetzner"
	"github.com/pulumi/pulumi/sdk/v3/go/pulumi"
)

func CreateDNSRecord(ctx *pulumi.Context, zone *hetzner.DnsZone, subdomain string, ipAddress string) (*hetzner.DnsRecord, error) {
	return hetzner.NewDnsRecord(ctx, subdomain+"-dns", &hetzner.DnsRecordArgs{
		ZoneId: pulumi.String(zone.Id),
		Name:   pulumi.String(subdomain),
		Type:   pulumi.String("A"),
		Value:  pulumi.String(ipAddress),
	})
}
